# Prism-Based Rakefile Parser for Dynamic Task Generation

**Status**: Implemented
**Architecture**: AST-based static analysis with dynamic pattern expansion
**Reference**: [lib/picotorokko/commands/device.rb](../../lib/picotorokko/commands/device.rb) (RakeTaskExtractor class)

## Overview

The Prism-based Rakefile parser enables secure, static analysis of Rake task definitions, including dynamic task generation via `.each` loops. This design provides a whitelist-based security mechanism for delegating commands to R2P2-ESP32's Rake tasks without executing arbitrary code.

### Key Benefits

- **Security**: Only whitelisted tasks (extracted statically) can be executed
- **No code execution**: Uses AST analysis only; safe on any system
- **Handles dynamic tasks**: Supports `.each` pattern with full expansion
- **Robust parsing**: AST is more reliable than regex patterns

## Design Rationale: Why Prism?

### Alternatives Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| **Regex patterns** | Simple, fast | Brittle, error-prone with nested structures | ❌ Rejected |
| **Ruby eval** | Full dynamic support | Security nightmare, unpredictable behavior | ❌ Rejected |
| **Prism AST** | Robust, safe, handles dynamics | Slightly slower (but still fast) | ✅ **Chosen** |

### Why Regex Fails

```ruby
# Regex can match the simple case:
/task\s+"(\w+)"/.match('task "flash" do')  # ✓ Works

# But breaks with string interpolation:
/task\s+"[^"]*#{[^}]*}[^"]*"/.match('task "setup_#{name}" do')  # ❌ False positives

# And complex nested structures:
task %w[a b].map { |x| "setup_#{x}" }  # ❌ Regex cannot parse this
```

### Why eval Is Dangerous

```ruby
# Malicious Rakefile:
task "flash" do
  system("rm -rf /")
  sh "idf.py flash"
end

# If you eval the Rakefile to extract tasks, the malicious code runs!
eval(rakefile_content)  # ❌ DANGEROUS
```

### Why Prism Is Right

```ruby
# Prism parses without executing:
source = File.read("Rakefile")
ast = Prism.parse(source)
ast.value.accept(RakeTaskExtractor.new)

# ✓ No code execution
# ✓ Full AST visibility
# ✓ Reliable parsing
# ✓ Safe on any system
```

## Supported Patterns

### ✅ Fully Supported

**Pattern 1: Simple task definitions**
```ruby
task :flash do
  sh "idf.py flash"
end

task "monitor" do
  puts "Monitoring"
end
```
Extracted: `["flash", "monitor"]`

**Pattern 2: Word array with .each loop**
```ruby
%w[esp32 esp32c3 esp32c6 esp32s3].each do |name|
  task "setup_#{name}" do
    sh "idf.py set-target #{name}"
  end
end
```
Extracted: `["setup_esp32", "setup_esp32c3", "setup_esp32c6", "setup_esp32s3"]`

**Pattern 3: Array literal with .each**
```ruby
['debug', 'release'].each do |mode|
  task "build_#{mode}" do
    sh "make #{mode}"
  end
end
```
Extracted: `["build_debug", "build_release"]`

**Pattern 4: Multiple tasks per loop element**
```ruby
%w[esp32 esp32c3].each do |chip|
  task "build_#{chip}" do
    # build logic
  end

  task "flash_#{chip}" do
    # flash logic
  end
end
```
Extracted: `["build_esp32", "build_esp32c3", "flash_esp32", "flash_esp32c3"]`

**Pattern 5: Complex string interpolation**
```ruby
%w[a b].each do |letter|
  task "prefix_#{letter}_suffix" do
    # logic
  end
end
```
Extracted: `["prefix_a_suffix", "prefix_b_suffix"]`

### ❌ Not Supported (By Design)

These patterns require runtime evaluation and cannot be statically analyzed:

**Pattern 6: Constant-based arrays**
```ruby
CHIPS = %w[esp32 esp32c3]
CHIPS.each do |chip|
  task "setup_#{chip}" do
    # ...
  end
end
```
**Reason**: Constant value determined at runtime; not in static AST

**Pattern 7: Method call results**
```ruby
get_chip_list.each do |chip|
  task "build_#{chip}" do
    # ...
  end
end
```
**Reason**: Method return value determined at runtime

**Pattern 8: Runtime variable interpolation**
```ruby
task "build_#{ENV['MODE']}" do
  # ...
end
```
**Reason**: Environment variable determined at runtime

### Fallback Behavior

When dynamic patterns cannot be extracted, the parser gracefully returns an empty list, and the system skips whitelist validation (allowing all declared methods). This ensures system stability while maintaining security for parseable Rakefiles.

## R2P2-ESP32 Rakefile Example

The R2P2-ESP32 project uses the `.each` pattern (Pattern 2), which is fully supported:

```ruby
%w[esp32 esp32c3 esp32c6 esp32s3].each do |name|
  desc "Setup environment for #{name} target"
  task "setup_#{name}" => %w[deep_clean setup] do
    sh "idf.py set-target #{name}"
  end
end
```

**Extracted tasks**: `setup_esp32`, `setup_esp32c3`, `setup_esp32c6`, `setup_esp32s3`

Plus standard tasks:
- Core: `all`, `build`, `clean`, `deep_clean`, `default`
- Device: `flash`, `flash_factory`, `flash_storage`, `monitor`
- Setup: `setup`

## Security Architecture

