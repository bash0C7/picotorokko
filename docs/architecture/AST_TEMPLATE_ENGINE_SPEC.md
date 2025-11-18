# AST-Based Template Engine Specification

**Status**: ✅ COMPLETE (merged from origin/main)
**Implementation**: Multiple sessions
**Key Commits**: c411bd4, 55664bf, 9806bd7, f95f036

## Overview

The AST-Based Template Engine replaces ERB-based template generation with syntax-aware AST manipulation, enabling robust template transformation for Ruby, YAML, and C code generation in the mrbgem build system.

## Architecture

### Core Components

```
┌──────────────────────────────────────┐
│  Pra::Template::Engine (abstract)    │
│  ├─ execute(content, replacements)   │
│  └─ Returns: modified content        │
└──────────────────────────────────────┘
           │
    ┌──────┼──────┬──────────┐
    │      │      │          │
    ↓      ↓      ↓          ↓
┌────┐ ┌────┐ ┌────┐  ┌──────────┐
│Ruby│ │YAML│ │ C  │  │StringEngine
│    │ │    │ │    │  │(fallback)
└────┘ └────┘ └────┘  └──────────┘
```

### Supported Template Types

| Type | Engine | Parser | Approach |
|------|--------|--------|----------|
| .rb | RubyTemplateEngine | Prism (AST) | Visitor pattern, code generation |
| .yml/.yaml | YamlTemplateEngine | Psych (AST) | Recursive traversal + replacement |
| .c | CTemplateEngine | - | String substitution with Regex |
| .erb (legacy) | StringEngine | - | Fallback, simple replacement |

## Implementation Details

### 1. RubyTemplateEngine (Prism-based)

**Purpose**: Transform Ruby code templates with variable substitution

**Method**: Abstract Syntax Tree manipulation

```ruby
# Input template
def initialize(name)
  @name = "{{NAME}}"
  @version = "{{VERSION}}"
end

# Replacements
{ "NAME" => "MyApp", "VERSION" => "1.0.0" }

# Output
def initialize(name)
  @name = "MyApp"
  @version = "1.0.0"
end
```

**Key Features**:
- Preserves code structure and formatting
- Detects placeholder strings via Prism AST
- Generates new StringNode with replaced value
- Handles nested data structures

**Implementation**:
- `lib/pra/template/ruby_engine.rb`
- Uses Prism::Visitor pattern

### 2. YamlTemplateEngine (Psych-based)

**Purpose**: Transform YAML templates preserving structure

**Method**: Recursive YAML object traversal

```ruby
# Input YAML
description: "App {{NAME}} v{{VERSION}}"
settings:
  enabled: "{{ENABLED}}"
  version: "{{VERSION}}"

# Output
description: "App MyApp v1.0.0"
settings:
  enabled: "true"
  version: "1.0.0"
```

**Key Features**:
- Traverses Hash/Array structures recursively
- Replaces string values containing placeholders
- Preserves YAML structure (keys, nesting, types)
- Handles arrays of hashes (common in config)

**Implementation**:
- `lib/pra/template/yaml_engine.rb`
- Recursive visitor pattern

### 3. CTemplateEngine (String-based)

**Purpose**: Transform C code templates simply

**Method**: Regex-based string replacement

```c
// Input
const char* APP_NAME = "{{NAME}}";
const char* VERSION = "{{VERSION}}";

// Output
const char* APP_NAME = "MyApp";
const char* VERSION = "1.0.0";
```

**Key Features**:
- Simple placeholder detection: `{{KEY}}`
- No parsing or validation
- Fast for simple substitution
- Works with any text format

**Implementation**:
- `lib/pra/template/c_engine.rb`
- Uses Regex: `/\{\{(\w+)\}\}/`

### 4. StringEngine (Fallback)

**Purpose**: Generic fallback for unknown file types

**Method**: Regex-based replacement (like CTemplateEngine)

**Rationale**:
- Unknown file types fall back to string replacement
- Same reliability as CTemplateEngine
- Better than failing

## Placeholder Syntax

All engines recognize the same placeholder syntax:

```
{{PLACEHOLDER_NAME}}
```

**Format Rules**:
- Double curly braces: `{{ }}`
- Alphanumeric + underscore: `[A-Z_0-9]+` (case-sensitive)
- No whitespace inside braces
- One placeholder per value (YAML) or per string (Ruby)

**Example Replacements**:

```ruby
{
  "APP_NAME" => "MyGem",
  "VERSION" => "1.2.3",
  "AUTHOR" => "Your Name",
  "ENABLED" => "true"
}
```

## Unified Interface

### Pra::Template::Engine

```ruby
module Pra
  module Template
    module Engine
      def self.execute(content, replacements, file_extension)
        engine = case file_extension
                 when '.rb'
                   RubyTemplateEngine.new
                 when '.yml', '.yaml'
                   YamlTemplateEngine.new
                 when '.c'
                   CTemplateEngine.new
                 else
                   StringEngine.new
                 end

        engine.execute(content, replacements)
      end
    end
  end
end
```

### Usage in mrbgems

```ruby
# lib/pra/commands/mrbgems.rb

def generate_template(template_path, output_path, replacements)
  content = File.read(template_path)
  ext = File.extname(template_path)

  # Unified interface - engine selected automatically
  transformed = Pra::Template::Engine.execute(content, replacements, ext)

  File.write(output_path, transformed)
end
```

## Test Coverage

### Test Scenarios Covered

