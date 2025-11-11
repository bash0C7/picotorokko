# Reality Marble Implementation TODO

**Status**: Design Complete, Ready for Implementation
**Target**: New standalone gem (separate from pra gem)
**Timeline**: To be determined (independent project)

---

## Project Overview

### Concept

**Reality Marble** - A Pure Ruby mock/stub library using Refinements for Test::Unit.

Inspired by TYPE-MOON's "Reality Marble" (固有結界):
- **Chant** (詠唱): Define your mock with normal Ruby syntax
- **Activate** (展開): Deploy the marble in test scope
- **Trace** (痕跡): Observe what happened inside
- **Auto-dissolution**: Automatic cleanup on block exit

### Key Features

- ✅ **Zero pollution** - Refinements provide lexical scoping
- ✅ **Zero cleanup** - Automatic on block exit (ensure)
- ✅ **Zero learning curve** - Normal Ruby syntax (refine/def/super)
- ✅ **Thread-safe** - Context isolated per thread
- ✅ **Test::Unit focused** - Optimized for one framework

### Design Philosophy

1. **Explicit declaration**: `using RealityMarble.chant` in every test file (明示的宣言)
2. **Normal Ruby syntax**: 100% standard Ruby inside `refine` blocks
3. **Automatic trace recording**: No manual instrumentation needed
4. **Method wrapping, not TracePoint**: Performance-friendly approach

---

## Final Design Summary

### API Overview

```ruby
require 'test/unit'
require 'reality_marble'

class GitTest < Test::Unit::TestCase
  # Step 1: Chant (Define marble with Refinements)
  using RealityMarble.chant do
    refine Kernel do
      def system(cmd)
        case cmd
        when /git clone/ then true
        when /git checkout/ then false
        else super  # Call original
        end
      end
    end
  end

  # Step 2: Activate (Deploy marble + auto trace)
  def test_git_commands
    RealityMarble.activate do |trace|
      system('git clone repo')
      system('git checkout main')

      # Step 3: Verify with trace
      assert_equal 2, trace[Kernel, :system].invocations
      assert trace[Kernel, :system].summoned_with?(/git clone/)
    end
  end
end
```

### Core Components

1. **RealityMarble.chant** → Returns Refinement module
2. **RealityMarble.activate** → Thread-local context + ensure cleanup
3. **Trace** → Spy-like recording (invocations, summoned_with?, etc.)
4. **Automatic wrapping** → Methods in `refine` blocks are auto-instrumented

---

## Implementation Plan

### Phase 0: Project Setup

**Goal**: Create gem skeleton with proper structure

#### Tasks

- [ ] Create new gem project: `bundle gem reality_marble`
- [ ] Setup gemspec
  - [ ] Name: `reality_marble`
  - [ ] Summary: "Pure Ruby mock library using Refinements for Test::Unit"
  - [ ] Description: Full description with TYPE-MOON metaphor
  - [ ] Dependencies: None (zero runtime dependencies)
  - [ ] Development dependencies: test-unit, rake, rubocop
  - [ ] Ruby version: >= 3.4.0
- [ ] Setup directory structure
  ```
  reality_marble/
  ├── lib/
  │   ├── reality_marble.rb
  │   └── reality_marble/
  │       ├── version.rb
  │       ├── chant.rb
  │       ├── activation.rb
  │       ├── trace.rb
  │       └── record.rb
  ├── test/
  │   ├── test_helper.rb
  │   └── reality_marble/
  ├── examples/
  ├── docs/
  ├── reality_marble.gemspec
  ├── Gemfile
  ├── Rakefile
  ├── README.md
  ├── CHANGELOG.md
  └── LICENSE (MIT)
  ```
- [ ] Setup Rakefile (test, rubocop tasks)
- [ ] Setup .rubocop.yml
- [ ] Setup .gitignore
- [ ] Initialize git repository
- [ ] Create initial README.md (basic structure)

---

### Phase 1: Core Implementation (Chant + Activate + Basic Trace)

**Goal**: Implement minimal working version

#### 1.1 Chant Implementation

