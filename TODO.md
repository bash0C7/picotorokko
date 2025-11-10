# TODO: Project Maintenance Tasks

> **TODO Management Methodology**: See `.claude/skills/project-workflow/SKILL.md` and `CLAUDE.md` ## TODO Management section for task management rules and workflow.
>
> **⚠️ CRITICAL RULE: TDD-First TODO Structure**
> - Each task = one Red → Green → RuboCop -A → Refactor → Commit cycle (1-5 min)
> - [TODO-INFRASTRUCTURE-*] markers are NEVER to be skipped
> - When encountering [TODO-INFRASTRUCTURE-*], STOP and handle before proceeding
> - Phase start sections ALWAYS include: "⚠️ Check for [TODO-INFRASTRUCTURE-*] from previous phases"
> - Test failures detected during phase: Record with [TODO-INFRASTRUCTURE-*] marker
> - Test problems are resolved in TDD cycles, NOT batched at the end

---

## 🚀 Core: Major Refactoring - picotorokko (ptrk)

**Status**: Test Infrastructure First, Then Implementation

**Full Specification**: [docs/PICOTOROKKO_REFACTORING_SPEC.md](docs/PICOTOROKKO_REFACTORING_SPEC.md)

**Overview**:
- Gem name: `pra` → `picotorokko`
- Command: `pra` → `ptrk`
- Commands: 8 → 4 (env, device, mrbgem, rubocop)
- Directory: Consolidate into `ptrk_env/` (replaces `.cache/`, `build/`, `.picoruby-env.yml`)
- Env names: User-defined (no "current" symlink), defaults to `development`
- Breaking changes: Yes (but no users affected - unreleased gem)
- Estimated effort: 3-4 weeks, 7 phases (Test Infrastructure prioritized)

**Key Design Decisions**:
- ✅ Two distinct project roots: Gem development vs. ptrk user
- ✅ Environment name validation: `/^[a-z0-9_-]+$/`
- ✅ No implicit state (no `current` symlink)
- ✅ Tests use `Dir.mktmpdir` to keep gem root clean
- ✅ All quality gates must pass: Tests + RuboCop + Coverage
- ✅ **TDD-First approach**: Test infrastructure before any feature implementation

### Phase 0: Test Infrastructure ✅ COMPLETED (1 day - ahead of schedule!)

**Objective**: Establish solid test foundation for all downstream phases. Each task = Red → Green → RuboCop -A → Refactor → Commit.

**Strategy**: Fix infrastructure issues early so Phase 2-6 can focus on feature TDD without blocked tests.

**Completion Summary**:
- ✅ Phase 0.1: test_helper.rb PTRK_USER_ROOT setup
- ✅ Phase 0.2: SimpleCov exit code verification
- ✅ Phase 0.3: RuboCop integration verification
- ✅ Phase 0.4: Three-gate quality check (Tests 100%, RuboCop 0 violations, Coverage 85.24% line)
- ✅ Phase 0.5: Device command Thor analysis (Infrastructure marker documented)
- **Quality Metrics**: 144 tests, 323 assertions, 100% pass rate
- **Git Status**: Clean, 5 focused commits

#### 0.1: Update test/test_helper.rb for temp ptrk_user_root ✅ COMPLETED
- [x] **RED**: Write test expecting temp root (no gem root pollution)
  - Test file: `test/test_helper_test.rb` ✅
  - Assertion: `ENV['PTRK_USER_ROOT']` uses `Dir.mktmpdir` ✅
  - Assertion: `verify_gem_root_clean!` method exists ✅
- [x] **GREEN**: Implement in `test/test_helper.rb` ✅
  - Add `ENV['PTRK_USER_ROOT'] = Dir.mktmpdir` in setup ✅
  - Add `verify_gem_root_clean!` method ✅
- [x] **RUBOCOP**: `bundle exec rubocop -A test/test_helper_test.rb test/test_helper.rb` ✅
- [x] **REFACTOR**: Ensure clarity and simplicity ✅
- [x] **COMMIT**: "test: configure test_helper for isolated ptrk_user_root" (34a77ed) ✅

