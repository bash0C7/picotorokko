# Phase 0: Executor Abstraction Infrastructure (Session 6)

**Status**: ✅ COMPLETE
**Session**: Session 6
**Key Commits**: d8c2c89, 4b3397c, 95f2caf, 89ee6ae, 0f1c543

## Overview

Phase 0 solved a critical testing infrastructure problem: system() command mocking was broken due to Ruby Refinements' lexical scoping limitations. The solution implements a clean dependency injection pattern for command execution, enabling testable design and eliminating global state pollution.

## Problem Statement

### Original Issue: Refinement Lexical Scope

Ruby Refinements are lexically scoped, not dynamically scoped:

```ruby
# env_test.rb
using SystemCommandMocking::SystemRefinement
  ↓
Pra::Env.clone_repo()
  ↓ (calls system() in lib/pra/env.rb's lexical scope)
  ↓
❌ Refinement NOT active → real git commands execute

# Real output: Network error when trying to clone
# Expected: Mocked git command
```

**Impact**:
- 3 tests permanently omitted in env_test.rb
- branch coverage incomplete (error handling paths untested)
- Cannot verify system() error handling without refactoring

### Tests Affected

1. `test/commands/env_test.rb:1206` - "clone_repo raises error when git clone fails"
2. `test/commands/env_test.rb:1239` - "clone_repo raises error when git checkout fails"
3. `test/commands/env_test.rb:1275` - "clone_with_submodules raises error when submodule init fails"

## Solution: Dependency Injection with Executor Abstraction

### Architecture

Create an abstraction layer for command execution:

```
┌─────────────────────────────────────┐
│  Test Code (env_test.rb)            │
│                                     │
│  mock = MockExecutor.new            │
│  Pra::Env.set_executor(mock)        │
│                                     │
│  mock.set_result("git clone url", )|
│       .fail: true)                  │
│                                     │
│  # Now clone_repo() uses mock       │
└─────────────────────────────────────┘
           │
           ↓
┌─────────────────────────────────────┐
│  Pra::Env (lib/pra/env.rb)          │
│                                     │
│  def execute_with_esp_env(cmd, dir) │
│    executor.execute(cmd, dir)       │
│  end                                │
└─────────────────────────────────────┘
           │
           ↓
      ┌────┴─────┐
      │           │
      ↓           ↓
  ┌─────────┐ ┌─────────────┐
  │ Prod    │ │ Test        │
  │Executor │ │ Executor    │
  └─────────┘ └─────────────┘
  Open3.    │  Mock
  capture3  │  calls
```

### Implementation

**lib/pra/executor.rb** - Command Execution Interface

```ruby
module Pra
  # Executor interface: all implementations must provide execute(command, working_dir)
  # Returns: [stdout, stderr] on success
  # Raises: RuntimeError on non-zero exit code

  module Executor
    def execute(command, working_dir = nil)
      raise NotImplementedError
    end
  end

  # Production: Real command execution via Open3
  class ProductionExecutor
    include Executor

    def execute(command, working_dir = nil)
      execute_block = lambda do
        stdout, stderr, status = Open3.capture3(command)
        raise "Command failed..." unless status.success?
        [stdout, stderr]
      end

      working_dir ? Dir.chdir(working_dir) { execute_block.call } : execute_block.call
    end
  end

  # Testing: Mock executor for test control
  class MockExecutor
    include Executor

    def initialize
      @calls = []
      @results = {}
    end

    def execute(command, working_dir = nil)
      @calls << { command: command, working_dir: working_dir }

      # Return preset result if configured
      if @results[command]
        stdout, stderr, should_fail = @results[command]
        raise RuntimeError, "..." if should_fail
        return [stdout, stderr]
      end

      ["", ""]  # Default success
    end

    def set_result(command, stdout: "", stderr: "", fail: false)
      @results[command] = [stdout, stderr, fail]
    end

    attr_reader :calls
  end
end
```

**lib/pra/env.rb** - Dependency Injection

```ruby
class << self
  # Executor management
  def set_executor(executor)
    @executor = executor
  end

  def executor
    @executor ||= ProductionExecutor.new
  end

  # Refactored methods using executor
  def clone_repo(repo_url, dest_path, commit)
    return if Dir.exist?(dest_path)

    cmd = "git clone #{Shellwords.escape(repo_url)} #{Shellwords.escape(dest_path)}"
    executor.execute(cmd)  # ← Uses injected executor

    cmd = "git checkout #{Shellwords.escape(commit)}"
    executor.execute(cmd, dest_path)
  end

  def execute_with_esp_env(command, working_dir = nil)
    executor.execute(command, working_dir)
  end
end
```

**test/commands/env_test.rb** - Test Usage