**File**: `lib/reality_marble/chant.rb`

```ruby
module RealityMarble
  module Chant
    # Registry of refined methods
    @refined_methods = Set.new

    class << self
      attr_reader :refined_methods

      def create(&refinement_block)
        Module.new do
          # Override refine to track and wrap methods
          define_singleton_method(:refine) do |target_class, &block|
            super(target_class) do
              # Capture methods before user block
              before_methods = instance_methods(false)

              # Execute user's method definitions
              module_eval(&block)

              # Detect newly defined methods
              after_methods = instance_methods(false)
              new_methods = after_methods - before_methods

              # Register and wrap each new method
              new_methods.each do |method_name|
                RealityMarble::Chant.register(target_class, method_name)
                wrap_with_trace(target_class, method_name)
              end
            end
          end

          # Execute user's refinement block
          module_eval(&refinement_block)
        end
      end

      def register(target_class, method_name)
        @refined_methods << [target_class, method_name]
      end

      def refined?(target_class, method_name)
        @refined_methods.include?([target_class, method_name])
      end
    end

    private

    # Wrap method with automatic trace recording
    def wrap_with_trace(target_class, method_name)
      original = instance_method(method_name)

      define_method(method_name) do |*args, **kwargs, &block|
        ctx = Thread.current[:reality_marble_context]

        if ctx
          # Record call with context
          trace = ctx.trace_for(target_class, method_name)
          record = trace.start_call(args, kwargs, block)

          begin
            result = original.bind(self).call(*args, **kwargs, &block)
            record.finish(result)
            result
          rescue => e
            record.finish_with_error(e)
            raise
          end
        else
          # No context: just call original
          original.bind(self).call(*args, **kwargs, &block)
        end
      end
    end
  end
end
```

**Tasks**:
- [ ] Implement `RealityMarble::Chant` module
- [ ] Implement `create` method (returns Refinement module)
- [ ] Implement `refine` override with method detection
- [ ] Implement method registry (Set-based)
- [ ] Implement `wrap_with_trace` (UnboundMethod approach)
- [ ] Test: Basic chant creation
- [ ] Test: Method registration
- [ ] Test: Multiple refine blocks

#### 1.2 Activation Implementation

**File**: `lib/reality_marble/activation.rb`

```ruby
module RealityMarble
  class Activation
    def initialize
      @traces = {}
    end

    # Access trace by [Class, :method]
    def [](target_class, method_name)
      trace_for(target_class, method_name)
    end

    def trace_for(target_class, method_name)
      key = [target_class, method_name]
      @traces[key] ||= Trace.new(target_class, method_name)
    end
  end

  module_function

  def activate(&test_block)
    context = Activation.new
    Thread.current[:reality_marble_context] = context

    begin
      test_block.call(context)
    ensure
      Thread.current[:reality_marble_context] = nil
    end
  end
end
```

**Tasks**:
- [ ] Implement `Activation` class
- [ ] Implement `trace_for` method
- [ ] Implement `[]` accessor (syntactic sugar)
- [ ] Implement `activate` module function
- [ ] Thread-local context management
- [ ] Ensure cleanup in ensure block
- [ ] Test: Context creation and cleanup
- [ ] Test: Thread isolation
- [ ] Test: Multiple activations (sequential)

#### 1.3 Basic Trace Implementation

**File**: `lib/reality_marble/trace.rb`

```ruby
module RealityMarble
  class Trace
    attr_reader :target_class, :method_name, :records

    def initialize(target_class, method_name)
      @target_class = target_class
      @method_name = method_name
      @records = []
    end

    def start_call(args, kwargs, block)
      record = Record.new(args, kwargs, block)
      @records << record
      record
    end

    # Basic query methods
    def invocations
      @records.size
    end

    def summoned?
      @records.any?
    end

    def dormant?
      @records.empty?
    end

    def first_record
      @records.first
    end

    def last_record
      @records.last
    end
  end
end
```

**File**: `lib/reality_marble/record.rb`

