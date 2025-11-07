# TODO: Project Maintenance Tasks

> **TODO Management Methodology**: See `.claude/skills/project-workflow/SKILL.md` and `CLAUDE.md` ## TODO Management section for task management rules and workflow.

## Future Enhancements (Optional)

### CLI Command Structure Refactoring

- [ ] Consider renaming commands in future if needed (e.g., `pra build-env` or `pra workspace`)

- [x] ~~Enhance `pra build setup` for complete build preparation~~ **完了 (2025-11-07)**
  - [x] ~~Add PicoRuby build step (call `rake setup_esp32` via ESP-IDF env)~~ **実装完了**
  - [ ] **次のセッションで実施**: ESP-IDF 環境での動作確認
  - [ ] **次のセッションで実施**: README.md の更新
    - **必須修正** (コマンド形式の誤り):
      - 行 74-75: `pra flash` / `pra monitor` → `pra device flash` / `pra device monitor` に修正
      - 行 107-108: Commands Reference セクションも同様に修正
      - 行 162: `pra r2p2 flash` を `pra device flash` に修正（または該当行を削除）
    - **機能追加の説明**:
      - `pra build setup` のセクション（行 95 付近）に以下を追加:
        ```
        - Automatically runs `rake setup_esp32` to prepare PicoRuby build environment
        - Sets up all pre-build requirements (submodules, dependencies, etc.)
        - Displays warnings if ESP-IDF environment setup fails
        ```
    - **オプション**: `pra device` コマンド群の説明セクションを追加
      - 明示的なサブコマンド: `flash`, `monitor`, `build`, `setup_esp32`
      - 動的 Rake 委譲機能の説明（`lib/pra/commands/device.rb:41-51` の method_missing）
  - **実装詳細**:
    - **Location**: `lib/pra/commands/build.rb:80-90`
    - **実装内容**:
      - パッチ適用後、storage/home コピー前に `rake setup_esp32` を実行
      - `Pra::Env.execute_with_esp_env` を使用して ESP-IDF 環境で実行
      - エラーハンドリング: 失敗時は警告を表示して処理を継続（ユーザーが後で手動実行可能）
    - **テスト結果**: 既存テスト全て通過 (9 tests, 29 assertions, 0 failures)
      - ESP-IDF 環境がない場合は警告が出るが、rescue 句で適切にハンドリングされる
    - **動作確認方法** (ESP-IDF 環境で実施):
      1. キャッシュを用意: `pra cache fetch <env_name>`
      2. ビルド環境構築: `pra build setup <env_name>`
      3. 出力に "Setting up PicoRuby build environment..." と "✓ PicoRuby build environment ready" が表示されることを確認
      4. 失敗した場合は "✗ Warning: Failed to run rake setup_esp32" が表示される
    - **関連ファイル**:
      - 実装: `lib/pra/commands/build.rb`
      - ESP-IDF 実行ユーティリティ: `lib/pra/env.rb:230-256` (`execute_with_esp_env` メソッド)
      - テスト: `test/commands/build_test.rb`

---

### ⚠️ pra ci コマンド実装禁止 (Implementation Forbidden)

**以下の `pra ci` コマンド関連の実装は、特別な指示がない限り禁止**

**理由**:
- `pra ci` コマンドは他のCLIコマンド（`pra device build`, `pra cache fetch` など）のインターフェースに依存
- これらのコマンドが変更されると、CI テンプレートやコマンドの動作に影響
- まず基盤となるコマンド群を安定化させてからCI機能を実装すべき
- テンプレート更新機能（`--force`オプション）は、ユーザーがテンプレートをカスタマイズする前提のため、基盤が安定してから実装が望ましい

**許可される作業**:
- ✅ CI テンプレートファイル (`docs/github-actions/esp32-build.yml`) の修正・改善
- ✅ CI ドキュメント (`docs/CI_CD_GUIDE.md`) の更新
- 🚫 `pra ci setup --force` オプションの実装
- 🚫 `pra ci` 関連の新機能追加

---

### pra ci setup --force オプション (実装禁止中)

