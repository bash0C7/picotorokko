# Executor Abstraction for System Command Testing

**Status**: Implemented (Session 6)
**Architecture**: Dependency injection with production/mock executors
**Reference**: [lib/picotorokko/executor.rb](../../lib/picotorokko/executor.rb), [lib/picotorokko/env.rb](../../lib/picotorokko/env.rb)

## Overview

The Executor Abstraction solves a critical testing infrastructure problem: system command mocking was broken due to Ruby Refinements' lexical scoping limitations. The solution implements a clean dependency injection pattern for command execution, enabling testable design and eliminating global state pollution.

## Problem Statement

### Ruby Refinements: Lexical Scope Limitation

Ruby Refinements are lexically scoped, not dynamically scoped. This creates a fundamental incompatibility with mocking patterns:

```ruby
# env_test.rb
using SystemCommandMocking::SystemRefinement
  ↓
Picotorokko::Env.clone_repo()
  ↓ (calls system() in lib/picotorokko/env.rb's lexical scope)
  ↓
❌ Refinement NOT active → real git commands execute

# Real output: Network error when trying to clone
# Expected: Mocked git command
```

### Impact

- Tests cannot mock system() calls that cross lexical boundaries
- 3 tests permanently omitted (error handling paths untested)
- Branch coverage incomplete and unable to improve without refactoring
- Cannot verify system() error handling behavior

## Solution: Dependency Injection with Executor Abstraction

### Architecture Diagram

```
┌──────────────────────────────────────┐
│  Test Code (env_test.rb)             │
│                                      │
│  mock = MockExecutor.new             │
│  Picotorokko::Env.set_executor(mock) │
│                                      │
│  mock.set_result("git clone url",    │
│       fail: true)                    │
│                                      │
│  # Now clone_repo() uses mock        │
└──────────────────────────────────────┘
           │
           ↓
┌──────────────────────────────────────┐
│  Picotorokko::Env                    │
│  lib/picotorokko/env.rb              │
│                                      │
│  def execute_with_esp_env(cmd, dir)  │
│    executor.execute(cmd, dir)        │
│  end                                 │
└──────────────────────────────────────┘
           │
           ↓
      ┌────┴──────┐
      │            │
      ↓            ↓
  ┌──────────┐  ┌───────────┐
  │ Prod     │  │ Test      │
  │Executor  │  │ Executor  │
  └──────────┘  └───────────┘
  Open3.       Mock
  capture3     calls
```

### Implementation Strategy

**Executor Module Interface**
- All implementations provide `execute(command, working_dir)`
- Returns: `[stdout, stderr]` on success
- Raises: `RuntimeError` on non-zero exit code

**ProductionExecutor**
- Uses `Open3.capture3` for real command execution
- Handles working directory context with `Dir.chdir`
- Provides full stdout/stderr and status information

**MockExecutor**
- Configurable per-test behavior via `set_result(command, stdout:, stderr:, fail:)`
- Tracks all invocations in `@calls` array
- Returns empty strings by default, or configured values on match

**Dependency Injection**
- `Picotorokko::Env.set_executor(executor)` injects test mock
- `Picotorokko::Env.executor` returns current executor (ProductionExecutor by default)
- No global state; each test owns its executor instance

## Key Design Decisions

### 1. Open3.capture3 vs. system()

**Why Open3.capture3?**

```ruby
# system() limitations
system("git clone ...")  # Returns: true/false only
# ❌ No stderr capture
# ❌ No exit status code
# ❌ Cannot distinguish error types

# Open3.capture3 advantages
stdout, stderr, status = Open3.capture3("git clone ...")
# ✅ Full stderr for error diagnostics
# ✅ status.exitstatus for detailed error codes
# ✅ Cleaner error reporting
# ✅ No STDOUT/STDERR redirection needed
```

### 2. Dependency Injection over Global Mock

**Why not global state?**

- **Test isolation**: Global mock affects all concurrent tests
- **Thread safety**: Conflicts when tests run in parallel
- **Cleanup burden**: Manual reset required in ensure blocks
- **Test independence**: One test's mock interferes with others

**DI benefits:**

- Each test creates its own executor instance
- No shared state between tests
- Automatic cleanup when test scope ends
- Explicit test intent (mock is local variable)

### 3. Working Directory as Parameter

