# TODO: Project Maintenance Tasks

## 🚀 Active Development

### Phase 1: Device Integration (Pending)

**Goal**: Apply Executor pattern to device.rb and device_test.rb for unified test execution

**Tasks**:
1. Refactor `lib/pra/commands/device.rb` to use executor dependency injection
2. Update `test/commands/device_test.rb` to replace `with_esp_env_mocking` with MockExecutor
3. Integrate device_test.rb into main test suite
4. Verify all 165 tests pass (151 main + 14 device)

**Related Files**:
- lib/pra/commands/device.rb
- test/commands/device_test.rb
- test/test_helper.rb (remove with_esp_env_mocking)

---

## 📋 Optional Enhancements

### Test Coverage Targets (Low Priority)

**Current**: 85.86% line, 64.11% branch (exceeds minimum thresholds)
**Ideal targets**: 90% line, 70% branch
**Status**: Optional, not required for release

**Potential coverage improvements**:
- Add tests for edge cases in Executor classes
- Expand device.rb error handling tests
- Test template engines with complex YAML structures

---

## ✅ Completed & Archived

### ✅ Phase 0: Infrastructure & System Mocking (Session 6)

**Completion Status**: ✅ **COMPLETE**

**What was done**:
- Created Executor abstraction (ProductionExecutor, MockExecutor)
- Refactored Pra::Env to use dependency injection
- Re-enabled 3 git error handling tests
- Unified test execution (rake, rake test, rake ci, rake test:all)
- Coverage: 85.86% line, 64.11% branch

**Key Commits**:
- d8c2c89: Add Executor abstraction with Open3
- 4b3397c: Refactor Env to use executor
- 95f2caf: Re-enable 3 git error handling tests
- 89ee6ae: Integrate device_test into default execution
- 0f1c543: Update docs for individual test files

**Documentation**:
- See: docs/PHASE_0_EXECUTOR_ABSTRACTION.md

---

### ✅ AST-Based Template Engine (Previous Session)

**Completion Status**: ✅ **COMPLETE** (merged from origin/main)

**What was done**:
- Implemented RubyTemplateEngine (Prism-based AST)
- Implemented YamlTemplateEngine (Psych-based)
- Implemented CTemplateEngine (String substitution)
- Full test coverage for all engines
- Integrated into mrbgems command

**Key Commits**:
- c411bd4: Integrate AST-Based Template Engine
- 55664bf: Test RubyTemplateEngine
- 9806bd7: Test YamlTemplateEngine and CTemplateEngine
- f95f036: Add AST-compatible templates for mrbgem

**Documentation**:
- See: docs/AST_TEMPLATE_ENGINE_SPEC.md

---

### ✅ Device Test Infrastructure Workaround (Session 5)

**Status**: ✅ **WORKAROUND COMPLETE** (permanent fix deferred to Phase 1)

**What was done**:
- Separated device_test.rb from main suite to prevent Thor interference
- Integrated via test:all and default rake task
- Maintained 14 device tests without breaking main suite

**Known Limitation**:
- device_test.rb excluded from main test suite (temporary)
- Permanent fix: Apply Executor pattern (scheduled for Phase 1)

---

## 📚 Test Execution Summary

### Current Status
- **Main suite**: 183 tests ✓ (includes template engine tests)
  - Core tests: 151
  - Template engine tests: 32
- **Device suite**: 14 tests ✓
- **Total**: 197 tests (when running `rake` or `rake test:all`)
- **Execution methods**:
  - `rake` → runs all 197 tests (default)
  - `rake test` → 183 main tests + template tests
  - `rake test:all` → 197 tests with coverage
  - `rake ci` → 183 main tests + RuboCop + coverage
  - `bundle exec ruby test/path/file_test.rb` → individual file

### Quality Gates
- ✅ RuboCop: 0 violations (27 files)
- ✅ Coverage: 85.86% line (from Phase 0), now tested with template engines
- ✅ Tests: 197 passing, 0 failures

---

## 🔗 Related Documentation

- `.claude/docs/git-safety.md` - Git development workflow
- `.claude/docs/tdd-rubocop-cycle.md` - TDD cycle guidelines
- `docs/PHASE_0_EXECUTOR_ABSTRACTION.md` - Phase 0 detailed spec
- `docs/AST_TEMPLATE_ENGINE_SPEC.md` - Template engine spec
- `CLAUDE.md` - Project instructions & development guide
