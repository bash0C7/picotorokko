# TODO: Project Maintenance Tasks

> **TODO Management Methodology**: See `.claude/skills/project-workflow/SKILL.md` and `CLAUDE.md` ## TODO Management section for task management rules and workflow.

## Future Enhancements (Optional)

### CLI Command Structure Refactoring

- [ ] Consider renaming commands in future if needed (e.g., `pra build-env` or `pra workspace`)

- [ ] Enhance `pra build setup` for complete build preparation
  - [ ] Add PicoRuby build step (call `rake setup_esp32` via ESP-IDF env)
  - [ ] Ensure `pra build setup` handles all pre-build requirements
  - [ ] Update documentation to reflect `pra build setup` capabilities
  - **Status**: `pra build setup` already implemented in `lib/pra/commands/build.rb`, but may need PicoRuby build step integration

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

- [ ] README.md のコマンド形式を正しい CLI サブコマンドに統一
  - **Location**: `README.md:71-76, 162`
  - **Problem**:
    - 行 71-76: `pra flash` / `pra monitor` と記載されているが、正しくは `pra device flash` / `pra device monitor`
    - 行 162: `pra r2p2 flash` は実装されていない存在しないコマンド
  - **Fix**:
    1. 行 71-76: コマンド形式を `pra device flash` / `pra device monitor` に修正
    2. 行 162: 存在しないコマンド `pra r2p2 flash` を削除、または `pra device flash` に修正
    3. device サブコマンド群（flash, monitor, build, setup_esp32）の説明セクションを追加
  - **Related**: `lib/pra/commands/device.rb` の実装と整合性を保つ

---

## 🟡 Medium Priority (Code Quality & Documentation)

### コード重複の排除（パッチ適用ロジック）

- [ ] build.rb と patch.rb のパッチ適用ロジックを共通化
  - **Location**:
    - `lib/pra/commands/build.rb:165-199` (apply_patches メソッド)
    - `lib/pra/commands/patch.rb:117-145` (apply_patches_from_config メソッド)
  - **Problem**:
    - FileUtils.cp_r と Dir.glob を使った同一のパッチ適用処理が重複
    - メンテナンス性が低下し、バグ修正時に両方を変更する必要がある
  - **Solution**:
    1. `lib/pra/patch_applier.rb` などの共通モジュール/クラスを作成
    2. パッチ適用ロジックを抽出してメソッド化
    3. build.rb と patch.rb から共通モジュールを呼び出す形にリファクタリング
  - **Testing**: 既存のテストが通ることを確認後、共通化されたロジックのテストを追加

### コード重複の排除（環境ハッシュ生成ロジック）

- [ ] 環境ハッシュ生成ロジックの共通化
  - **Location**: 複数ファイルで重複
    - `lib/pra/commands/device.rb:73-88`
    - `lib/pra/commands/build.rb` (複数箇所)
    - `lib/pra/commands/cache.rb` など
  - **Problem**:
    - 5箇所以上で同じハッシュ生成処理（Digest::SHA256 による .picoruby-env.yml ハッシュ化）が重複
    - 計算方法が変わった場合に全箇所を変更する必要がある
  - **Solution**:
    1. `lib/pra/env.rb` に `compute_env_hash(env_name)` クラスメソッドを追加
    2. 各コマンドから共通メソッドを呼び出す形にリファクタリング
  - **Testing**: 既存のテストが通ることを確認

### CI_CD_GUIDE.md の YAML スキーマ修正

- [ ] CI_CD_GUIDE.md の YAML 例を .picoruby-env.yml スキーマに統一
  - **Location**: `docs/CI_CD_GUIDE.md:62-73`
  - **Problem**:
    - YAML 例のキー構造が実際の `.picoruby-env.yml` スキーマと一致しない
    - ユーザーが参照する際に混乱を招く可能性がある
  - **Fix**:
    1. 行 62-73 の YAML 例を `lib/pra/env.rb` が期待するスキーマ形式に修正
    2. 実際のリポジトリのサンプル `.picoruby-env.yml` との整合性を確認
  - **Related**: `lib/pra/env.rb` の YAML パース処理

### device コマンドの method_missing 機能ドキュメント追加

- [ ] README.md に device コマンドの動的 Rake 委譲機能の説明を追加
  - **Location**: `README.md` の適切なセクション（例: Usage または Commands）
  - **Problem**:
    - `lib/pra/commands/device.rb:41-51` の method_missing を使った透過的 Rake 委譲機能がドキュメント化されていない
    - ユーザーが `pra device <任意のタスク>` で Rakefile のタスクを実行できることを知らない可能性
  - **Add**:
    1. device サブコマンド群の詳細説明セクション
    2. 明示的なサブコマンド（flash, monitor, build, setup_esp32）の説明
    3. method_missing 経由での任意の Rake タスク実行方法の説明
    4. 使用例: `pra device monitor`, `pra device <custom_rake_task>` など
  - **Related**: `lib/pra/commands/device.rb:41-51`

---

## 🟢 Low Priority (Optional Enhancements)

### Ruby バージョンマトリックステスト

- [ ] CI で複数の Ruby バージョンをテスト
  - **Location**: `.github/workflows/main.yml:18-23`
  - **Current State**:
    - 現在は Ruby 3.4 のみでテスト実行
    - `pra.gemspec` では Ruby >= 3.1.0 を要求
  - **Problem**:
    - Ruby 3.1, 3.2, 3.3 での互換性が検証されていない
    - ユーザーが古いバージョンを使用した際にバグが発生する可能性
  - **Solution**:
    1. `.github/workflows/main.yml` の strategy.matrix に Ruby バージョン配列を追加:
       ```yaml
       strategy:
         matrix:
           ruby: ['3.1', '3.2', '3.3', '3.4']
       ```
    2. steps の `ruby-version: '3.4'` を `ruby-version: ${{ matrix.ruby }}` に変更
  - **Note**: CI 実行時間が増加するため、低優先度

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
