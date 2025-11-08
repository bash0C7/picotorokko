# TODO: Project Maintenance Tasks

> **TODO Management Methodology**: See `.claude/skills/project-workflow/SKILL.md` and `CLAUDE.md` ## TODO Management section for task management rules and workflow.

---

## 🎯 実装優先順位（セッション別グルーピング）

### **✅ Phase 1: 基盤強化（完了）** 🔧

(commit: 9b84751f0a740969cdfdcad2ab2dc78cf995f4b6 時点完了済み)

---

### **✅ Phase 2: UX改善（完了）** 📚 

(commit: 9b84751f0a740969cdfdcad2ab2dc78cf995f4b6 時点完了済み)

---

### **✅ Phase 3: CI 拡充・品質基準復元（完了）** 🚀

**目的**: ローカル品質基準達成 → CI テスト範囲拡大 → カバレッジ要件復元 → 全品質チェック自動化

**最終成果**（commit: 9dd758d完了）:
- **ローカル**: 38 tests (全てパス), Line Coverage 67.4% / Branch 35.53%, **RuboCop 0違反** ✅
- **CI**: 66 tests (device_test.rb除外), Line Coverage 81.57% / Branch 56.14% ✅
- **改善**: RuboCop 92違反 → 0違反、テスト範囲 4 → 66、カバレッジ Line 23.72% → 81.57%

---

#### ✅ Task 3.1: ローカル品質基準クリア（RuboCop違反解消） [完了]
- **実装内容**:
  1. RuboCop自動修正: 98個自動修正（`bundle exec rubocop -A`）
  2. 複雑度削減リファクタリング:
     - `lib/pra/commands/device.rb`: `show_available_tasks` メソッドを `resolve_env_name`, `validate_and_get_r2p2_path` に分割
     - `lib/pra/commands/mrbgems.rb`: `generate` メソッドを複数のヘルパーメソッドに分割（7個のメソッド作成）
     - `test/commands/device_test.rb`: 重複したセットアップコードを `setup_test_environment`, `with_stubbed_esp_env` 等のヘルパーに抽出
     - `test/commands/mrbgems_test.rb`: `sub_test_case` ネスト除外（BlockLength削減）
  3. 最終確認: `bundle exec rubocop` → **0 offenses** ✅
  4. テスト合格: **38/38 tests passing** ✅

#### ✅ Task 3.2: CI テスト範囲拡大（66 tests達成） [完了]
- **実装内容**:
  1. Rakefile に TEST_EXCLUDE サポート追加:
     - 正規表現パターンマッチングで複数ファイルを除外可能
  2. `.github/workflows/main.yml` 修正:
     - `bundle exec rake test TEST=test/pra_test.rb` → `bundle exec rake test TEST_EXCLUDE=test/commands/device_test.rb`
  3. SimpleCov要件引き上げ: `minimum_coverage line: 1, branch: 0` → `line: 60, branch: 30`
  4. 最終確認:
     - **66 tests 実行成功** ✅ (38個ローカル + 28個追加)
     - **Line Coverage 81.57% > 60%** ✅
     - **Branch Coverage 56.14% > 30%** ✅

#### ✅ Task 3.3: テストレイヤー分離＆モック R2P2-ESP32 [完了]
- **採用アプローチ**: B（テストレイヤー分離）
  - CI では `test/commands/device_test.rb` を除外
  - ローカル開発では全38 tests実行可能
  - device_test.rb は R2P2-ESP32 Rakefile 依存のため、本番に近い環境で実行可能
- **実装内容**:
  1. モック R2P2-ESP32 Rakefile 作成: `test/fixtures/R2P2-ESP32/Rakefile`
  2. 本番環境と同じ Rake タスク構造（flash, monitor, build, setup_esp32）
  3. テスト時のダミー実装（実際の実行は不要）
- **メリット**:
  - CI は高速・安定（device_test.rb除外）
  - ローカル開発では全テスト実行可能（統合テストを検証）
  - R2P2-ESP32 依存を明確に分離

---