#### 0.2: Verify SimpleCov exit code behavior ✅ COMPLETED
- [x] **RED**: Write test expecting SimpleCov exit 0 on success
  - Test file: `test/coverage_test.rb` ✅
  - Verify SimpleCov XML report generated ✅
- [x] **GREEN**: SimpleCov config verified correct
  - SimpleCov exits with code 0 on success ✅
  - Coverage XML generated successfully ✅
- [x] **RUBOCOP**: `bundle exec rubocop -A` ✅
- [x] **REFACTOR**: Code is clean and simple ✅
- [x] **COMMIT**: "test: add SimpleCov exit code verification test" (a5343a0) ✅

#### 0.3: Verify RuboCop integration with tests ✅ COMPLETED
- [x] **RED**: Test RuboCop integration
  - Test: `bundle exec rubocop` succeeds with 0 violations ✅
- [x] **GREEN**: RuboCop integration verified
  - RuboCop: 0 violations across all files ✅
- [x] **RUBOCOP**: Check current state ✅
- [x] **REFACTOR**: N/A (RuboCop is the refactor tool) ✅
- [x] **COMMIT**: "test: add RuboCop integration verification test" (575d4ff) ✅

#### 0.4: Three-gate quality check (Tests + RuboCop + Coverage) ✅ COMPLETED
- [x] **RED**: Write integration test for three-gate quality
  - Test file: `test/quality_gates_test.rb` ✅
- [x] **GREEN**: All three gates verified passing
  - Tests: 144/144 (100%) ✅
  - RuboCop: 0 violations ✅
  - Coverage: 85.24% line, 65.2% branch ✅
- [x] **RUBOCOP**: `bundle exec rubocop -A` ✅
- [x] **REFACTOR**: N/A ✅
- [x] **COMMIT**: "test: add three-gate quality verification test" (c5a0785) ✅

#### 0.5: Device command Thor argument handling investigation
- [x] **ANALYSIS**: Understand Thor issue without fixing yet
  - Read: `test/commands/device_test.rb` (currently excluded from Rakefile)
  - Understand: Why Thor treats env names as subcommands
  - Record: Exact error behavior, root cause

**ANALYSIS RESULT (Phase 0.5 Completed)**:

**Problem**: 複数のテストが `return # Skipped: test-env argument breaks SimpleCov exit code detection` で skip されている

**Root Cause - Thor Subcommand Interpretation**:
```ruby
# Test attempts to call:
Pra::Commands::Device.start(['flash', 'test-env'])

# But Thor interprets 'test-env' as a SUBCOMMAND, not an argument
# Thor looks for a 'test-env' subcommand in the Device class
# When not found: raises SystemExit(1) with "Could not find command test-env"
# This leaves $ERROR_INFO set globally, corrupting SimpleCov exit code detection
```

**Affected Tests** (test/commands/device_test.rb):
- Line 46-50: "raises error when build environment not found"
- Line 78-82: "shows message when flashing"
- Line 147-151: "shows message when monitoring"
- Line 198-202: "shows message when building"
- Line 250-253: "shows message when setting up ESP32"
- Line 347-352: "delegates custom_task to R2P2-ESP32 rake task"
- Line 407-412: "uses default env_name when not provided"

**Current Workaround**: Tests call `return` early to avoid SystemExit

**Solution** (Deferred to Phase 5):
- Refactor device command to use explicit `--env` flag
- Change: `Device.start(['flash', 'test-env'])` → `Device.start(['flash', '--env', 'test-env'])`
- This prevents Thor from interpreting env_name as a subcommand

- [x] **MARK**: [TODO-INFRASTRUCTURE-DEVICE-COMMAND]
  - **Status**: Documented for Phase 5 (device command refactor to `--env` flag)
  - **Reference**:
    - Test file: `test/commands/device_test.rb` (lines 46-50, 78-82, 147-151, 198-202, 250-253, 347-352, 407-412)
    - Implementation: `lib/ptrk/commands/device.rb` (requires `--env` option refactor)
    - Configuration: Rakefile currently excludes device_test.rb from test suite
  - **Not blocking**: Phase 2-4 proceed with other commands; device is Phase 5 focus
  - **Dependency**: Phase 5.1 must fix this before re-enabling device_test.rb

---