```ruby
def "clone_repo raises error when git clone fails"
  # 1. Create mock
  mock_executor = Pra::MockExecutor.new

  # 2. Configure failure
  mock_executor.set_result(
    "git clone https://github.com/test/repo.git dest",
    fail: true,
    stderr: "fatal: could not read Username"
  )

  # 3. Inject mock
  original_executor = Pra::Env.executor
  Pra::Env.set_executor(mock_executor)

  begin
    # 4. Test failure path
    error = assert_raise(RuntimeError) do
      Pra::Env.clone_repo("https://github.com/test/repo.git", "dest", "abc1234")
    end

    # 5. Verify
    assert_include error.message, "Command failed"
    assert_equal 1, mock_executor.calls.length
  ensure
    Pra::Env.set_executor(original_executor)
  end
end
```

## Key Design Decisions

### 1. Open3.capture3 for Production Execution

**Why not system()?**
- system() returns boolean (true/false), loses stderr
- Open3.capture3 returns [stdout, stderr, status]
- status.exitstatus provides detailed error info

```ruby
# With Open3.capture3:
stdout, stderr, status = Open3.capture3(command)
# ✅ Can inspect stderr for error messages
# ✅ Can check status.exitstatus for specific codes
# ✅ Cleaner error reporting
```

### 2. Dependency Injection over Global Mock

**Why not global mock?**
- Global state: fragile test isolation
- Thread safety: conflicts between tests
- Cleanup burden: manual reset required

**Benefits of injection:**
- Each test owns its executor instance
- No global state pollution
- Automatic cleanup when test ends

### 3. Working Directory as Parameter

**Original**: nested Dir.chdir + system handling
```ruby
# Before
Dir.chdir(dest_path) do
  unless system(cmd)
    raise "Command failed..."
  end
end
```

**Refactored**: working_dir passed to executor
```ruby
# After - cleaner, testable
executor.execute(cmd, dest_path)

# Executor handles Dir.chdir internally
```

## Results & Impact

### Test Re-enablement

All 3 previously omitted tests now pass:

```
✓ clone_repo raises error when git clone fails
✓ clone_repo raises error when git checkout fails
✓ clone_with_submodules raises error when submodule init fails
```

### Coverage Improvement

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Line Coverage | 84.51% | 85.86% | +1.35% |
| Branch Coverage | 63.64% | 64.11% | +0.47% |
| Omitted Tests | 4 | 1 | -3 |

### Test Counts

- Main suite: 151 tests (no change)
- Device suite: 14 tests (no change)
- Total: 165 tests (no change, but 3 newly enabled)
- All passing: ✅

### Code Quality

- RuboCop violations: 0
- Test failures: 0
- Error handling coverage: ✅ Improved

## Usage Guide

### Production Code (lib/pra/)

No global mocking needed. Uses ProductionExecutor by default:

```ruby
# Just use Pra::Env methods normally
Pra::Env.clone_repo(url, dest, commit)  # Uses real Open3
Pra::Env.execute_with_esp_env(cmd, dir)
```

### Test Code

Inject MockExecutor for controlled testing:

```ruby
# Setup
mock = Pra::MockExecutor.new
original = Pra::Env.executor
Pra::Env.set_executor(mock)

# Configure results
mock.set_result("git clone ...", fail: true, stderr: "error")

# Run test
error = assert_raise(RuntimeError) { Pra::Env.clone_repo(...) }

# Cleanup
Pra::Env.set_executor(original)
```

## Next Phase (Phase 1)

Apply same pattern to device.rb and device_test.rb:

```ruby
# device.rb refactoring
def delegate_to_r2p2(task, env_name)
  executor = Pra::Env.executor  # Shared executor
  executor.execute("rake #{task}", r2p2_path)
end

# device_test.rb
mock = Pra::MockExecutor.new
Pra::Env.set_executor(mock)
Pra::Commands::Device.start(['flash', '--env', 'test'])
```

This will enable full device test integration without Thor interference.

## Files Modified

### New
- `lib/pra/executor.rb` - Executor abstraction (ProductionExecutor, MockExecutor)
- `test/pra/executor_test.rb` - Executor unit tests (11 tests)

### Modified
- `lib/pra/env.rb` - Refactored to use executor
- `test/commands/env_test.rb` - Re-enabled 3 git error handling tests
- `Rakefile` - Unified test execution (rake, rake test, rake test:all, rake ci)

## Testing

Run all tests to verify Phase 0:

```bash
rake ci           # 151 main + RuboCop + coverage
rake test:all     # 165 tests (151 + 14) with coverage
bundle exec ruby test/pra/executor_test.rb  # 11 Executor tests
```

## References

- Executor abstraction: lib/pra/executor.rb
- Pra::Env refactoring: lib/pra/env.rb (lines 46-57, 151-170, 307-309)
- Git tests: test/commands/env_test.rb (lines 1204-1310)
- Test helper: test/test_helper.rb