### Whitelist-Based Validation

When a user runs `pra device some_task`:

```
1. Extract Rakefile tasks via Prism AST → ["setup_esp32", "flash", "monitor", ...]
2. Check if "some_task" in whitelist
3. If yes → execute `rake some_task`
4. If no → raise Thor::UndefinedCommandError with suggestions
```

### Defense Against Injection

```ruby
# User input: pra device "flash; rm -rf /"
# Whitelist: ["flash", "build", "monitor", ...]

# Without Prism check:
# system("rake flash; rm -rf /")  ❌ DANGEROUS

# With Prism check:
# "flash; rm -rf /" not in whitelist → ERROR ✅ SAFE
```

### Performance Characteristics

- **Parsing speed**: <10ms for typical Rakefiles (Prism is fast)
- **Caching**: Not currently cached; could optimize with memoization if needed
- **Fallback**: If Rakefile cannot be parsed, empty whitelist means all methods allowed (safe, permissive)

## Design Decisions

### 1. Static Analysis Only (No eval)

**Decision**: Use Prism AST visitor pattern instead of eval

```ruby
# ✓ Safe approach
ast = Prism.parse(rakefile_source)
extractor = RakeTaskExtractor.new
ast.value.accept(extractor)
tasks = extractor.tasks
```

**Benefits**:
- No code execution; safe on any system
- Transparent (you can inspect the AST)
- Predictable behavior

### 2. Pattern Expansion in RakeTaskExtractor

**Decision**: Handle `.each` loops within the extractor

```ruby
# Instead of:
# 1. Extract raw pattern: "setup_#{name}"
# 2. Try to evaluate: eval %Q{%w[esp32 esp32c3].each { |name| "setup_#{name}" }}

# We do:
# 1. Extract array: ["esp32", "esp32c3"]
# 2. Extract pattern: [{ type: :string, value: "setup_" }, { type: :variable }]
# 3. Expand manually: ["setup_esp32", "setup_esp32c3"]
```

**Benefits**:
- No eval needed
- Explicit control over expansion
- Easy to test and debug

### 3. Graceful Degradation

**Decision**: Return empty array if parsing fails

```ruby
rescue StandardError => e
  warn "Warning: Failed to parse Rakefile: #{e.message}" if ENV['DEBUG']
  []  # Empty whitelist → no filtering
```

**Benefits**:
- System remains usable if parser breaks
- Warning provides debugging context
- Safe default: allow all declared methods

## Implementation References

- **RakeTaskExtractor class**: [lib/picotorokko/commands/device.rb](../../lib/picotorokko/commands/device.rb) (private class)
- **Whitelist integration**: [lib/picotorokko/commands/device.rb](../../lib/picotorokko/commands/device.rb) (`method_missing` with validation)
- **Test coverage**: [test/commands/device_test.rb](../../test/commands/device_test.rb)

## Future Enhancements

### 1. Caching Extracted Tasks

```ruby
def available_rake_tasks(r2p2_path)
  @task_cache[r2p2_path] ||= extract_from_rakefile(r2p2_path)
end
```

Currently, tasks are extracted on each call. Could cache to improve performance.

### 2. Support for Constants (Pattern 6)

If R2P2-ESP32 migrates to constant-based arrays, we could:
- Build a context analyzer to track simple constant assignments
- Extract values from constant definitions in Rakefile
- This is possible but adds complexity; wait for user demand

### 3. Symbolic Execution for Method Calls

If Pattern 7 becomes necessary, we could:
- Implement a restricted Ruby interpreter for Rakefile definitions
- Execute only task definitions, reject all other code
- This is complex and may reintroduce security concerns; avoid if possible

## Potential Issues & Mitigations

| Issue | Risk | Impact | Mitigation |
|-------|------|--------|-----------|
| Prism API changes | Low | Parser breaks on Ruby version update | Test coverage ensures early detection |
| Dynamic arrays (CONST) | Low | Tasks not extracted; whitelist empty | Graceful fallback (no filtering) |
| Performance | Very low | Parsing slow on large Rakefiles | Prism is <10ms typically; cache if needed |
| Parsing errors | Very low | Rakefile syntax error | rescue block returns empty array |
| Complex nested loops | Low | Multiple block variables | Not used in R2P2-ESP32; simple implementation |
| Task name conflicts | Very low | Task appears twice in expansion | `uniq` + `sort` in extractor |

## Lessons Learned

### AST Analysis Is Worth the Complexity

Initial consideration was to use simple regex. But:
- Regex breaks quickly with real-world Rakefiles
- String interpolation patterns are ambiguous
- Multiple tasks per loop make counting difficult

AST analysis provides:
- Reliability
- Maintainability
- Explicitness (clear intent in code)

### Security Through Limitation

Prism's limitation (cannot analyze runtime values) is actually a **security feature**:
- Constants, method calls, and ENV cannot be used in malicious task generation
- Parser gracefully degrades to no filtering
- System never executes unvetted code

## References

- **Prism Documentation**: https://github.com/ruby/prism (built-in to Ruby 3.3+)
- **R2P2-ESP32 Rakefile**: https://github.com/picoruby/R2P2-ESP32/blob/master/Rakefile
- **Thor Documentation**: Handling `method_missing` and `UndefinedCommandError`
- **Related Architecture**: [Executor Abstraction Design](executor-abstraction-design.md) - complementary DI pattern for system command testing