**Phase 3 の成果**:
- ✅ ローカル品質基準達成（RuboCop 0違反）
- ✅ CI テスト範囲 4→66 tests 拡大（16.5倍）
- ✅ カバレッジ Line 23.72%→81.57% 向上（+57.85%）
- ✅ テストレイヤー分離による安定な CI/開発環境
- ✅ 全タスクで Kent Beck の「Tidy First」原則を適用

---

### **🔮 Future Enhancements (Phase 4+)**

#### Task 4.x: カバレッジ Line 80%→90%, Branch 50%→70% 向上
- 現状: Line 81.57%, Branch 56.14% で既に高い基準達成
- 将来: device_test.rb の R2P2-ESP32 依存をモック化し、全テストを CI で実行可能にする
- 推奨アプローチ: アプローチ A（`lib/pra/env.rb` に CI 環境検出を追加）

#### Task 5.x: RuboCop 統合・CI 完全自動化
- 現状: ローカルテストで `bundle exec rake ci` (test + rubocop) 実行可能
- 将来: CI workflow を `bundle exec rake ci` に統合（全品質チェック自動化）

---

## Future Enhancements (Optional)

### CLI Command Structure Refactoring

- [ ] Consider renaming commands in future if needed (e.g., `pra build-env` or `pra workspace`)

---

### ⚠️ pra ci: --force Option (Implementation Forbidden)

**Status**: `pra ci setup` already implemented. The `--force` option is **forbidden** unless explicitly requested.

- 🚫 **Do not implement** `pra ci setup --force` option
  - **Current behavior**: Interactive prompt "Overwrite? (y/N)" if file exists
  - **Reason forbidden**: CI templates follow "fork and customize" model; users should own and edit templates directly
  - **Permitted**: Modify CI templates and documentation in `docs/`

---

## 🔴 High Priority (CI/Testing Strategy)

### CI Test Execution Strategy - ESP-IDF Dependency Issue