**RubyTemplateEngine**:
- String literals (single/double quoted)
- Nested data structures (arrays, hashes)
- Multiple placeholders in one string
- Complex expressions with strings
- Methods with string arguments

**YamlTemplateEngine**:
- Top-level hash replacements
- Nested hash/array structures
- Multiple placeholders in values
- Different YAML data types
- Preserves key ordering

**CTemplateEngine**:
- Simple string replacement
- Multiple placeholders per line
- C-specific patterns (pointers, macros)
- Edge cases (no placeholders, empty strings)

## Performance Characteristics

### Parse Time (by engine)

| Engine | Time | Notes |
|--------|------|-------|
| RubyTemplateEngine | ~10ms | Prism AST parsing, Visitor traversal |
| YamlTemplateEngine | ~5ms | Psych YAML parsing, recursive traversal |
| CTemplateEngine | ~1ms | Simple regex replacement |
| StringEngine | ~1ms | Basic regex replacement |

**Note**: Typical template sizes: 1-10KB. Performance acceptable for build-time use.

### Complexity

- RubyTemplateEngine: O(n) where n = AST node count
- YamlTemplateEngine: O(n) where n = YAML value count
- CTemplateEngine: O(n*m) where n = placeholders, m = average replacement size

## Integration with mrbgems

### Workflow

```
User runs: ptrk mrbgems generate --env development
    ↓
mrbgems_command loads .erb templates from templates/mrbgem_app/
    ↓
For each template file:
    1. Read content
    2. Detect file extension
    3. Select appropriate Engine
    4. Call Engine.execute(content, replacements)
    5. Write transformed output to build directory
    ↓
Transformed files ready for build
```

### Example: mrbgem.rake Template

**Input** (`lib/pra/templates/mrbgem_app/mrbgem.rake`):

```erb
MRuby::Gem::Specification.new('{{APP_NAME}}') do |spec|
  spec.version = '{{VERSION}}'
  spec.authors = ['{{AUTHOR}}']
  spec.summary = '{{SUMMARY}}'

  spec.add_dependency 'mruby-io'
  spec.add_dependency 'mruby-time'
end
```

**Execution**:

```ruby
replacements = {
  "APP_NAME" => "my_app",
  "VERSION" => "1.0.0",
  "AUTHOR" => "Jane Doe",
  "SUMMARY" => "A cool Ruby app"
}

output = Pra::Template::Engine.execute(content, replacements, '.rake')
# Falls back to StringEngine (unknown extension)
```

**Output**:

```ruby
MRuby::Gem::Specification.new('my_app') do |spec|
  spec.version = '1.0.0'
  spec.authors = ['Jane Doe']
  spec.summary = 'A cool Ruby app'

  spec.add_dependency 'mruby-io'
  spec.add_dependency 'mruby-time'
end
```

## Extension Points

### Adding New Engine Type

To support a new file type (e.g., JSON):

```ruby
# lib/pra/template/json_engine.rb
module Pra
  module Template
    class JsonTemplateEngine
      def execute(content, replacements)
        data = JSON.parse(content)
        transformed = replace_in_object(data, replacements)
        JSON.pretty_generate(transformed)
      end

      private

      def replace_in_object(obj, replacements)
        case obj
        when Hash
          obj.map { |k, v| [k, replace_in_object(v, replacements)] }.to_h
        when Array
          obj.map { |item| replace_in_object(item, replacements) }
        when String
          replacements.each { |key, val| obj.gsub!("{{#{key}}}", val) }
          obj
        else
          obj
        end
      end
    end
  end
end
```

Register in Engine dispatcher:

```ruby
# lib/pra/template/engine.rb
when '.json'
  JsonTemplateEngine.new
```

## Files Structure

```
lib/pra/
├── template/
│   ├── engine.rb              # Dispatcher interface
│   ├── ruby_engine.rb         # Prism-based
│   ├── yaml_engine.rb         # Psych-based
│   ├── c_engine.rb            # Regex-based
│   └── string_engine.rb       # Fallback
│
└── templates/
    └── mrbgem_app/
        ├── README.md
        ├── mrbgem.rake
        ├── mrblib/app.rb
        └── src/app.c

test/template/
├── engine_test.rb
├── ruby_engine_test.rb
├── yaml_engine_test.rb
└── c_engine_test.rb
```

## Compatibility

- **Ruby**: 3.3+ (Prism, Psych available)
- **mruby**: 3.2+
- **Gems**: prism, psych (bundled with Ruby)

## Known Limitations

1. **RubyTemplateEngine**:
   - Only handles string literals (not symbols, comments)
   - Does not validate Ruby syntax
   - Complex expressions may not be transformed correctly

2. **YamlTemplateEngine**:
   - Assumes valid YAML input
   - Does not preserve comments
   - Does not handle anchors/aliases

3. **CTemplateEngine**:
   - Simple regex matching, no C parsing
   - May have false positives in comments/strings

**Mitigation**: Use StringEngine as fallback for edge cases.

## Testing

Run template engine tests:

```bash
# All template tests
bundle exec ruby test/template/engine_test.rb
bundle exec ruby test/template/ruby_engine_test.rb
bundle exec ruby test/template/yaml_engine_test.rb
bundle exec ruby test/template/c_engine_test.rb

# In test suite
rake test  # Includes all template tests
```

## References

- Prism Ruby Parser: https://github.com/ruby/prism
- Psych YAML parser: https://github.com/ruby/psych
- mrbgem documentation: https://github.com/mruby/mruby