```ruby
module RealityMarble
  class Record
    attr_reader :arguments, :keyword_arguments, :block, :timestamp
    attr_accessor :outcome, :error, :duration

    def initialize(args, kwargs, block)
      @arguments = args
      @keyword_arguments = kwargs
      @block = block
      @timestamp = Time.now
      @outcome = nil
      @error = nil
      @duration = nil
    end

    def finish(result)
      @outcome = result
      @duration = Time.now - @timestamp
    end

    def finish_with_error(error)
      @error = error
      @duration = Time.now - @timestamp
    end

    def success?
      @error.nil?
    end

    def failed?
      !@error.nil?
    end
  end
end
```

**Tasks**:
- [ ] Implement `Trace` class
- [ ] Implement `start_call` (creates Record)
- [ ] Implement basic query methods (invocations, summoned?, dormant?)
- [ ] Implement `Record` class
- [ ] Implement `finish` and `finish_with_error`
- [ ] Test: Record creation and storage
- [ ] Test: Basic query methods
- [ ] Test: Multiple calls to same method

#### 1.4 Main Entry Point

**File**: `lib/reality_marble.rb`

```ruby
require_relative 'reality_marble/version'
require_relative 'reality_marble/chant'
require_relative 'reality_marble/activation'
require_relative 'reality_marble/trace'
require_relative 'reality_marble/record'

module RealityMarble
  class Error < StandardError; end

  module_function

  def chant(&refinement_block)
    Chant.create(&refinement_block)
  end

  def activate(&test_block)
    context = Activation.new
    Thread.current[:reality_marble_context] = context

    begin
      test_block.call(context)
    ensure
      Thread.current[:reality_marble_context] = nil
    end
  end
end
```

**Tasks**:
- [ ] Implement main module entry point
- [ ] Require all submodules
- [ ] Define `chant` convenience method
- [ ] Define `activate` convenience method
- [ ] Test: End-to-end basic flow
- [ ] Test: Kernel#system mock
- [ ] Test: Multiple methods in single marble

---

### Phase 2: Advanced Trace Features

**Goal**: Implement pattern matching and advanced queries

#### 2.1 Pattern Matching

**Add to `Trace` class**:

```ruby
def summoned_with?(*expected_args, **expected_kwargs, &matcher)
  @records.any? do |record|
    if matcher
      # Block-based matching
      matcher.call(*record.arguments, **record.keyword_arguments)
    elsif expected_args.size == 1 && expected_args.first.is_a?(Regexp)
      # Regex matching (join args as string)
      record.arguments.join(' ') =~ expected_args.first
    elsif expected_args.empty? && expected_kwargs.empty?
      # No pattern given
      false
    else
      # Exact match
      record.arguments == expected_args &&
        record.keyword_arguments == expected_kwargs
    end
  end
end
```

**Tasks**:
- [ ] Implement `summoned_with?` with multiple patterns
- [ ] Support exact match (args comparison)
- [ ] Support Regexp match (join args as string)
- [ ] Support block-based matching
- [ ] Test: Exact match
- [ ] Test: Regex match
- [ ] Test: Block match
- [ ] Test: Edge cases (empty args, kwargs only)

#### 2.2 Record Filtering

**Add to `Trace` class**:

```ruby
def select_records(&filter)
  @records.select(&filter)
end

def successful_calls
  @records.select(&:success?)
end

def failed_calls
  @records.select(&:failed?)
end
```

**Tasks**:
- [ ] Implement `select_records`
- [ ] Implement `successful_calls`
- [ ] Implement `failed_calls`
- [ ] Test: Filtering by outcome
- [ ] Test: Filtering by custom criteria

---

### Phase 3: Class Method Support

**Goal**: Support mocking class methods (singleton_class)

#### 3.1 Singleton Class Refinement

**Example usage**:

```ruby
using RealityMarble.chant do
  refine FileUtils.singleton_class do
    def mkdir_p(path)
      puts "Mock: mkdir_p(#{path})"
      [path]
    end
  end
end
```

