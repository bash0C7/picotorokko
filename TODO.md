# TODO: Project Maintenance Tasks

## ✅ [TODO-INFRASTRUCTURE-DEVICE-TEST-REGISTRATION] Device Test Integration Status

**Status**: ✅ **WORKAROUND COMPLETED** (Session 5, commits 57bf375 + e70d478)

### Problem
- device_test.rb breaks test-unit registration when loaded with other test files
- Root cause: Thor command execution interferes with test-unit's `at_exit` hooks
- Symptom: 54 tests registered instead of 140+

### Solution Implemented
**Workaround** (Rakefile modification - commit 57bf375):
- Exclude device_test.rb from main test suite
- Separate `test:device` task for device_test.rb only
- Integrated `test:all` task runs both sequentially

**Results**:
- `bundle exec rake test`: **140 tests** ✓ (device_test.rb excluded)
- `bundle exec rake test:device`: **14 tests** ✓ (device only)
- `bundle exec rake test:all`: **154 tests** ✓ (sequential execution)
- Coverage (main suite): **83.51%** ✓
- All tests pass: 0 failures, 0 errors ✓

### Known Limitations
- device_test.rb not integrated with main suite - requires separate task execution
- Not recommended for production workflows, only temporary solution

### Future Permanent Fix (Post-Feature-Implementation Priority)
**Recommended Approach**: Refactor device tests to avoid Thor direct execution
- Extract Thor command logic into internal methods
- Test internal methods directly (faster, better isolation)
- Eliminates Thor state corruption

---

### [TODO-INFRASTRUCTURE-SYSTEM-MOCKING-REFACTOR] ✅ COMPLETED - Phase 0 (Session 6)

**Status**: ✅ **COMPLETED** (commits d8c2c89, 4b3397c, 95f2caf)

**Problem Summary (Original)**:
- 3 system() mocking tests in env_test.rb failed due to Ruby Refinement limitations
- Refinement activated in env_test.rb didn't affect system() calls inside lib/pra/env.rb
- Real git commands executed instead of mocks, causing test failures

**Root Cause (Original)**:
- **Ruby Refinements are lexically scoped, not dynamically scoped**
- `using SystemCommandMocking::SystemRefinement` in env_test.rb only affected code **in that file**
- When env_test.rb calls `Pra::Env.clone_repo()`, which then calls `system()` in lib/pra/env.rb:
  - The `system()` call happened in lib/pra/env.rb's lexical scope
  - Refinement is NOT active in that scope
  - Real Kernel#system is called instead of mock

**Evidence**:
```bash
# Test output shows real git command execution:
Cloning https://github.com/test/repo.git to dest...
Cloning into 'dest'...
fatal: could not read Username for 'https://github.com': No such device or address

# Mock call count is 0 (mock never invoked):
<1> expected but was <0>
```

**Historical Context**:
- Commit 92b4475 introduced Refinement-based mocking but **never actually worked**
- NoMethodError: `undefined method 'using'` when trying to activate Refinement dynamically
- These tests have been broken since introduction

**Affected Tests** (3 tests omitted in commit 0393bea):
1. `test/commands/env_test.rb:1201` - "clone_repo raises error when git clone fails"
2. `test/commands/env_test.rb:1228` - "clone_repo raises error when git checkout fails"
3. `test/commands/env_test.rb:1256` - "clone_with_submodules raises error when submodule init fails"

**Current Workaround**:
- Tests omitted with detailed comment explaining Refinement limitation
- See: `test/commands/env_test.rb` lines 1202-1209, 1229-1231, 1257-1259

**Priority**: 🔧 **MEDIUM** - Impact:
1. Missing branch coverage for error handling paths in lib/pra/env.rb
2. Cannot verify system() error handling without production code refactoring
3. 3 tests permanently omitted until resolved

**Solution Implemented (Phase 0 - Session 6)**:

**Option A: Dependency Injection** ✅ **CHOSEN & COMPLETED**

