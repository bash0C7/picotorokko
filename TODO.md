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

### Phase 0: Test Infrastructure ✅ COMPLETED

**Objective**: Establish solid test foundation for all downstream phases.

**Completion Summary**:
- ✅ test_helper.rb PTRK_USER_ROOT setup
- ✅ SimpleCov exit code verification
- ✅ RuboCop integration verification
- ✅ Three-gate quality check (Tests 100%, RuboCop 0 violations, Coverage 85.24% line)
- ✅ Device command Thor analysis and infrastructure marker [TODO-INFRASTRUCTURE-DEVICE-COMMAND] documented
- **Final Metrics**: 144 tests, 323 assertions, 100% pass rate

**Deferred Issues**:
- [TODO-INFRASTRUCTURE-DEVICE-COMMAND]: Device command requires `--env` flag refactor (Phase 5)
  - Device tests excluded from Rakefile until Phase 5.1

---

### Phase 1: Planning & Documentation ✅ COMPLETED
- ✅ Analyzed current command structure and naming options
- ✅ Created detailed refactoring specification (docs/PICOTOROKKO_REFACTORING_SPEC.md)
- ✅ Updated TODO.md with phased breakdown

---

### Phase 2: Rename & Constants ✅ COMPLETED

**Completion Summary**:
- ✅ Renamed gemspec and exe/ptrk
- ✅ Added Pra::Env constants (ENV_DIR, ENV_NAME_PATTERN)
- ✅ Updated CLI command registration (removed cache, build, patch, ci)
- **Final Metrics**: 153 tests, 345 assertions, 100% pass rate, 85.12% coverage

---

### Phase 3: Command Structure ✅ COMPLETED

**Completion Summary**:
- ✅ Implemented env list, set, reset, show commands
- ✅ Moved patch operations into env command (patch_export, patch_apply, patch_diff)
- ✅ Deleted obsolete commands (cache, build, patch, ci)
- **Final Metrics**: 113 tests, 233 assertions, 100% pass rate, deleted 2485 lines

---

### Phase 4: Directory Structure & Bug Fixes ✅ COMPLETED

**Completion Summary**:
- ✅ 4.1: Consolidated `ptrk_env/` directory structure (replaced `.cache/`, `build/`, `.picoruby-env.yml`)
- ✅ 4.2: Environment name validation (`/^[a-z0-9_-]+$/`)
- ✅ 4.3: Quality gate verification (integrated tests)
- ✅ 4.4-4.6: Fixed 3 critical git operation bugs (get_timestamp, get_commit_hash, traverse_submodules)
- **Final Metrics**: 139 tests, 277 assertions, 100% pass, 1 omission, 84.86% line coverage, 61.11% branch coverage
- **Achievement**: Reached 84.86% line coverage (target 85%, only 0.14% away!)

---

### Phase 4.7: Fix System Command Mocking for CI Compatibility ⚠️ HIGHEST PRIORITY

**Status**: CRITICAL - Blocks Phase 5 (omitted 3 tests in env_test.rb)

**Problem**: [TODO-INFRASTRUCTURE-SYSTEM-MOCKING-TESTS]
- 3 tests omitted due to `Kernel.method(:system)` mocking failing in CI
- Local tests pass (mocking works), but CI fails (environment-dependent behavior)
- Affects: `clone_repo`, `clone_with_submodules` error path coverage

**Omitted Tests** (test/commands/env_test.rb):
1. `clone_repo raises error when git clone fails` (line 1196)
2. `clone_repo raises error when git checkout fails` (line 1204)
3. `clone_with_submodules raises error when submodule init fails` (line 1214)

**Root Cause**:
- Direct Kernel method override: `Kernel.define_singleton_method(:system)`
- Works in local Ruby env, fails in CI runner (sandboxing, different Ruby version, etc.)
- No dependency injection: system() calls are tightly coupled to implementation

**Solution Approaches** (try in order):

