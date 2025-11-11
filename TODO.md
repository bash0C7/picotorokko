# TODO: Project Maintenance Tasks

## 🚀 Active Development

### Phase 1: Device Integration (Executor Pattern Application)

**Goal**: Apply Executor pattern to device.rb and device_test.rb for unified test execution

**⚠️ Check for [TODO-INFRASTRUCTURE-DEVICE-TEST] markers before starting**

**Tasks**:
1. Refactor `lib/picotorokko/commands/device.rb` to use executor dependency injection
2. Update `test/commands/device_test.rb` to replace `with_esp_env_mocking` with MockExecutor
3. Integrate device_test.rb into main test suite
4. Verify all 197 tests pass with coverage ≥ 85% line / 60% branch

**Related Files**:
- lib/picotorokko/commands/device.rb
- test/commands/device_test.rb
- test/test_helper.rb

---

## [TODO-INFRASTRUCTURE-DEVICE-TEST]

**Consolidated marker** for device test framework infrastructure issues:

- **Context**: Thor help command breaks test-unit registration, requiring mock setup for system command testing
- **Affected Tests**:
  - test/commands/env_test.rb:919 (GIT-ERROR-HANDLING tests)
  - test/commands/env_test.rb:1197 (SYSTEM-MOCKING-TESTS)
  - test/commands/device_test.rb:10, 442 (DEVICE-TEST-FRAMEWORK)
- **Current Workaround**: device_test.rb excluded from main suite, integrated via test:all task
- **Permanent Fix**: Phase 1 will apply Executor pattern to remove mock helper dependencies
- **Reference**: test/test_helper.rb:22

---

## ✅ Completed & Archived

### ✅ Phase 0: Command Name Refactoring (pra → picotorokko) [Session 7]

**Status**: ✅ **COMPLETE**

Complete migration of gem name from `pra` → `picotorokko` across 46 files:

**Phase 0a: Module & Directory Refactoring**
- Renamed `lib/pra/` directory to `lib/picotorokko/`
- Updated `module Pra` → `module Picotorokko` in all files
- Updated all `require "pra/..."` → `require "picotorokko/..."`
- Updated version output to "picotorokko version"
- 183 tests passing ✓

**Phase 0b: Command Example Updates**
- Updated SPEC.md: 42 `pra` → `ptrk` references
- Updated `.picoruby-env.yml.example`: command examples
- Updated `CONTRIBUTING.md`: project name
- Updated `CHANGELOG.md`: initial release message
- Updated all docs/ files with `ptrk` references

**Phase 0c: Configuration & Tooling**
- Updated `.rubocop.yml`: path exclusions
- Updated `.claude/settings.local.json`: command references
- Updated `.github/workflows/release.yml`: version.rb paths
- Renamed `test/pra_test.rb` → `test/picotorokko_test.rb`
- All 197 tests passing (183 main + 14 device) ✓
- Coverage: 87.14% line, 65.37% branch ✓

### ✅ Phase 0 (Prior): Infrastructure & System Mocking (Session 6)

**Status**: ✅ **COMPLETE**

- Created Executor abstraction (ProductionExecutor, MockExecutor)
- Refactored Picotorokko::Env to use dependency injection
- Re-enabled 3 git error handling tests
- Coverage: 85.86% line, 64.11% branch
- Reference: docs/PHASE_0_EXECUTOR_ABSTRACTION.md

### ✅ AST-Based Template Engine (Previous Session)

**Status**: ✅ **COMPLETE**

- Implemented RubyTemplateEngine (Prism-based AST)
- Implemented YamlTemplateEngine (Psych-based)
- Implemented CTemplateEngine (String substitution)
- Reference: docs/AST_TEMPLATE_ENGINE_SPEC.md

### ✅ Device Test Infrastructure Workaround (Session 5)

**Status**: ✅ **WORKAROUND COMPLETE** (permanent fix deferred to Phase 1)

- Separated device_test.rb from main suite to prevent Thor interference
- Integrated via test:all and default rake task
- Maintained 14 device tests without breaking main suite

---

## 📚 Test Execution & Quality Summary

### Current Status

- **Main suite**: 183 tests ✓ (includes template engine tests)
- **Device suite**: 14 tests ✓
- **Total**: 197 tests (when running `rake` or `rake test:all`)
- **RuboCop**: 11 remaining violations (non-critical metrics: method length, cyclomatic complexity, naming conventions)
- **Coverage**: 87.14% line, 65.37% branch (exceeds minimum thresholds: 85% line, 60% branch)

### Execution Methods

- `rake` → runs all 197 tests (default)
- `rake test` → 183 main tests + template tests
- `rake test:all` → 197 tests with coverage validation
- `rake ci` → 183 main tests + RuboCop + coverage
- `bundle exec ruby test/path/file_test.rb` → individual file

---

## 🔗 Related Documentation

- `.claude/docs/git-safety.md` - Git development workflow
- `.claude/docs/tdd-rubocop-cycle.md` - TDD cycle guidelines
- `docs/PHASE_0_EXECUTOR_ABSTRACTION.md` - Phase 0 detailed spec
- `docs/AST_TEMPLATE_ENGINE_SPEC.md` - Template engine spec
- `CLAUDE.md` - Project instructions & development guide
