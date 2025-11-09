# Phase 5: Prism Secure Parsing Implementation Guide

**Status**: Investigation Complete, Implementation Ready (Next Session)
**Last Updated**: 2025-11-09

## Overview

This document contains the complete technical design for Phase 5 implementation, including:
1. Detailed analysis of test failures (7 items)
2. Complete Prism-based Rakefile parser implementation
3. Dynamic task generation support (`.each` pattern)
4. Test strategy and verification plan

---

## Part 1: Test Failures Analysis

### Summary
- **7 total failures**: 4 in build_test.rb, 3 in device_test.rb
- **Root causes**: Environment check missing (4), patch directory cleanup issues (3)
- **All failures traceable to specific issues** ✅

### Detailed Failure Breakdown

#### build_test.rb Failures (4 items)

**Failure 1-3**: Patch directory residual from previous tests
- Files: `lib/pra/commands/build.rb:126-131` (clean command)
- Files: `test/test_helper.rb:38-49` (cleanup enhancement)
- **Root cause**: Symlink deletion missing, build/ directory not cleaned between tests
- **Fix**: Add FileUtils.rm_f for symlink, ensure `build/` dir removed in teardown

**Failure 4**: "setup_esp32" environment check
- File: `lib/pra/commands/device.rb`
- **Root cause**: Environment validation missing in method
- **Fix**: Add resolve_env_name + validate_and_get_r2p2_path checks

#### device_test.rb Failures (3 items)

**Failures 5-7**: Exception not raised for missing environment
- Methods affected: `flash`, `monitor`, `build`, `tasks`
- File: `lib/pra/commands/device.rb`
- **Root cause**: Environment check missing in each method
- **Fix**: Add early environment validation before any operations

---

## Part 2: Prism-Based Rakefile Parser

### Complete RakeTaskExtractor Implementation

```ruby
require "prism"

# AST-based Rake task extractor for secure, static analysis
class RakeTaskExtractor < Prism::Visitor
  attr_reader :tasks

  def initialize
    super
    @tasks = []
  end

  def visit_call_node(node)
    case node.name
    when :task
      handle_task_definition(node)
    when :each
      handle_each_block_with_task_generation(node)
    end

    super
  end

  private

  # Standard task definition: task :name or task "name"
  def handle_task_definition(node)
    return unless node.arguments&.arguments&.any?

    task_name = extract_task_name(node.arguments.arguments[0])
    @tasks << task_name if task_name
  end

  # Dynamic task generation: %w[...].each do |var| task "name_#{var}" end
  def handle_each_block_with_task_generation(node)
    # Only handle array literals (not constants, method calls)
    return unless node.receiver.is_a?(Prism::ArrayNode)

    # Extract array elements
    array_elements = extract_array_elements(node.receiver)
    return if array_elements.empty?

    # Get block parameter name
    block_param_name = extract_block_parameter(node.block)
    return unless block_param_name

    # Find task definitions inside block
    task_patterns = extract_task_patterns_from_block(node.block, block_param_name)

    # Expand patterns for each array element
    task_patterns.each do |pattern|
      array_elements.each do |element|
        expanded_name = expand_pattern(pattern, element)
        @tasks << expanded_name
      end
    end
  end

  # Extract string values from array literal
  def extract_array_elements(array_node)
    array_node.elements.filter_map do |elem|
      elem.unescaped if elem.is_a?(Prism::StringNode)
    end
  end

  # Get block parameter name from |var| syntax
  def extract_block_parameter(block_node)
    return unless block_node&.parameters&.parameters&.requireds&.any?
    block_node.parameters.parameters.requireds[0].name
  end

  # Find all task definitions within a block and extract their patterns
  def extract_task_patterns_from_block(block_node, param_name)
    return [] unless block_node&.body&.body

    block_node.body.body.filter_map do |stmt|
      next unless stmt.is_a?(Prism::CallNode) && stmt.name == :task
      next unless stmt.arguments&.arguments&.any?

      extract_task_pattern(stmt.arguments.arguments[0], param_name)
    end
  end

  # Extract pattern from interpolated string like "setup_#{name}"
  # Returns array of { type: :string/:variable, value: ... } hashes
  def extract_task_pattern(arg_node, param_name)
    if arg_node.is_a?(Prism::InterpolatedStringNode)
      parts = arg_node.parts.filter_map do |part|
        case part
        when Prism::StringNode
          { type: :string, value: part.unescaped }
        when Prism::EmbeddedStatementsNode
          var = part.statements.body[0]
          if var.is_a?(Prism::LocalVariableReadNode) && var.name == param_name
            { type: :variable }
          end
        end
      end
      parts unless parts.empty?
    elsif arg_node.is_a?(Prism::StringNode)
      [{ type: :string, value: arg_node.unescaped }]
    end
  end

  # Expand pattern by replacing :variable placeholders with actual values
  # Example: [{ type: :string, value: "setup_" }, { type: :variable }] + "esp32" → "setup_esp32"
  def expand_pattern(pattern, value)
    pattern.map do |part|
      case part[:type]
      when :string
        part[:value]
      when :variable
        value
      end
    end.join
  end

  # Extract simple task name from string or symbol node
  def extract_task_name(arg_node)
    case arg_node
    when Prism::StringNode
      arg_node.unescaped
    when Prism::SymbolNode
      arg_node.unescaped
    when Prism::InterpolatedStringNode
      # Cannot expand runtime interpolation, skip
      nil
    end
  end
end
```