#### 4.7.1: Use Ruby Refinement (Recommended - Cleanest)
```ruby
# test/commands/env_test.rb
module MockSystem
  refine Kernel do
    def system(*args)
      # return false if cmd.include?('git clone')
      # original behavior
    end
  end
end

class TestClass
  using MockSystem
  # system() calls use refined version
end
```
**Pros**: Scoped, safe, no global state
**Cons**: Requires Ruby 2.1+, slightly verbose

#### 4.7.2: Use test::unit Mock/Stub (if available)
```ruby
# Check if test::unit has built-in mocking
require 'test/unit/mock'
mock_system = Test::Unit::Mock.new(Kernel, :system)
mock_system.expect(:system, false, ['git clone ...'])
```
**Pros**: Standard library, simple
**Cons**: Compatibility varies, may need adapter

#### 4.7.3: Refactor clone_repo for Dependency Injection (Best Practice)
```ruby
# lib/pra/env.rb - add system executor parameter
def clone_repo(repo_url, dest_path, commit, system_executor: method(:system))
  # system_executor.call("git clone ...")
end

# test - inject mock
class MockSystem
  def call(cmd)
    return false if cmd.include?('git clone')
    true
  end
end

Pra::Env.clone_repo(url, dest, commit, system_executor: MockSystem.new)
```
**Pros**: Testable, no mocking required, follows dependency injection
**Cons**: Requires implementation changes (but permitted for this case)

**Recommended Implementation**:
1. **Try Refinement first** (4.7.1) - No implementation changes needed
2. **Fallback to Dependency Injection** (4.7.3) - If Refinement not available
3. **Last resort**: Skip testing error paths, accept CI limitation

**Acceptance Criteria**:
- ✅ All 3 omitted tests pass in both local AND CI
- ✅ No `omit()` statements remain in system mocking tests
- ✅ Branch coverage increased (target: 65%+)
- ✅ RuboCop: 0 violations
- ✅ No circular dependencies introduced

**Estimated Effort**: 2-3 hours (1-2 hour implementation + testing)

**Priority**: 🚨 **HIGHEST** - Unblock Phase 5, improve CI reliability

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

---

## 🔬 Code Quality: Test Coverage Improvement (Low Priority)

**Current Status**: Phase 4.1完了時点
- Line Coverage: 80.61% (474 / 588)
- Branch Coverage: 57.98% (109 / 188)
- CI Threshold: line 75%, branch 55% ✅ (達成)

**Target Goals** (低優先度):
- Line Coverage: **85%** (目標 +4.4%, 約26行)
- Branch Coverage: **65%** (目標 +7%, 約13分岐)

**未カバー領域の特定** (Phase 4.1時点):
1. **lib/pra/env.rb** (64.81% → 要改善)
   - `get_timestamp`: Git timestamp取得（テスト環境でgitコミット作成が不安定）
   - `traverse_submodules_and_validate`: 3段階サブモジュールトラバース
   - `get_commit_hash`: コミット情報から hash形式生成（未使用の可能性）
   - `clone_with_submodules`: サブモジュール初期化エラーハンドリング

2. **lib/pra/commands/device.rb** (55.48% → Phase 5で対応予定)
   - device_test.rbが除外されているため（Thor引数処理問題）
   - Phase 5.1で`--env`フラグリファクタリング後にテスト再有効化

**実装アプローチ** (TDD cycle):
1. **RED**: 未カバー箇所のテストを作成
   - Git操作のモック化改善（`get_timestamp`, `traverse_submodules_and_validate`）
   - エラーケースの網羅（`clone_with_submodules`失敗シナリオ）
   - 条件分岐の全パターンテスト（branch coverage向上）

2. **GREEN**: 既存実装を変更せずテストをパス
   - テスト環境でのgit操作安定化
   - スタブ/モックの適切な設計

3. **RUBOCOP**: `bundle exec rubocop -A`

4. **COMMIT**: "test: improve coverage to 85%/65%"

**優先順位**: **低** (Phase 6以降、他の機能実装が完了後)

**見積もり**: 1-2日

**備考**:
- device.rbのカバレッジはPhase 5.1で自然に向上する
- 現在の75%/55%基準で品質は十分保証されている
- 85%/65%は理想的な目標値であり、必須要件ではない