Architecture:
```ruby
# lib/pra/executor.rb
module Pra
  module Executor
    def execute(command, working_dir = nil)
      # Returns [stdout, stderr]
      # Raises RuntimeError on non-zero exit (via Open3.capture3)
    end
  end

  class ProductionExecutor < Executor  # Uses Open3
  class MockExecutor < Executor        # For testing
end

# lib/pra/env.rb refactored:
def execute_with_esp_env(command, working_dir = nil)
  executor.execute(command, working_dir)
end
```

Implementation Details:
- ✅ **lib/pra/executor.rb**: ProductionExecutor (Open3.capture3) + MockExecutor
- ✅ **lib/pra/env.rb**: Dependency injection via `set_executor(executor)` / `executor` accessors
- ✅ **clone_repo / clone_with_submodules / execute_with_esp_env**: All refactored to use executor
- ✅ **No Dir.chdir boilerplate**: Working directory passed to executor.execute()
- ✅ **Error handling**: RuntimeError thrown on non-zero exit with detailed stderr

Test Re-enablement (env_test.rb):
- ✅ **Test 1**: "clone_repo raises error when git clone fails" - MockExecutor.set_result(fail: true)
- ✅ **Test 2**: "clone_repo raises error when git checkout fails" - Dual mock setup
- ✅ **Test 3**: "clone_with_submodules raises error when submodule init fails" - Triple mock setup

Results:
- ✅ 3 tests re-enabled (previously omitted)
- ✅ Branch coverage: 64.11% (was 63.64%, +0.47%)
- ✅ Line coverage: 85.86% (was 84.51%, +1.35%)
- ✅ All 151 tests passing, 0 failures, 0 errors
- ✅ RuboCop: 0 violations
- ✅ SimpleCov: Coverage validated

Benefits:
1. **Testability**: Clean dependency injection, zero global state pollution
2. **Maintainability**: Single point of control for command execution (executor)
3. **Clarity**: Reduced boilerplate (no nested Dir.chdir + system handling)
4. **Flexibility**: Easy to add command tracing, caching, or alternate backends

Phase 1 Next: Apply same pattern to device.rb + device_test.rb (with_esp_env_mocking → MockExecutor)

---

## 🔮 Post-Refactoring Enhancements

### AST-Based Template Engine ✅ APPROVED

**Status**: Approved for Implementation (Execute AFTER picotorokko refactoring)

**Full Specification**: [docs/PICOTOROKKO_REFACTORING_SPEC.md#template-strategy-ast-based-template-engine](docs/PICOTOROKKO_REFACTORING_SPEC.md#template-strategy-ast-based-template-engine)

**Overview**: Replace ERB-based template generation with AST-based approach (Parse → Modify → Dump)

**Key Components**:
- `Ptrk::Template::Engine` - Unified template interface
- `RubyTemplateEngine` - Prism-based (Visitor pattern)
- `YamlTemplateEngine` - Psych-based (recursive placeholder replacement)
- `CTemplateEngine` - String gsub-based

**Estimated Effort**: 8-12 days

**Priority**: High (approved, post-picotorokko)

---

## 🔬 Code Quality

### Test Coverage Targets (Low Priority)
- Current: 85.55% line, 64.85% branch (exceeds minimum thresholds)
- Ideal targets: 90% line, 70% branch
- Status: Optional enhancement, not required for release

---

## 📝 Current Status & Next Steps

**Completed Phases**:
- ✅ Phases 0-5: Foundation + device command refactoring
- ✅ Test infrastructure: 140 main tests + 14 device tests (154 total)
- ✅ Coverage: 85.55% line, 64.85% branch (exceeds thresholds)

**Current Test Status**:
- Main suite: `bundle exec rake test` → 140 tests
- Device suite: `bundle exec rake test:device` → 14 tests
- Combined: `bundle exec rake test:all` → 154 tests sequential

**Next Priority**:
1. Phase 6+ feature enhancements
2. Template engine migration (AST-based, post-feature)
3. Permanent device test refactoring (post-feature)