- [ ] Add `--force` option to `pra ci setup` command
  - **Rationale**: CI workflow templates should be "fork and customize" model. Users edit workflows directly (ESP-IDF version, target chip, branches, custom steps). `pra ci setup --force` allows refreshing template while letting users salvage changes via `git diff`.
  - **Location**: `lib/pra/commands/ci.rb` (currently has `setup` subcommand with interactive prompt)
  - **Current Behavior**:
    - Existing file → Shows prompt "Overwrite? (y/N)" → User confirms
  - **New Behavior**:
    - No `--force` + existing file → Error message + exit (fail-fast)
    - `--force` + existing file → Overwrite without confirmation
    - No existing file → Copy template (same as current)
  - **Implementation Details**:
    1. Add `method_option :force, type: :boolean, desc: 'Overwrite existing workflow file'` to `setup` method
    2. Remove interactive prompt logic (lines 34-43 in `lib/pra/commands/ci.rb`)
    3. Replace with:
       ```ruby
       if File.exist?(target_file)
         if options[:force]
           # Proceed with copy
         else
           puts "✗ Error: File already exists: .github/workflows/esp32-build.yml"
           puts "  Use --force to overwrite: pra ci setup --force"
           exit 1
         end
       end
       ```
    4. Update success message to mention `--force` for future updates
  - **Testing Changes** (`test/commands/ci_test.rb`):
    - ❌ Remove: `test "prompts for overwrite when file already exists and user declines"` (lines 66-85)
    - ❌ Remove: `test "overwrites file when user confirms"` (lines 87-108)
    - ❌ Remove: `test "accepts 'yes' as full word for confirmation"` (lines 110-128)
    - ✅ Add: `test "fails when file exists without --force option"` - Verify error message and exit
    - ✅ Add: `test "overwrites file with --force option"` - Verify `Pra::Commands::Ci.start(['setup', '--force'])`
    - Keep: `with_stdin` helper (may be used elsewhere, no harm keeping)
  - **Documentation Updates**:
    1. Consider adding `pra ci setup` mention in main README.md if relevant
  - **Related Context**: Original TODO planned "Add CI/CD update command" with `pra ci update` subcommand. Analysis showed workflow templates are meant to be "fork and customize" by users (documented in CI_CD_GUIDE.md). Rather than Bmodel (config-based), Amodel (user ownership) is more appropriate, so `pra ci setup --force` is the right pattern.

---

## 🔴 High Priority (Documentation & Testing)

### README.md コマンド説明の修正

- [ ] README.md のコマンド形式を正しい CLI サブコマンドに統一 **→ CLI Command Structure Refactoring に統合**
  - **Note**: この項目は「CLI Command Structure Refactoring」セクション（行 11-28）に詳細が記載されています
  - **次のセッションで実施**: 上記セクションの指示に従って README.md を更新してください

---

## 🟢 Low Priority (Optional Enhancements)

### セキュリティ強化（シンボリックリンク race condition 対策）

- [ ] build.rb のシンボリックリンクチェックに race condition 対策
  - **Location**: `lib/pra/commands/build.rb:92-93`
  - **Current Code**:
    ```ruby
    if File.symlink?(top_dir)
      raise "Error: Top directory is a symbolic link: #{top_dir}"
    end
    ```
  - **Problem**:
    - File.symlink? チェックと実際の使用の間に race condition が存在
    - チェック後、使用前にファイルが改変される TOCTOU (Time-of-check to time-of-use) 脆弱性
  - **Solution**:
    1. File.stat を使ってシンボリックリンクを辿らないチェックに変更
    2. 例外処理で TOCTOU を防ぐパターンを採用
  - **Note**: 実際の攻撃シナリオは限定的なため低優先度

### セキュリティ強化（パストラバーサル検証）

- [ ] ユーザー入力のパス（env_name など）にパストラバーサル検証を追加
  - **Location**: 複数のコマンドファイル
  - **Problem**:
    - env_name などのユーザー入力に `../../` などの相対パス記号が含まれていても検証されない
    - 悪意あるユーザーが意図しないディレクトリにアクセス可能な可能性
  - **Solution**:
    1. `lib/pra/validator.rb` などの共通バリデーションモジュールを作成
    2. env_name などのパラメータに対して以下をチェック:
       - `..` が含まれていないこと
       - 絶対パスでないこと
       - 許可された文字（英数字、ハイフン、アンダースコア）のみであること
    3. 各コマンドで入力バリデーションを追加
  - **Testing**: パストラバーサル攻撃のテストケースを追加
  - **Note**: 現在のコードは開発者向けツールであり、攻撃リスクは限定的だが、将来的な強化として検討