**Tasks**:
- [ ] Test singleton_class refinement
- [ ] Ensure method wrapping works for class methods
- [ ] Test: FileUtils.mkdir_p mocking
- [ ] Test: Custom class methods
- [ ] Document singleton_class pattern

---

### Phase 4: Test::Unit Integration Helpers

**Goal**: Provide convenience helpers for Test::Unit

#### 4.1 Test Helper Module

**File**: `lib/reality_marble/test_unit.rb`

```ruby
module RealityMarble
  module TestUnit
    # Convenience method for activate
    def with_marble(&block)
      RealityMarble.activate(&block)
    end

    # Assert helpers
    def assert_summoned(trace, message = nil)
      assert trace.summoned?, message || "Expected #{trace.method_name} to be called"
    end

    def assert_not_summoned(trace, message = nil)
      assert trace.dormant?, message || "Expected #{trace.method_name} not to be called"
    end

    def assert_summoned_with(trace, *expected, **kwargs, &block)
      assert trace.summoned_with?(*expected, **kwargs, &block),
             "Expected #{trace.method_name} to be called with #{expected.inspect}"
    end
  end
end
```

**Tasks**:
- [ ] Implement `TestUnit` helper module
- [ ] Implement `with_marble` alias
- [ ] Implement `assert_summoned`
- [ ] Implement `assert_not_summoned`
- [ ] Implement `assert_summoned_with`
- [ ] Test: Helper methods in Test::Unit context
- [ ] Document usage in README

---

### Phase 5: Documentation & Examples

**Goal**: Complete documentation with rich examples

#### 5.1 README.md

**Sections**:
1. Project overview with TYPE-MOON metaphor
2. Installation
3. Quick start (3-step usage)
4. Core concepts (chant/activate/trace)
5. API reference (brief)
6. Test::Unit integration
7. Advanced usage (link to docs/)
8. Contributing
9. License

**Tasks**:
- [ ] Write project overview
- [ ] Write installation guide
- [ ] Write quick start (3 examples)
- [ ] Write core concepts section
- [ ] Write API reference summary
- [ ] Add badges (gem version, build status, etc.)
- [ ] Proofread and polish

#### 5.2 Detailed Documentation

**Files**:
- `docs/CONCEPT.md` - Reality Marble metaphor explained
- `docs/API.md` - Complete API reference
- `docs/TRACE_API.md` - Trace methods reference
- `docs/ADVANCED.md` - Custom logging workarounds
- `docs/RECIPES.md` - Common patterns and recipes

**Tasks**:
- [ ] Write CONCEPT.md (TYPE-MOON background)
- [ ] Write API.md (complete method reference)
- [ ] Write TRACE_API.md (all Trace methods)
- [ ] Write ADVANCED.md (custom logging with closures)
- [ ] Write RECIPES.md (common patterns)

#### 5.3 Example Code

**Files**:
- `examples/basic_example.rb` - Simple Kernel#system mock
- `examples/git_commands.rb` - Git command mocking
- `examples/file_operations.rb` - FileUtils mocking
- `examples/http_requests.rb` - Net::HTTP mocking
- `examples/backtick_commands.rb` - Backtick (`) mocking
- `examples/custom_logging.rb` - Advanced: Custom trace with closures

**Tasks**:
- [ ] Write basic_example.rb
- [ ] Write git_commands.rb (realistic git workflow)
- [ ] Write file_operations.rb (FileUtils)
- [ ] Write http_requests.rb (Net::HTTP)
- [ ] Write backtick_commands.rb (` mocking)
- [ ] Write custom_logging.rb (closure-based logging)
- [ ] Ensure all examples are runnable
- [ ] Add comments explaining each pattern

---

### Phase 6: Integration with pra gem (This Project)

**Goal**: Replace SystemCommandMocking with Reality Marble

#### 6.1 Analysis of Existing Code

**Current implementation**: `test/commands/env_test.rb` (lines 6-77)

**Components**:
- `SystemCommandMocking` module
- `SystemRefinement` with Kernel#system refinement
- `with_system_mocking` helper
- Thread-local mock context
- Call counting and failure simulation