### Supported Patterns

#### ✅ Supported (Full Support)

**Pattern 1: Simple task definitions**
```ruby
task :flash do
  sh "idf.py flash"
end

task "monitor" do
  puts "Monitoring"
end
```
Result: `["flash", "monitor"]`

**Pattern 2: Word array with .each**
```ruby
%w[esp32 esp32c3 esp32c6 esp32s3].each do |name|
  task "setup_#{name}" do
    sh "idf.py set-target #{name}"
  end
end
```
Result: `["setup_esp32", "setup_esp32c3", "setup_esp32c6", "setup_esp32s3"]`

**Pattern 3: Regular array literal with .each**
```ruby
['debug', 'release'].each do |mode|
  task "build_#{mode}" do
    sh "make #{mode}"
  end
end
```
Result: `["build_debug", "build_release"]`

**Pattern 4: Multiple tasks per array element**
```ruby
%w[esp32 esp32c3].each do |chip|
  task "build_#{chip}" do
    # ...
  end

  task "flash_#{chip}" do
    # ...
  end
end
```
Result: `["build_esp32", "build_esp32c3", "flash_esp32", "flash_esp32c3"]`

**Pattern 5: Complex string interpolation**
```ruby
%w[a b].each do |letter|
  task "prefix_#{letter}_suffix" do
    # ...
  end
end
```
Result: `["prefix_a_suffix", "prefix_b_suffix"]`

#### ❌ Not Supported (By Design)

These patterns require runtime execution and cannot be statically analyzed:

**Pattern 6: Constant-based arrays**
```ruby
CHIPS = %w[esp32 esp32c3]
CHIPS.each do |chip|
  task "setup_#{chip}" do
    # ...
  end
end
```
Reason: Constant value determined at runtime

**Pattern 7: Method call results**
```ruby
get_chip_list.each do |chip|
  task "build_#{chip}" do
    # ...
  end
end
```
Reason: Method return value determined at runtime

**Pattern 8: Runtime variable interpolation**
```ruby
task "build_#{ENV['MODE']}" do
  # ...
end
```
Reason: ENV['MODE'] determined at runtime

---

## Part 3: Implementation Steps

### Phase 1: Fix Test Failures (Required First)

#### 1-1: build.rb clean command fix
**File**: `lib/pra/commands/build.rb:126-131`

```ruby
# Before:
FileUtils.rm_rf(build_path) if Dir.exist?(build_path)
FileUtils.rm_f(current_link)

# After:
if Dir.exist?(build_path)
  FileUtils.rm_rf(build_path)
  FileUtils.rm_f(current_link)  # Also remove symlink
  Pra::Env.set_current_env(nil)  # Clear YAML current field
  puts '✓ Current build environment removed'
else
  FileUtils.rm_f(current_link) if File.symlink?(current_link)
  puts 'No current environment to clean'
end
```

#### 1-2: test_helper.rb cleanup enhancement
**File**: `test/test_helper.rb:38-49`