### Phase 1: Planning & Documentation ✅ COMPLETED
- [x] Analyze current command structure
- [x] Investigate naming options
- [x] Create detailed refactoring specification
- [x] Update TODO.md with phased breakdown

---

### Phase 2: Rename & Constants ✅ COMPLETED (1 day - on schedule!)

**Status**: All three subphases completed with full test coverage

**Completion Summary**:
- ✅ Phase 2.1: Rename gemspec and bin/ptrk
- ✅ Phase 2.2: Add Pra::Env constants (ENV_DIR, ENV_NAME_PATTERN)
- ✅ Phase 2.3: Update CLI command registration (removed cache, build, patch, ci)
- **Quality Metrics**: 153 tests, 345 assertions, 100% pass rate, 0 RuboCop violations, 85.12% coverage
- **Git Status**: Clean, 3 focused commits

#### 2.1: Rename gemspec and bin/ptrk ✅ COMPLETED
- [x] **RED**: Created test for executable name in gemspec (test/gemspec_test.rb)
- [x] **GREEN**: Updated gemspec with spec.name = "picotorokko", renamed exe/pra → exe/ptrk
- [x] **RUBOCOP**: RuboCop auto-correct passed (0 violations)
- [x] **COMMIT**: "chore: rename executable pra → ptrk in gemspec" (0c4802d)

#### 2.2: Update lib/ptrk/env.rb constants ✅ COMPLETED
- [x] **RED**: Created test for new constants (test/lib/env_constants_test.rb)
  - Assertion: Pra::Env::ENV_DIR == "ptrk_env" ✅
  - Assertion: Pra::Env::ENV_NAME_PATTERN matches /^[a-z0-9_-]+$/ ✅
- [x] **GREEN**: Added constants to lib/pra/env.rb
  - ENV_DIR = "ptrk_env".freeze ✅
  - ENV_NAME_PATTERN = /^[a-z0-9_-]+$/ ✅
  - [TODO-INFRASTRUCTURE-ENV-PATHS] - Deferred to Phase 4 as noted
- [x] **RUBOCOP**: RuboCop auto-correct applied .freeze (1 violation corrected)
- [x] **COMMIT**: "refactor: add constants for ptrk env directory" (02263a8)

#### 2.3: Update lib/ptrk/cli.rb command registration ✅ COMPLETED
- [x] **RED**: Created test for CLI command registration (test/commands/cli_test.rb)
  - Assertions: env, device, mrbgems, rubocop commands registered ✅
  - Assertions: cache, build, patch, ci commands NOT registered ✅
- [x] **GREEN**: Updated lib/pra/cli.rb
  - Removed CLI registration for: cache, build, patch, ci
  - Kept registered: env, device, mrbgems, rubocop ✅
- [x] **RUBOCOP**: RuboCop auto-correct passed (0 violations)
- [x] **COMMIT**: "refactor: update cli.rb for new command structure" (4cd1106)

---

### Phase 3: Command Structure - TDD Approach (5-6 days)

**⚠️ Start**: Check for [TODO-INFRASTRUCTURE-*] markers from Phase 2.
  - If [TODO-INFRASTRUCTURE-ENV-PATHS] found: Defer path logic to Phase 4, proceed with command structure.
  - If [TODO-INFRASTRUCTURE-*] blocking test: Resolve immediately in TDD cycle.

**Strategy**: Each command = Red (test) → Green (impl) → RuboCop -A → Refactor → Commit

#### 3.1: env list command (Red → Green → RuboCop → Commit) ✅ COMPLETED
- [x] **RED**: Write test for `ptrk env list`
  - Test file: `test/commands/env_test.rb` ✅
  - Assertion: Lists all environments in ptrk_user_root ✅
  - Assertion: Shows env name, path, status ✅
- [x] **GREEN**: Implement in `lib/ptrk/commands/env.rb` ✅
  - Add `list` method with output formatting ✅
- [x] **RUBOCOP**: `bundle exec rubocop -A` ✅
- [x] **REFACTOR**: Ensure clean output logic ✅
- [x] **COMMIT**: "feat: implement ptrk env list command" (597e52e) ✅

