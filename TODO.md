# TODO: Project Maintenance Tasks

## 🚀 Active Development

### Phase 0: Command Name Refactoring (ptrk → picotorokko)

**CRITICAL PRIORITY**: Complete migration of gem name from `pra` → `picotorokko` across 46 files

**Goal**: Align codebase and documentation with new naming convention (picotorokko / ptrk command)

#### Phase 0a: Module & Directory Refactoring

**Tasks** (TDD cycles: 1-5 minutes each):

1. Rename `lib/picotorokko/` directory to `lib/picotorokko/`
2. Update `module Pra` → `module Picotorokko` in all files
3. Update all `require "pra/..."` → `require "picotorokko/..."`
4. Update all test helper requires
5. Verify all 197 tests pass after refactoring

**Related Files**:
- lib/pra.rb
- lib/picotorokko/version.rb
- lib/picotorokko/cli.rb
- lib/picotorokko/env.rb
- lib/picotorokko/executor.rb
- lib/picotorokko/patch_applier.rb
- lib/picotorokko/commands/*.rb (env.rb, device.rb, mrbgems.rb, rubocop.rb)
- lib/picotorokko/template/*.rb (engine.rb)
- test/test_helper.rb
- exe/ptrk
- picoruby-application-on-r2p2-esp32-development-kit.gemspec

#### Phase 0b: Command Example Updates

**Tasks**:

1. Update SPEC.md: `ptrk env show` → `ptrk env show` (58 references)
2. Update `.picoruby-env.yml.example`: all command examples `pra` → `ptrk`
3. Update `CONTRIBUTING.md`: "Contributing to pra" → "Contributing to picotorokko"
4. Update `CHANGELOG.md`: Initial release message

**Related Files**:
- SPEC.md
- .picoruby-env.yml.example
- CONTRIBUTING.md
- CHANGELOG.md
- docs/RUBOCOP_PICORUBY_GUIDE.md
- docs/AST_TEMPLATE_ENGINE_SPEC.md

#### Phase 0c: Configuration & Tooling

**Tasks**:

1. Update `.rubocop.yml`: `lib/picotorokko/` → `lib/picotorokko/` in exclusion path
2. Update `.claude/settings.local.json`: `pra` → `ptrk` command references
3. Update `.github/workflows/release.yml`: version.rb path (ptrk → picotorokko)
4. Update test file names & requires (picotorokko_test.rb references)
5. Run full test suite and verify 0 violations, 197 tests passing

**Related Files**:
- .rubocop.yml
- .claude/settings.local.json
- .github/workflows/release.yml
- test/picotorokko_test.rb
- test/commands/mrbgems_test.rb

---

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

### ✅ Phase 0: Infrastructure & System Mocking (Session 6)

**Status**: ✅ **COMPLETE**

- Created Executor abstraction (ProductionExecutor, MockExecutor)
- Refactored Pra::Env to use dependency injection
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
- **RuboCop**: 0 violations (27 files)
- **Coverage**: 85.86% line, 64.11% branch (exceeds minimum thresholds)

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