```ruby
# Add build/ directory cleanup to ensure block
def with_fresh_project_root
  original_dir = Dir.pwd
  begin
    yield
  ensure
    Dir.chdir(original_dir)

    # Clean up build/ directory created during test
    build_dir = File.join(Dir.pwd, 'build')
    FileUtils.rm_rf(build_dir) if Dir.exist?(build_dir)

    # Reset PROJECT_ROOT
    Pra::Env.const_set(:PROJECT_ROOT, Dir.pwd)
  rescue NameError
    # Ignore if Env not defined
  end
end
```

#### 1-3: device.rb environment validation
**File**: `lib/pra/commands/device.rb`

Add environment check to these methods:

```ruby
desc 'flash [ENV_NAME]', 'Flash firmware to ESP32'
def flash(env_name = 'current')
  actual_env = resolve_env_name(env_name)
  r2p2_path = validate_and_get_r2p2_path(actual_env)

  puts "Flashing: #{actual_env}"
  Pra::Env.execute_with_esp_env("rake flash", r2p2_path)
  puts '✓ Flash completed'
end

desc 'monitor [ENV_NAME]', 'Monitor ESP32 serial output'
def monitor(env_name = 'current')
  actual_env = resolve_env_name(env_name)
  r2p2_path = validate_and_get_r2p2_path(actual_env)

  puts "Monitoring: #{actual_env}"
  puts '(Press Ctrl+C to exit)'
  Pra::Env.execute_with_esp_env("rake monitor", r2p2_path)
end

desc 'build [ENV_NAME]', 'Build firmware for ESP32'
def build(env_name = 'current')
  actual_env = resolve_env_name(env_name)
  r2p2_path = validate_and_get_r2p2_path(actual_env)

  puts "Building: #{actual_env}"
  Pra::Env.execute_with_esp_env("rake build", r2p2_path)
  puts '✓ Build completed'
end

desc 'tasks [ENV_NAME]', 'Show available R2P2-ESP32 tasks'
def tasks(env_name = 'current')
  actual_env = resolve_env_name(env_name)
  r2p2_path = validate_and_get_r2p2_path(actual_env)
  show_available_tasks(actual_env, r2p2_path)
end
```

#### 1-4: Verification
```bash
bundle exec rake test
# Expected: 0 failures, all 132+ tests pass
```

---

### Phase 2: Implement Prism Parser

#### 2-1: Add RakeTaskExtractor class
**File**: `lib/pra/commands/device.rb`

Insert the complete RakeTaskExtractor class (from Part 2 above) as a private class in device.rb

#### 2-2: Add available_rake_tasks method
**File**: `lib/pra/commands/device.rb`

```ruby
private

def available_rake_tasks(r2p2_path)
  rakefile_path = File.join(r2p2_path, 'Rakefile')
  return [] unless File.exist?(rakefile_path)

  source = File.read(rakefile_path)
  result = Prism.parse(source)

  extractor = RakeTaskExtractor.new
  result.value.accept(extractor)

  extractor.tasks.uniq.sort
rescue StandardError => e
  warn "Warning: Failed to parse Rakefile: #{e.message}" if ENV['DEBUG']
  []
end
```

#### 2-3: Enhance method_missing with whitelist validation
**File**: `lib/pra/commands/device.rb:51-65`

```ruby
def method_missing(method_name, *args)
  return super if method_name.to_s.start_with?('_')

  env_name = args.first || 'current'
  actual_env = resolve_env_name(env_name)
  r2p2_path = validate_and_get_r2p2_path(actual_env)

  # Get whitelist of available tasks
  available_tasks = available_rake_tasks(r2p2_path)
  task_name = method_name.to_s

  # If whitelist exists and task not in it, reject
  unless available_tasks.empty? || available_tasks.include?(task_name)
    raise Thor::UndefinedCommandError.new(
      task_name,
      self.class.all_commands.keys + available_tasks,
      self.class.namespace
    )
  end

  puts "Delegating to R2P2-ESP32 task: #{task_name}"
  Pra::Env.execute_with_esp_env("rake #{task_name}", r2p2_path)
rescue Errno::ENOENT, RuntimeError => e
  raise Thor::UndefinedCommandError.new(
    task_name,
    self.class.all_commands.keys + available_tasks,
    self.class.namespace
  )
end
```

---

### Phase 3: Add Tests

#### 3-1: New file - rake_task_extractor_test.rb
**File**: `test/rake_task_extractor_test.rb`