#### 3.2: env set command with options (Red → Green → RuboCop → Commit) ✅ COMPLETED
- [x] **RED**: Test `ptrk env set <name> [--commit <sha>] [--branch <name>]` ✅
  - Assertion: Creates environment with options ✅
  - Assertion: Stores commit/branch if provided ✅
  - Assertion: Validates env name against pattern ✅
- [x] **GREEN**: Implement in `lib/ptrk/commands/env.rb` ✅
  - Add `set` method with option parsing ✅
  - Support both create and switch modes ✅
- [x] **RUBOCOP**: `bundle exec rubocop -A` ✅ (1 auto-correction: unless modifier)
- [x] **REFACTOR**: Simplify logic ✅
- [x] **COMMIT**: "feat: enhance ptrk env set with --commit and --branch options" (d731858) ✅

#### 3.3: env reset command (Red → Green → RuboCop → Commit) ✅ COMPLETED
- [x] **RED**: Test `ptrk env reset <name>` ✅
  - Assertion: Removes and recreates environment ✅
  - Assertion: Preserves metadata (notes) ✅
- [x] **GREEN**: Implement in `lib/ptrk/commands/env.rb` ✅
  - Add `reset` method ✅
- [x] **RUBOCOP**: `bundle exec rubocop -A` ✅
- [x] **REFACTOR**: N/A ✅
- [x] **COMMIT**: "feat: implement ptrk env reset command" (68e6226) ✅

#### 3.4: env show command (Red → Green → RuboCop → Commit) ✅ COMPLETED
- [x] **RED**: Test `ptrk env show [ENV_NAME]` ✅
  - Assertion: Displays specific environment details ✅
  - Assertion: Works with user-provided env names ✅
  - Assertion: Shows error for missing environments ✅
- [x] **GREEN**: Implement enhancement in `lib/ptrk/commands/env.rb` ✅
  - Update `show` to accept optional env name parameter ✅
  - Extract display logic into helper methods ✅
- [x] **RUBOCOP**: `bundle exec rubocop -A` ✅ (0 violations after refactoring)
- [x] **REFACTOR**: Extract helper methods to reduce nesting ✅
- [x] **COMMIT**: "feat: enhance ptrk env show to accept optional environment name" (d7478c0) ✅

**Phase 3.1-3.4 Status**: 4 commits (597e52e, d731858, 68e6226, d7478c0) successfully pushed to origin/claude/execute-todo-items-011CUynGmL5qMprB2AGpc5Jc and merged into main

#### 3.5: env patch operations (Red → Green → RuboCop → Commit) ✅ COMPLETED
- [x] **RED**: Test `ptrk env patch_export`, `patch_apply`, `patch_diff` ✅
  - Assertion: Commands accept env name parameter ✅
  - Assertion: Proper output for patches ✅
  - Test file: `test/commands/env_test.rb` (3 tests added) ✅
- [x] **GREEN**: Move patch operations from deleted commands into `env.rb` ✅
  - Implement: `patch_export`, `patch_apply`, `patch_diff` as env subcommands ✅
  - Add private helper methods: `resolve_work_path`, `export_repo_changes`, `show_repo_diff` ✅
  - Add require for `pra/patch_applier` ✅
- [x] **RUBOCOP**: `bundle exec rubocop -A` ✅ (1 auto-correction)
- [x] **REFACTOR**: N/A ✅
- [x] **COMMIT**: "feat: move patch operations to env command" (766b95d) ✅

#### 3.6: Delete obsolete commands and update device (Red → Green → RuboCop → Commit) ✅ COMPLETED
- [x] **RED**: Test that deleted commands don't exist ✅
  - Assertion: `cache`, `build`, `patch`, `ci` commands not available ✅
  - Test already existed in `test/commands/cli_test.rb` from Phase 2.3 ✅
- [x] **GREEN**: Delete files ✅
  - Delete: `lib/pra/commands/cache.rb` ✅
  - Delete: `lib/pra/commands/build.rb` ✅
  - Delete: `lib/pra/commands/patch.rb` ✅
  - Delete: `lib/pra/commands/ci.rb` ✅
  - Update: `lib/pra/cli.rb` to remove requires for deleted commands ✅
  - Delete: Corresponding test files (cache_test.rb, build_test.rb, patch_test.rb, ci_test.rb) ✅
  - Update: `lib/ptrk/commands/device.rb` - deferred to Phase 5 ✅
    - [TODO-INFRASTRUCTURE-DEVICE-COMMAND] from Phase 0: Thor --env flag refactor deferred to Phase 5