**Tasks**:
- [ ] Review current SystemCommandMocking implementation
- [ ] Identify all mocking patterns used
- [ ] List all test cases that depend on it
- [ ] Document migration requirements

#### 6.2 Migration Plan

**Step 1**: Add Reality Marble as development dependency

```ruby
# picoruby-application-on-r2p2-esp32-development-kit.gemspec
spec.add_development_dependency 'reality_marble', '~> 0.1.0'
```

**Step 2**: Create marble definition for git commands

```ruby
# test/support/git_marble.rb
using RealityMarble.chant do
  refine Kernel do
    def system(cmd)
      case cmd
      when /git clone/
        # Create dummy git repository
        if cmd =~ /git clone.* (\S+)\s*$/
          dest_path = $1.gsub(/['"]/, '')
          FileUtils.mkdir_p(dest_path)
          FileUtils.mkdir_p(File.join(dest_path, '.git'))
        end
        true
      when /git checkout/
        true
      when /git submodule update/
        true
      else
        super
      end
    end
  end
end
```

**Step 3**: Rewrite test cases

**Before** (SystemCommandMocking):
```ruby
def test_clone_success
  with_system_mocking do |mock|
    # ...
    assert_equal 1, mock[:call_count][:clone]
  end
end
```

**After** (Reality Marble):
```ruby
def test_clone_success
  RealityMarble.activate do |trace|
    # ...
    assert_equal 1, trace[Kernel, :system].invocations
    assert trace[Kernel, :system].summoned_with?(/git clone/)
  end
end
```

**Tasks**:
- [ ] Add reality_marble to gemspec (development dependency)
- [ ] Create `test/support/git_marble.rb`
- [ ] Migrate `test_clone_success` test case
- [ ] Migrate `test_clone_failure` test case
- [ ] Migrate `test_checkout_failure` test case
- [ ] Migrate `test_submodule_failure` test case
- [ ] Remove old `SystemCommandMocking` module
- [ ] Run full test suite (ensure all pass)
- [ ] Update test_helper.rb if needed

#### 6.3 Verification

**Tasks**:
- [ ] Run `bundle exec rake test` (all tests pass)
- [ ] Run `bundle exec rake ci` (coverage maintained)
- [ ] Verify no SystemCommandMocking references remain
- [ ] Git commit: "refactor: replace SystemCommandMocking with Reality Marble"

---

### Phase 7: Polish & Release Preparation

**Goal**: Prepare gem for public release

#### 7.1 Code Quality

**Tasks**:
- [ ] Run RuboCop (0 violations)
- [ ] Run test suite (100% pass rate)
- [ ] Measure test coverage (target: 90%+ line, 80%+ branch)
- [ ] Add YARD documentation comments
- [ ] Generate API documentation

#### 7.2 Release Checklist

**Tasks**:
- [ ] Update CHANGELOG.md (version 0.1.0)
- [ ] Update version.rb (0.1.0)
- [ ] Review README.md (final polish)
- [ ] Review all documentation
- [ ] Create GitHub repository
- [ ] Push code to GitHub
- [ ] Create git tag: v0.1.0
- [ ] Build gem: `gem build reality_marble.gemspec`
- [ ] Test gem installation locally
- [ ] Publish to RubyGems.org: `gem push reality_marble-0.1.0.gem`
- [ ] Announce on Twitter/社交媒体

---

## Sample Code (Complete Examples)

### Example 1: Basic Git Command Mocking

```ruby
require 'test/unit'
require 'reality_marble'

class GitCommandTest < Test::Unit::TestCase
  # Chant: Define Reality Marble
  using RealityMarble.chant do
    refine Kernel do
      def system(cmd)
        case cmd
        when /git clone/
          puts "[Marble] git clone → success"
          true
        when /git checkout/
          puts "[Marble] git checkout → failure"
          false
        else
          super  # Call original for non-git commands
        end
      end
    end
  end

  def test_git_clone_succeeds_in_marble
    RealityMarble.activate do |trace|
      result = system('git clone https://github.com/user/repo.git')

      assert_true result
      assert_equal 1, trace[Kernel, :system].invocations
      assert trace[Kernel, :system].summoned_with?(/git clone/)
    end
  end

  def test_git_checkout_fails_in_marble
    RealityMarble.activate do |trace|
      result = system('git checkout main')

      assert_false result
      assert_equal 1, trace[Kernel, :system].invocations
    end
  end

  def test_non_git_commands_use_original
    RealityMarble.activate do |trace|
      system('echo hello')  # Uses real system

      # Still recorded
      assert_equal 1, trace[Kernel, :system].invocations
    end
  end
end
```