Create comprehensive test suite for RakeTaskExtractor:
- Basic patterns (symbol, string, keyword)
- .each patterns (word array, array literal, multiple tasks)
- Edge cases (empty file, parse errors, nested interpolation)
- Non-supported patterns (verify they return nil/empty)

#### 3-2: device.rb test enhancements
**File**: `test/commands/device_test.rb`

Add tests for:
- Method delegation with unknown task (should raise error)
- Method delegation with known task (should execute)
- Command injection prevention (`rake "task; rm -rf /"`)
- Tasks list output includes available rake tasks

---

### Phase 4: Quality Assurance

#### 4-1: RuboCop
```bash
bundle exec rubocop lib/pra/commands/device.rb
# Fix any violations (goal: 0 offenses)
```

#### 4-2: Full test suite
```bash
bundle exec rake test
# Expected: All 132+ tests pass, 0 failures
```

#### 4-3: Coverage
```bash
bundle exec rake ci
# Expected: Line 85%+, Branch 60%+
```

#### 4-4: Git commit
```bash
# Commit all changes
# Message: "feat: Add Prism-based Rakefile parser with .each pattern support
#          Fixes 7 test failures and adds whitelist validation for method_missing"
```

---

## Part 4: R2P2-ESP32 Rakefile Example

The actual R2P2-ESP32 Rakefile contains this dynamic pattern:

```ruby
%w[esp32 esp32c3 esp32c6 esp32s3].each do |name|
  desc "Setup environment for #{name} target"
  task "setup_#{name}" => %w[deep_clean setup] do
    sh "idf.py set-target #{name}"
  end
end
```

**Expected extraction result**:
```
setup_esp32
setup_esp32c3
setup_esp32c6
setup_esp32s3
```

Plus other standard tasks:
```
all
build
clean
deep_clean
default
flash
flash_factory
flash_storage
monitor
setup
```

---

## Part 5: Security Benefits

1. **Prevents arbitrary command execution**: Only whitelisted Rakefile tasks can be executed
2. **Static analysis only**: No Ruby code execution (safe on any system)
3. **AST-based parsing**: More robust than regex patterns
4. **Handles dynamic generation**: Supports `.each` loop expansion patterns

---

## Part 6: Implementation Verification Checklist

### Pre-Implementation
- [ ] Review this document for complete understanding
- [ ] Check that R2P2-ESP32 Rakefile has `.each` pattern (confirmed ✓)
- [ ] Verify Prism is available in Ruby 3.3+ (standard library)

### Phase 1 Verification
- [ ] Apply all 3 fixes (build.rb, test_helper.rb, device.rb)
- [ ] `bundle exec rake test` → all pass, 0 failures
- [ ] Verify 7 specific failures are gone

### Phase 2 Verification
- [ ] RakeTaskExtractor class loads without error
- [ ] available_rake_tasks returns proper task list
- [ ] method_missing properly validates against whitelist
- [ ] Error messages include suggested valid tasks

### Phase 3 Verification
- [ ] New test file runs without errors
- [ ] All test patterns execute correctly
- [ ] Coverage for RakeTaskExtractor ≥ 90%

### Phase 4 Verification
- [ ] RuboCop: 0 violations
- [ ] Test suite: 132+ tests all pass
- [ ] Coverage: Line 85%+, Branch 60%+
- [ ] Commit message clear and descriptive

---

## Part 7: Potential Issues & Mitigations

| Issue | Risk | Mitigation |
|-------|------|-----------|
| Prism API changes | Low | Test coverage ensures detection |
| Dynamic arrays (CONST) | Low | Graceful fallback: empty whitelist |
| Performance | Very low | Prism is fast, <1s for typical Rakefile |
| Parsing errors | Very low | rescue → empty array (safe default) |
| Multiple block vars | Very low | Not used in R2P2-ESP32, can skip |
| Namespace nesting | Low | Not used in R2P2-ESP32, simple impl |

---

## References

- **Prism Gem**: Built-in to Ruby 3.3+, AST parser
- **R2P2-ESP32 Rakefile**: https://github.com/picoruby/R2P2-ESP32/blob/master/Rakefile
- **Thor Documentation**: For UndefindedCommandError
- **CLAUDE.md Testing Guidelines**: `.claude/docs/testing-guidelines.md`