- [x] **RUBOCOP**: `bundle exec rubocop -A` ✅ (0 violations)
- [x] **REFACTOR**: N/A ✅
- [x] **COMMIT**: "refactor: remove cache, build, patch, ci commands; update cli" (c7b4acc) ✅
- [x] **Quality**: 113 tests, 233 assertions, 100% passed; deleted 2485 lines ✅

**Phase 3.5-3.6 Status**: 2 commits (766b95d, c7b4acc) successfully pushed to origin/claude/ruby-todo-implementation-011CUyovXEg8UEuSzPcTPsMS

---

### Phase 4: Directory Structure - TDD Approach (3-4 days)

**⚠️ CRITICAL POLICY: No Backward Compatibility Required**
- This is an **unreleased gem** (version 0.x) with **zero users**
- Breaking changes are **fully acceptable** and **encouraged** for cleaner design
- Do NOT add compatibility layers, deprecated constants, or migration paths
- Remove old logic completely and update all references immediately
- Focus on the final, clean design without compromise

**⚠️ Start**: Check for [TODO-INFRASTRUCTURE-*] markers from Phase 3.
  - [TODO-INFRASTRUCTURE-ENV-PATHS]: Verify env directory structure
  - [TODO-INFRASTRUCTURE-ENV-SET-PATHS]: Verify env set creates correct structure
  - Address any test failures in TDD cycle before proceeding.

**Strategy**: Each directory refactor = Red (test) → Green (impl) → RuboCop -A → Refactor → Commit

#### 4.1: Implement ptrk_env/ consolidated directory structure (Red → Green → RuboCop → Commit)
- [ ] **RED**: Test directory paths use ptrk_env/ prefix
  - Test: Cache path is `ptrk_env/.cache`
  - Test: Env path is `ptrk_env/{env_name}`
  - Test: Config path is `ptrk_env/.picoruby-env.yml`
  - Test: No `current` symlink exists or is created
- [ ] **GREEN**: Update `lib/ptrk/env.rb` path logic
  - Replace: `.cache/` → `ptrk_env/.cache/`
  - Replace: `build/` → `ptrk_env/{env_name}/`
  - Replace: `.picoruby-env.yml` → `ptrk_env/.picoruby-env.yml`
  - Remove: All `current` symlink logic
  - Remove: `current_env` methods (use explicit env_name)
- [ ] **RUBOCOP**: `bundle exec rubocop -A lib/ptrk/env.rb test/lib/env_test.rb`
- [ ] **REFACTOR**: Simplify path construction
- [ ] **COMMIT**: "refactor: consolidate paths into ptrk_env/ directory"

#### 4.2: Environment name validation in all commands (Red → Green → RuboCop → Commit)
- [ ] **RED**: Test all commands validate env names
  - Test: `env set` rejects invalid names (not matching `/^[a-z0-9_-]+$/`)
  - Test: `env list` shows only valid env directories
  - Test: Device command validates env name before use
- [ ] **GREEN**: Add validation to `lib/ptrk/env.rb` and all command files
  - Implement: `validate_env_name!(name)` method
  - Call: In env set, reset, show, device commands
  - Return: Error message on invalid names
- [ ] **RUBOCOP**: `bundle exec rubocop -A`
- [ ] **REFACTOR**: Extract validation into helper method
- [ ] **COMMIT**: "feat: add env name validation across commands"

#### 4.3: Verify all Phase 4 changes pass quality gates (Red → Green → RuboCop → Commit)
- [ ] **RED**: Write integration test for directory structure
  - Test: `bundle exec rake test` all pass with Phase 4 changes
  - Test: `bundle exec rubocop` 0 violations
  - Test: Coverage ≥ 80% line, ≥ 50% branch
- [ ] **GREEN**: Run test suite
  - `bundle exec rake test` → all passing
  - `bundle exec rubocop` → 0 violations
  - SimpleCov report → acceptable coverage
- [ ] **RUBOCOP**: Final check
- [ ] **REFACTOR**: N/A
- [ ] **COMMIT**: "test: verify Phase 4 directory structure changes"