### Example 2: File Operations

```ruby
require 'test/unit'
require 'reality_marble'
require 'fileutils'

class FileOperationsTest < Test::Unit::TestCase
  using RealityMarble.chant do
    refine FileUtils.singleton_class do
      def mkdir_p(path)
        puts "[Marble] mkdir_p: #{path}"
        [path]  # Return path without actually creating
      end

      def rm_rf(path)
        puts "[Marble] rm_rf: #{path} (blocked)"
        # Do nothing (safe in tests)
      end
    end
  end

  def test_mkdir_without_side_effects
    RealityMarble.activate do |trace|
      result = FileUtils.mkdir_p('/tmp/test/deep/path')

      assert_equal ['/tmp/test/deep/path'], result
      assert_equal 1, trace[FileUtils.singleton_class, :mkdir_p].invocations
    end
  end

  def test_rm_rf_is_safe
    RealityMarble.activate do |trace|
      FileUtils.rm_rf('/important/data')  # Safe in marble!

      assert_equal 1, trace[FileUtils.singleton_class, :rm_rf].invocations
    end
  end
end
```

### Example 3: Backtick Commands

```ruby
require 'test/unit'
require 'reality_marble'

class BacktickCommandTest < Test::Unit::TestCase
  using RealityMarble.chant do
    refine Kernel do
      def `(cmd)
        case cmd
        when /date/
          "2025-11-10\n"
        when /uname/
          "Reality Marble OS\n"
        else
          super
        end
      end
    end
  end

  def test_date_command_returns_fixed_date
    RealityMarble.activate do |trace|
      output = `date`

      assert_equal "2025-11-10\n", output
      assert_equal 1, trace[Kernel, :`].invocations
    end
  end

  def test_multiple_backtick_calls
    RealityMarble.activate do |trace|
      date = `date`
      os = `uname`

      assert_equal "2025-11-10\n", date
      assert_equal "Reality Marble OS\n", os
      assert_equal 2, trace[Kernel, :`].invocations

      # Verify each call
      assert trace[Kernel, :`].summoned_with?(/date/)
      assert trace[Kernel, :`].summoned_with?(/uname/)
    end
  end
end
```

### Example 4: Advanced - Custom Logging

```ruby
require 'test/unit'
require 'reality_marble'

class CustomLoggingTest < Test::Unit::TestCase
  using RealityMarble.chant do
    # Use closure to capture custom data
    http_requests = []

    refine Net::HTTP do
      def request(req)
        # Custom logging (beyond automatic trace)
        http_requests << {
          method: req.method,
          path: req.path,
          headers: req.to_hash,
          body: req.body,
          timestamp: Time.now
        }

        # Mock response
        Net::HTTPSuccess.new('1.1', '200', 'OK')
      end
    end

    # Helper to access custom log
    def all_http_requests
      http_requests
    end

    def post_requests
      http_requests.select { |r| r[:method] == 'POST' }
    end
  end

  def test_http_requests_with_custom_logging
    RealityMarble.activate do |trace|
      http = Net::HTTP.new('api.example.com')
      http.request(Net::HTTP::Post.new('/users'))
      http.request(Net::HTTP::Get.new('/status'))

      # Automatic trace
      assert_equal 2, trace[Net::HTTP, :request].invocations

      # Custom logging
      assert_equal 2, all_http_requests.size
      assert_equal 1, post_requests.size
      assert_equal '/users', post_requests.first[:path]
    end
  end