**Original approach**: Nested Dir.chdir + system handling
```ruby
# Before: implicit context
Dir.chdir(dest_path) do
  unless system(cmd)
    raise "Command failed..."
  end
end
```

**Refactored**: working_dir passed to executor
```ruby
# After: explicit parameter
executor.execute(cmd, dest_path)

# Executor handles Dir.chdir internally
```

**Benefits:**
- Testable without side effects (no Dir.chdir in test)
- Clearer method signatures
- Easier to understand execution context

## Results & Impact

### Test Re-enablement

All 3 previously omitted git error handling tests now pass:

- `test/commands/env_test.rb`: clone_repo raises error when git clone fails ✓
- `test/commands/env_test.rb`: clone_repo raises error when git checkout fails ✓
- `test/commands/env_test.rb`: clone_with_submodules raises error when submodule init fails ✓

### Coverage Improvement

| Metric | Phase 0 | Current | Status |
|--------|---------|---------|--------|
| Line Coverage | 84.51% | 87.06% | +2.55% ✓ |
| Branch Coverage | 63.64% | 65.37% | +1.73% ✓ |
| Omitted Tests | 4 | 1 | -3 ✓ |
| Main Suite | 151 | 183 | +32 tests |
| Device Suite | 14 | 14 | stable |
| **Total Tests** | **165** | **197** | **+32 tests** |

### Code Quality

- RuboCop violations: 0
- Test failures: 0
- Error handling coverage: ✅ Fully improved
- All tests passing: ✅

## Usage Guide

### Production Code

No mocking needed. Uses ProductionExecutor by default:

```ruby
# lib/picotorokko/env.rb
Picotorokko::Env.clone_repo(url, dest, commit)
Picotorokko::Env.execute_with_esp_env(cmd, working_dir)
```

The executor is never visible in production code—it just works.

### Test Code

Inject MockExecutor for controlled testing:

```ruby
def test_error_handling
  # 1. Create mock
  mock_executor = Picotorokko::MockExecutor.new

  # 2. Configure failure case
  mock_executor.set_result(
    "git clone https://github.com/test/repo.git dest",
    fail: true,
    stderr: "fatal: could not read Username"
  )

  # 3. Inject mock (save original for cleanup)
  original_executor = Picotorokko::Env.executor
  Picotorokko::Env.set_executor(mock_executor)

  begin
    # 4. Run test
    error = assert_raise(RuntimeError) do
      Picotorokko::Env.clone_repo("https://github.com/test/repo.git", "dest", "abc1234")
    end

    # 5. Verify behavior
    assert_include error.message, "Command failed"
    assert_equal 1, mock_executor.calls.length

  ensure
    # 6. Cleanup (restore original executor)
    Picotorokko::Env.set_executor(original_executor)
  end
end
```

## Related Work

This pattern is foundational for Phase 1 (Device Integration), which applies the same executor abstraction to device.rb for testing device commands without Thor interference.

## Lessons Learned

### Ruby Refinements Are Not a Mocking Solution

Refinements are designed for DSL enhancement, not test mocking. Key lessons:

1. **Lexical scoping is mandatory** - Cannot be overridden
2. **Cross-boundary calls are problematic** - Refinement effects don't propagate
3. **DI is more flexible** - Works across any code boundary
4. **Explicit over implicit** - Dependency injection makes test intent clear

### When to Use Dependency Injection vs. Refinements

| Use Case | Refinement | DI |
|----------|-----------|-----|
| DSL enhancement (syntax) | ✅ Perfect | ❌ Overkill |
| Monkey patching (scoped) | ✅ Good | ✓ Also works |
| **Test mocking (isolation)** | ❌ **Breaks on lexical scope** | ✅ **Best choice** |
| Global behavior override | ❌ Limited | ✅ Simple |

For testing system commands, DI is always the right choice.

## References

- [lib/picotorokko/executor.rb](../../lib/picotorokko/executor.rb) - Executor implementation
- [lib/picotorokko/env.rb](../../lib/picotorokko/env.rb) - Dependency injection points
- [test/picotorokko/executor_test.rb](../../test/picotorokko/executor_test.rb) - Executor tests
- [test/commands/env_test.rb](../../test/commands/env_test.rb) - Git operation tests using MockExecutor