---

### Phase 5: Device Command Thor Fix & Test Completion - TDD Approach (2-3 days)

**⚠️ START - CRITICAL CHECKS**:
  - [TODO-INFRASTRUCTURE-DEVICE-COMMAND]: Device command requires `--env` flag refactor
  - [TODO-INFRASTRUCTURE-SIMPLECOV-DETAILS]: Verify SimpleCov still exits 0
  - Address all [TODO-INFRASTRUCTURE-*] markers immediately before proceeding.

**Strategy**: Each fix = Red (test) → Green (impl) → RuboCop -A → Refactor → Commit

#### 5.1: Refactor device command to explicit --env flag (Red → Green → RuboCop → Commit)
- [ ] **RED**: Write test for device command with `--env` option
  - Test file: `test/commands/device_test.rb` (re-enable)
  - Assertion: `ptrk device flash --env staging` works
  - Assertion: Thor doesn't interpret env name as subcommand
  - Assertion: Explicit `--env` flag is required
- [ ] **GREEN**: Refactor `lib/ptrk/commands/device.rb`
  - Add: `--env ENV_NAME` option to all device subcommands
  - Remove: Logic that treats env names as positional arguments
  - Update: All flash, monitor, build subcommands to use `--env`
- [ ] **RUBOCOP**: `bundle exec rubocop -A`
- [ ] **REFACTOR**: Simplify command structure
- [ ] **COMMIT**: "refactor: device command uses explicit --env flag"

#### 5.2: Re-enable and verify device tests (Red → Green → RuboCop → Commit)
- [ ] **RED**: Verify `test/commands/device_test.rb` tests pass
  - Re-enable: Remove exclusion from Rakefile
  - Test: All device command variants work with `--env`
- [ ] **GREEN**: Run test suite
  - `bundle exec rake test` → all pass including device_test.rb
  - Verify coverage for device commands
- [ ] **RUBOCOP**: `bundle exec rubocop -A test/commands/device_test.rb`
- [ ] **REFACTOR**: N/A
- [ ] **COMMIT**: "test: re-enable device command tests"

#### 5.3: Final quality gate check (Red → Green → RuboCop → Commit)
- [ ] **RED**: Verify all three gates pass
  - Tests, RuboCop, Coverage all pass together
- [ ] **GREEN**: Run full suite
  - `bundle exec rake test` → exit 0, all pass
  - `bundle exec rubocop` → 0 violations
  - Coverage ≥ 80% line, ≥ 50% branch
- [ ] **RUBOCOP**: N/A
- [ ] **REFACTOR**: N/A
- [ ] **COMMIT**: "test: final quality gate verification after device fix"

---

### Phase 6: Documentation & Finalization - TDD Approach (3-4 days)

**⚠️ Start**: Verify all [TODO-INFRASTRUCTURE-*] resolved in Phase 0-5.

**Strategy**: Update documentation in small, testable chunks.

#### 6.1: Update README.md (Red → Green → RuboCop → Commit)
- [ ] **RED**: Test README examples work
  - Assertion: All `pra` → `ptrk` renamed
  - Assertion: Installation section uses `picotorokko`
  - Assertion: Command examples show new 4-command structure
- [ ] **GREEN**: Update README.md
  - Replace: All `pra` → `ptrk`
  - Update: Installation instructions
  - Update: Command examples for env, device, mrbgem, rubocop
  - Remove: References to cache, build, patch commands
- [ ] **RUBOCOP**: `bundle exec rubocop -A README.md` (if applicable)
- [ ] **REFACTOR**: Ensure clarity and correctness
- [ ] **COMMIT**: "docs: update README for picotorokko refactoring"

#### 6.2: Update configuration files (Red → Green → RuboCop → Commit)
- [ ] **RED**: Test `.gitignore` and config updated
  - Assertion: `ptrk_env/` is ignored
  - Assertion: Old `.cache/`, `build/` entries removed or updated
- [ ] **GREEN**: Update files
  - `.gitignore`: Add `ptrk_env/` entries, remove old entries
  - `CLAUDE.md`: Update project instructions with new structure