end
```

---

## Documentation Structure

### README.md Outline

```markdown
# Reality Marble

Pure Ruby mock library using Refinements for Test::Unit.

> "I am the bone of my sword" - Inspired by TYPE-MOON's Reality Marble (固有結界)

## Features

- Zero pollution (Refinements scoped)
- Zero cleanup (automatic)
- Zero learning curve (normal Ruby syntax)
- Thread-safe
- Test::Unit focused

## Installation

gem install reality_marble

## Quick Start

[3-step example]

## Core Concepts

### Chant (詠唱)
### Activate (展開)
### Trace (痕跡)

## API Reference

[Brief summary, link to docs/API.md]

## Test::Unit Integration

[Helper methods]

## Advanced Usage

[Link to docs/ADVANCED.md]

## Contributing

## License

MIT
```

### docs/CONCEPT.md Outline

```markdown
# Reality Marble Concept

## TYPE-MOON Background

[Explanation of 固有結界 in Fate/月姫]

## Metaphor Mapping

| Reality Marble | RealityMarble Gem |
|----------------|-------------------|
| Chant (詠唱)   | using RealityMarble.chant |
| Deploy (展開)  | RealityMarble.activate |
| Inner world    | Refinement scope |
| Auto-fade      | Block exit cleanup |
| Trace (痕跡)   | Spy recording |

## Why This Metaphor Works

[Technical + poetic explanation]
```

### docs/API.md Outline

```markdown
# API Reference

## Module: RealityMarble

### RealityMarble.chant(&block)
### RealityMarble.activate(&block)

## Class: RealityMarble::Trace

### Instance Methods

- invocations
- summoned?
- dormant?
- summoned_with?(...)
- first_record
- last_record
- records

## Class: RealityMarble::Record

### Attributes

- arguments
- keyword_arguments
- outcome
- error
- timestamp
- duration

### Methods

- success?
- failed?
```

### docs/RECIPES.md Outline

```markdown
# Common Recipes

## Recipe 1: Mock git commands
## Recipe 2: Mock file operations
## Recipe 3: Mock HTTP requests
## Recipe 4: Mock time-dependent code
## Recipe 5: Mock external API calls
## Recipe 6: Combine multiple marbles
## Recipe 7: Custom logging patterns
```

---

## Testing Strategy

### Test Coverage Goals

- **Line coverage**: 90%+
- **Branch coverage**: 80%+
- **All public APIs**: 100% tested

### Test Organization

```
test/
├── test_helper.rb
├── reality_marble/
│   ├── chant_test.rb          # Chant functionality
│   ├── activation_test.rb     # Activation + context
│   ├── trace_test.rb          # Trace queries
│   ├── record_test.rb         # Record attributes
│   ├── wrapping_test.rb       # Method wrapping
│   ├── thread_safety_test.rb # Thread isolation
│   └── integration_test.rb    # End-to-end scenarios
```

### Key Test Cases

#### Chant Tests
- Basic refine block
- Multiple refine blocks
- Multiple methods in single refine
- Class methods (singleton_class)
- Method with super
- Method with complex logic

#### Activation Tests
- Basic activate
- Thread-local context
- Ensure cleanup on exception
- Multiple sequential activations
- Thread isolation

#### Trace Tests
- Basic invocation counting
- summoned? / dormant?
- summoned_with? patterns (exact, regex, block)
- first_record / last_record
- Multiple calls to same method

#### Wrapping Tests
- super calls original method
- Arguments passed correctly
- Return value captured
- Exception handling
- Block arguments

#### Integration Tests
- Kernel#system mocking
- FileUtils mocking
- Backtick mocking
- Multiple methods simultaneously
- Real-world git command scenario

---

## Technical Notes

### Refinement Wrapping Implementation

**Key insight**: Use `instance_method` + `define_method` pattern

```ruby
def wrap_with_trace(target_class, method_name)
  original = instance_method(method_name)

  define_method(method_name) do |*args, **kwargs, &block|
    # Trace logic here
    original.bind(self).call(*args, **kwargs, &block)
  end
