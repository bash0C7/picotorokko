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

### **Phase 3: CI 拡充・品質基準復元（5段階・順次実行）** 🚀

**目的**: ローカル品質基準達成 → CI テスト範囲拡大 → カバレッジ要件復元 → 全品質チェック自動化

**現状分析**（2025-11-09 ローカル検証完了）:
- **ローカル**: 38 tests (全てパス), Line Coverage 66.76% / Branch 36.78%, RuboCop 92違反（86自動修正可能）
- **CI**: 4 tests のみ（`test/pra_test.rb`）, Line Coverage 23.72% / Branch 0.0%, RuboCop未実行
- **問題**: ESP-IDF依存（`device_test.rb`）がCI環境で実行不可、カバレッジ要件が一時的に最小値

---

#### ⚠️ Task 3.1: ローカル品質基準クリア（RuboCop違反解消）
- **価値**: ⭐⭐⭐ 高 - コード品質基盤、CI統合の前提条件
- **並列性**: ❌ Task 3.2 以降をブロック（順次実行必須）
- **実施内容**:
  1. RuboCop自動修正実行: `bundle exec rubocop -A`（86個自動修正）
  2. 手動修正（6個の残存違反を解決）:
     - `lib/pra/commands/build.rb`: Layout violations（4個）
     - `lib/pra/commands/device.rb`: Complexity violations（2個: `show_available_tasks` メソッドの分割）
     - `lib/pra/commands/mrbgems.rb`: AbcSize, MethodLength（分割して複雑度削減）
  3. 全違反解消確認: `bundle exec rubocop` → 0 offenses
  4. 最後に `bundle exec rake ci` で全品質ゲートクリア確認
- **影響ファイル**:
  - `lib/pra/commands/build.rb`
  - `lib/pra/commands/device.rb`
  - `lib/pra/commands/mrbgems.rb`
  - `test/commands/mrbgems_test.rb`（テスト内のRuboCop違反も対応）
- **完了条件**: `bundle exec rubocop` が 0 offenses を報告
- **推奨アプローチ**: Kent Beckの「Tidy First」に従い、リファクタリングで複雑度を削減

---

#### ⚠️ Task 3.2: CI テスト範囲拡大（ESP-IDF非依存テスト8ファイル）
- **価値**: ⭐⭐⭐ 高 - カバレッジ 23.72%→60%台へ向上
- **並列性**: ❌ Task 3.1 完了後、Task 3.3 と並列不可（順次実行）
- **実施内容**:
  1. ESP-IDF非依存テストファイル特定（8ファイル）:
     - `test/pra_test.rb`（4 tests）
     - `test/env_test.rb`（複数テスト）
     - `test/commands/cache_test.rb`（複数テスト）
     - `test/commands/patch_test.rb`（複数テスト）
     - `test/commands/ci_test.rb`（複数テスト）
     - `test/commands/env_test.rb`（複数テスト）
     - `test/commands/build_test.rb`（複数テスト）
     - `test/commands/mrbgems_test.rb`（複数テスト）
  2. `.github/workflows/main.yml` 修正:
     - 現在: `bundle exec rake test TEST=test/pra_test.rb`
     - 変更後: `bundle exec rake test TEST_EXCLUDE=test/commands/device_test.rb` または各ファイルを明示指定
  3. SimpleCov要件を段階的に引き上げ:
     - `test/test_helper.rb` line 11: `minimum_coverage line: 1, branch: 0` → `line: 60, branch: 30`
  4. CI実行確認:
     - 8ファイル全て実行（30+ tests）
     - カバレッジ 60%台達成確認
     - RuboCop統合は Task 3.5 で実施
- **影響ファイル**:
  - `.github/workflows/main.yml`（テスト実行コマンド変更）
  - `test/test_helper.rb`（カバレッジ要件変更）
- **完了条件**: CI で 30+ tests 実行成功、カバレッジ Line 60% 以上達成
- **注意**: `device_test.rb` は Task 3.3 で対応するため、このタスクからは除外

---