- [ ] **RUBOCOP**: Check files
- [ ] **REFACTOR**: Simplify if needed
- [ ] **COMMIT**: "chore: update .gitignore and configuration"

#### 6.3: Update documentation files (Red → Green → RuboCop → Commit)
- [ ] **RED**: Test docs reflect new structure
  - Assertion: All docs in `docs/` reference new commands
  - Assertion: No references to removed commands
- [ ] **GREEN**: Update `docs/` files
  - Update: `docs/CI_CD_GUIDE.md` (examples, references)
  - Update: `docs/*.md` (all command documentation)
  - Remove: If any docs for cache, build, patch commands
- [ ] **RUBOCOP**: Check Markdown style
- [ ] **REFACTOR**: Ensure consistency
- [ ] **COMMIT**: "docs: update documentation for new command structure"

#### 6.4: Add CHANGELOG and final verification (Red → Green → RuboCop → Commit)
- [ ] **RED**: Test CHANGELOG entry and final build
  - Assertion: CHANGELOG documents breaking changes
  - Assertion: Final `bundle exec rake ci` passes
- [ ] **GREEN**: Create and verify
  - Add: CHANGELOG entry for picotorokko v1.0
    - Summarize: Renamed gem, commands, directory structure
    - List: Breaking changes (command names, env structure)
  - Run: `bundle exec rake ci` (full test + RuboCop + coverage)
- [ ] **RUBOCOP**: N/A (rake ci includes rubocop)
- [ ] **REFACTOR**: N/A
- [ ] **COMMIT**: "docs: add CHANGELOG for picotorokko refactoring"

---

### Final Quality Verification (1 day)
- [ ] `bundle exec rake test` - All tests pass (exit 0)
- [ ] `bundle exec rubocop` - 0 violations (exit 0)
- [ ] `bundle exec rake ci` - All gates pass (exit 0)
- [ ] SimpleCov coverage report - ≥ 80% line, ≥ 50% branch
- [ ] No files in gem root (only ptrk_user_root used in tests)
- [ ] All commits have clear, descriptive messages
- [ ] No [TODO-INFRASTRUCTURE-*] markers remain unresolved
- [ ] **FINAL COMMIT**: "refactor: complete picotorokko refactoring (v1.0)"

---

## 🔮 Post-Refactoring Enhancements

### AST-Based Template Engine ✅ APPROVED

**Status**: Approved for Implementation (Execute AFTER picotorokko refactoring)

**Full Specification**: [docs/PICOTOROKKO_REFACTORING_SPEC.md#template-strategy-ast-based-template-engine](docs/PICOTOROKKO_REFACTORING_SPEC.md#template-strategy-ast-based-template-engine)

**Overview**: Replace ERB-based template generation with AST-based approach (Parse → Modify → Dump)

**Key Decisions**:
- ✅ Ruby templates: Placeholder Constants (e.g., `TEMPLATE_CLASS_NAME`)
- ✅ YAML templates: Special placeholder keys (e.g., `__PTRK_TEMPLATE_*__`), comments NOT preserved
- ✅ C templates: String replacement (e.g., `TEMPLATE_C_PREFIX`)
- ✅ ERB removal: Complete migration, no hybrid period
- ✅ **Critical requirement**: All templates MUST be valid code before substitution

**Key Components**:
- `Ptrk::Template::Engine` - Unified template interface
- `RubyTemplateEngine` - Prism-based (Visitor pattern for ConstantReadNode)
- `YamlTemplateEngine` - Psych-based (recursive placeholder replacement)
- `CTemplateEngine` - String gsub-based (simple identifier substitution)

**Migration Phases**:
1. PoC (2-3 days): ONE template + validation
2. Complete Rollout (3-5 days): ALL templates converted
3. ERB Removal (1 day): Delete .erb files

**Web Search Required** (before implementation):
- Prism unparse/format capabilities
- Prism location offset API verification
- RuboCop autocorrect patterns for learning

**Estimated Effort**: 8-12 days

**Priority**: High (approved, post-picotorokko)

### Future Enhancements (Phase 5+)

For detailed implementation guide and architecture design of the PicoRuby RuboCop Custom Cop, see [docs/RUBOCOP_PICORUBY_GUIDE.md](docs/RUBOCOP_PICORUBY_GUIDE.md).