end
```

**Why this works**:
1. `instance_method(method_name)` captures UnboundMethod
2. `define_method` replaces it with wrapper
3. `original.bind(self).call` invokes captured method
4. `super` still works (goes to pre-Refinement method)

### Thread Safety

**Context isolation**:
```ruby
Thread.current[:reality_marble_context] = context
```

Each thread has independent context, no shared state.

### Performance Considerations

**No TracePoint overhead**:
- Only wrapped methods have trace logic
- No global method monitoring
- Minimal performance impact

**Benchmarks** (to be measured):
- Wrapping overhead: < 5% vs direct call
- Memory overhead: ~100 bytes per Record

---

## Migration Guide (for pra gem)

### Before (SystemCommandMocking)

```ruby
module SystemCommandMocking
  module SystemRefinement
    refine Kernel do
      def system(*args)
        mock_context = Thread.current[:system_mock_context]
        return ORIGINAL_SYSTEM.bind(self).call(*args) unless mock_context

        cmd = args.join(' ')
        if cmd.include?('git clone')
          mock_context[:call_count][:clone] += 1
          return false if mock_context[:fail_clone]
          # ...
        end
      end
    end
  end

  def with_system_mocking(fail_clone: false, ...)
    # Manual context setup
  end
end
```

### After (Reality Marble)

```ruby
using RealityMarble.chant do
  refine Kernel do
    def system(cmd)
      case cmd
      when /git clone/
        # Setup logic here
        true
      else
        super
      end
    end
  end
end

def test_git_clone
  RealityMarble.activate do |trace|
    # Test logic
    assert trace[Kernel, :system].summoned_with?(/git clone/)
  end
end
```

### Benefits of Migration

1. **Simpler**: Less boilerplate
2. **Standard**: Uses gem instead of custom code
3. **Maintainable**: Gem is tested and documented
4. **Readable**: Normal Ruby syntax

---

## Future Enhancements (Post-v1.0)

### Possible Features

- [ ] RSpec integration (if demand exists)
- [ ] Minitest integration
- [ ] Marble chaining (marble1 + marble2)
- [ ] Marble inheritance
- [ ] Record serialization (JSON export)
- [ ] Web UI for trace visualization
- [ ] Performance profiling integration

### Out of Scope (Philosophy)

- ❌ Auto-mocking (against explicit declaration)
- ❌ Framework-agnostic (Test::Unit focus is strength)
- ❌ DSL for method definition (normal Ruby is better)

---

## Success Criteria

### v0.1.0 Release Checklist

- [ ] All Phase 1-5 tasks complete
- [ ] Test coverage ≥ 90% line, ≥ 80% branch
- [ ] RuboCop: 0 violations
- [ ] Documentation complete (README + docs/)
- [ ] Examples runnable
- [ ] Gem builds successfully
- [ ] Published to RubyGems.org

### Post-Release

- [ ] pra gem migration complete (Phase 6)
- [ ] Blog post written (Japanese + English)
- [ ] Community feedback collected
- [ ] GitHub issues addressed
- [ ] v0.2.0 planning (based on feedback)

---

## Contact & Contribution

**Maintainer**: bash0C7 (from pra gem project)
**Repository**: (TBD - to be created)
**License**: MIT

**Contribution welcome**:
- Bug reports
- Feature requests (aligned with philosophy)
- Documentation improvements
- Example code

---

## Appendix: Design Decisions

### Why Refinements?

- Lexical scoping (no global pollution)
- Built-in to Ruby 3.4+ (no dependencies)
- Perfect metaphor for "alternate reality"

### Why Test::Unit Only?

- Focus on one framework = better quality
- Most pra gem tests use Test::Unit
- Simpler implementation and documentation

### Why No TracePoint?

- Performance (avoid global monitoring)
- Noise (too many irrelevant events)
- Precision (only track refined methods)

### Why Normal Ruby Syntax?

- Zero learning curve
- IDE support (syntax highlighting, completion)
- Flexibility (full Ruby power)

---

**END OF REALITY_MARBLE_TODO.md**