- [ ] **Resolve: Tests fail in CI due to ESP-IDF environment missing**
  - **Problem**:
    - CI workflow executes `bundle exec rake ci`, which runs all tests
    - Tests like `device_test.rb` call `execute_with_esp_env`, which tries to source `$IDF_PATH/export.sh`
    - CI environment doesn't have ESP-IDF installed → `export.sh` not found → bash fails
    - Although test code has stubs for `execute_with_esp_env`, the test loading/setup phase still triggers actual bash execution
  - **Root Cause**:
    - User's `~/.bashrc` or shell profile auto-activates ESP-IDF on all shell invocations
    - Local dev environment: works fine (ESP-IDF installed, `export.sh` exists)
    - CI environment: fails (no ESP-IDF, `export.sh` doesn't exist)
  - **Temporary Fix** (current branch fix_ci):
    - Reduce CI test scope to minimal, safe tests
    - Modify `.github/workflows/main.yml` to run only `test/pra_test.rb`
    - This runs version check only (no external dependencies)
    - Reduce SimpleCov minimum coverage to line: 1, branch: 1 (temporary)
    - Goal: Get CI green while planning long-term solution
  - **Long-term Solution** (future task):
    - Separate tests into layers:
      1. **Unit tests** (no external tools): YAML parsing, env management, git operations
      2. **Integration tests** (require ESP-IDF): device commands, build setup
    - Create separate CI job for integration tests (only run on demand or main branch)
    - Or mock `execute_with_esp_env` at module load time (not in individual tests)
    - Or wrap `execute_with_esp_env` to detect CI environment and skip ESP-IDF execution
  - **Files to Update**:
    - `.github/workflows/main.yml`: Change `bundle exec rake ci` to `bundle exec rake test TEST=test/pra_test.rb`
    - `test/test_helper.rb`: Restore coverage requirements (line: 80, branch: 50) once test scope expands
  - **Related Issues**:
    - PR #30 failing CI checks
    - Need to ensure other test files work before expanding test scope

### Restore SimpleCov Coverage Requirements

- [ ] **Restore: Increase SimpleCov minimum coverage back to line: 80, branch: 50**
  - **Current State** (temporary fix):
    - `test/test_helper.rb` has minimum_coverage line: 1, branch: 1
    - This allows CI to pass with minimal test scope
  - **Problem**:
    - Current minimum (1%) is too low for production code quality
    - Allows untested code to merge without warning
  - **Solution** (when expanding test scope):
    1. Expand test suite to cover more code paths
    2. Run full test suite: `bundle exec rake ci` (all test files)
    3. Restore `test/test_helper.rb` line 11:
       ```ruby
       minimum_coverage line: 80, branch: 50 if ENV["CI"]
       ```
  - **Prerequisite**:
    - Must fix ESP-IDF dependency issue first (see "CI Test Execution Strategy" above)
    - All test files must pass in CI without ESP-IDF environment
  - **Related Files**:
    - `test/test_helper.rb`
    - `.github/workflows/main.yml` - will change from `TEST=test/pra_test.rb` back to `ci` task
    - `.codecov.yml` - Change `informational: true` back to `informational: false` when coverage requirements are restored

---

## 🟡 Medium Priority (Code Quality & Documentation)

---

## 🔒 Security Enhancements (Do not implement without explicit request)

All security enhancements below do not change behavior and should only be implemented with explicit user request.

### Symbolic Link Race Condition Prevention

- [ ] Add race condition protection to symbolic link checks
  - **Where**: Symbolic link validation in `lib/pra/commands/build.rb`
  - **Problem**: TOCTOU (Time-of-check to time-of-use) vulnerability between check and usage
  - **Solution**: Use File.stat with follow_symlinks: false instead of File.symlink?
  - **Note**: Limited real-world risk, low priority

### Path Traversal Input Validation

- [ ] Add path traversal validation for user inputs (env_name, etc.)
  - **Where**: All command files in `lib/pra/commands/`
  - **Problem**: User inputs like env_name could contain `../../` without validation
  - **Checks needed**:
    - Reject paths containing `..`
    - Reject absolute paths
    - Allow only alphanumeric, hyphen, underscore
  - **Solution**: Create `lib/pra/validator.rb` for centralized validation
  - **Testing**: Add path traversal attack test cases
  - **Note**: Current codebase is developer-facing tool with limited attack surface

---

## 🟢 New Feature Implementation

### PicoRuby RuboCop Configuration Template

**Status**: Planning complete. See `TODO_rubocop_picoruby.md` for comprehensive implementation guide.

- [ ] **Implement PicoRuby RuboCop template for static analysis of generated scripts**
  - **Purpose**: Detect CRuby methods not supported in PicoRuby with warning-level feedback
  - **Key Design**:
    - pra gem provides data extraction script (template), NOT data files
    - Users run `pra rubocop update` to fetch latest PicoRuby definitions from picoruby.github.io
    - Warning severity (not error) for unsupported methods
    - Users can disable warnings with `# rubocop:disable PicoRuby/UnsupportedMethod`
  - **Deliverables**:
    - Template directory: `lib/pra/templates/rubocop/`
    - Data extraction script: `lib/pra/templates/rubocop/scripts/update_methods.rb`
    - Custom Cop: `lib/pra/templates/rubocop/lib/rubocop/cop/picoruby/unsupported_method.rb`
    - RuboCop config: `lib/pra/templates/rubocop/.rubocop.yml`
    - Setup guide: `lib/pra/templates/rubocop/README.md`
    - pra command: `lib/pra/commands/rubocop.rb` with `setup` and `update` subcommands
    - Tests: `test/pra/commands/rubocop_test.rb`
  - **User Workflow**:
    1. `pra rubocop setup` - Deploy template to user's PicoRuby project
    2. `pra rubocop update` - Generate method database from latest picoruby.github.io
    3. `bundle exec rubocop` - Run static analysis, warnings shown for unsupported methods
  - **Details**: See `TODO_rubocop_picoruby.md` for:
    - Complete implementation guide with code examples
    - Data flow architecture and design decisions
    - Investigation results (PicoRuby RBS doc structure, CRuby method extraction, RuboCop patterns)
    - Step-by-step implementation instructions (Phase 1-7)
    - Testing and verification procedures
    - Troubleshooting and limitations