#### ⚠️ Task 3.3: ESP-IDF依存テストのCI対応（3アプローチから選択）
- **価値**: ⭐⭐ 中 - 全テストスイートCI実行、カバレッジ66%台達成
- **並列性**: ❌ Task 3.2 完了後に実施（順次実行）
- **実施内容**（3つのアプローチから選択）:
  - **アプローチA: CI環境検出スキップ**（推奨・最もシンプル）:
    1. `lib/pra/env.rb` の `execute_with_esp_env` メソッドにCI環境検出追加
    2. `ENV["CI"]` 時は ESP-IDF export.sh を実行せず no-op 化
    3. テストのスタブ化は維持（二重防御）
  - **アプローチB: テストレイヤー分離**（長期的）:
    1. `test/integration/` ディレクトリ作成
    2. `device_test.rb` を `test/integration/` へ移動
    3. CI は `test/` のみ実行、integration は手動または別job
  - **アプローチC: モック強化**（複雑度高）:
    1. `test/test_helper.rb` でグローバルに `execute_with_esp_env` モック化
    2. モジュールロード時から有効化
- **影響ファイル**:
  - 【A】`lib/pra/env.rb`（`execute_with_esp_env` メソッド修正）
  - 【B】`test/integration/device_test.rb`, `Rakefile`, `.github/workflows/main.yml`
  - 【C】`test/test_helper.rb`, `test/commands/device_test.rb`
- **完了条件**: CI で全38 tests実行成功、カバレッジ Line 66%台達成
- **推奨アプローチ**: アプローチA（`lib/pra/env.rb` に1行の環境検出追加）
- **ユーザー相談推奨**: アプローチ選択時に相談

---

#### ⚠️ Task 3.4: カバレッジ要件復元（目標Line 80% / Branch 50%）
- **価値**: ⭐⭐ 中 - 品質基準の完全復旧
- **並列性**: ❌ Task 3.3 完了後に実施（順次実行）
- **実施内容**:
  1. カバレッジギャップ分析（現在66.76% → 目標80%、約13.24%分のカバレッジ向上が必要）:
     - `coverage/coverage.html` でHTMLレポート確認
     - 未カバー箇所をリスト化
  2. 追加テストケース作成:
     - 各未カバー箇所に対応するテストを小さく追加
     - 小さいサイクルで回す（Red-Green-Refactor）
     - RuboCop違反を発生させない
  3. `test/test_helper.rb` 修正:
     - `minimum_coverage line: 60, branch: 30` → `line: 80, branch: 50`
  4. `.codecov.yml` 修正:
     - `informational: true` → `informational: false`（カバレッジ低下でCIを失敗させる）
- **影響ファイル**:
  - `test/test_helper.rb`（カバレッジ要件）
  - `.codecov.yml`（Codecov設定）
  - 各テストファイル（追加テストケース）
- **完了条件**: CI でカバレッジ Line 80% / Branch 50% 達成
- **推奨アプローチ**: Kent Beckの「Tidy First」に従い、小さいテストを多数追加（1-5分サイクル）

---

#### ⚠️ Task 3.5: RuboCop統合・CI完全自動化
- **価値**: ⭐⭐⭐ 高 - 品質チェック自動化完成
- **並列性**: ❌ Task 3.1 と Task 3.4 完了後に実施（順次実行）
- **実施内容**:
  1. `.github/workflows/main.yml` 修正:
     - 現在: `bundle exec rake test TEST=...`
     - 変更後: `bundle exec rake ci`（test + rubocop）
  2. ローカルRubocopスクリプト確認:
     - `Rakefile` の `ci` タスクが `test` + `rubocop` を実行確認
  3. CI実行確認:
     - テスト全38個実行 ✅
     - RuboCop 0 offenses ✅
     - カバレッジ Line 80% / Branch 50% ✅
- **影響ファイル**:
  - `.github/workflows/main.yml`（CIコマンド変更）
- **完了条件**: CI で `bundle exec rake ci` 成功、全品質チェック自動化
- **推奨アプローチ**: Rakefile既存の `ci` タスク設定確認し、そのまま使用

---

**Phase 3 の効果**:
- ローカル品質基準達成（RuboCop 0違反）
- CI テスト範囲 4→38 tests 拡大（10倍）
- カバレッジ 23.72%→80% 復元（約3.4倍）
- 品質チェック完全自動化（test + rubocop + coverage）
- 全タスクで Kent Beck の「Tidy First」原則を適用（小さく、安全に、頻繁に）

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
