# Priority 3 Phase 1: Documentation Update Automation 詳細設計

**設計日**: 2025-11-13
**Status**: Design Complete
**参考**: TODO.md Priority 3 Phase 1 section
**関連ドキュメント**: type-system-strategy.md, tdd-rubocop-cycle.md

---

## 目次

1. [概要](#概要)
2. [現在のワークフロー分析](#現在のワークフロー分析)
3. [実装プラン](#実装プラン)
4. [ファイル変更→ドキュメントマッピング](#ファイル変更ドキュメントマッピング)
5. [Documentation Check デザイン](#documentation-check-デザイン)
6. [rbs-inline Generation Workflow](#rbs-inline-generation-workflow)
7. [CLAUDE.md 統合詳細](#claudemd-統合詳細)
8. [実装チェックリスト](#実装チェックリスト)

---

## 概要

**Priority 3 目標**: コード実装変更時にドキュメント更新が自動的にトリガーされる仕組みをワークフローに統合。

**実装段階**:
- **Phase 1**: CLAUDE.md ワークフロー統合（30分〜1時間）
- **Phase 2**: Claude Skill 開発（2-3時間）
- **Phase 3**: Git post-commit hook（4-6時間、オプション）
- **Phase 4**: CI ドキュメント検証（将来）

**本ドキュメント対象**: Phase 1

---

## 現在のワークフロー分析

### CLAUDE.md 現在構造

**確認箇所**:
- Line 213-249: Development Workflow: TDD with RuboCop Auto-Correction
- Line 233-236: Before every commit チェックリスト
- Line 238-241: Quality Gates

**現在のチェックリスト** (Line 233-236):
```markdown
4. **Before every commit**:
   - Verify `bundle exec rubocop` returns **0 violations** (exit 0)
   - Verify `bundle exec rake test` passes (exit 0)
   - If any violations remain after `-A`, refactor instead of adding `# rubocop:disable`
```

**Quality Gates** (Line 238-241):
```markdown
**Quality Gates (ALL must pass before commit)**:
- ✅ Tests pass: `bundle exec rake test`
- ✅ RuboCop: 0 violations: `bundle exec rubocop`
- ✅ Coverage ≥ 80% line, ≥ 50% branch (in CI): `bundle exec rake ci`
```

### 関連ドキュメント

#### .claude/docs/tdd-rubocop-cycle.md
- **Phase 4: VERIFY & COMMIT** (Line 153-188)
- 現在: Tests + RuboCop + Coverage チェックのみ
- **挿入ポイント**: Line 171後（Coverage チェック直後）

#### .claude/docs/testing-guidelines.md
- **Quality Gates** セクション
- 同様に Documentation Check を追加

---

## 実装プラン

### Step 1: CLAUDE.md 修正（15分）

#### 位置1: Before every commit チェックリスト追加（Line 236後）

**追加内容**:

```markdown
   - If any violations remain after `-A`, refactor instead of adding `# rubocop:disable`
   - 📝 **Documentation Check** (if implementation changed):
     - Code implementation changed? → Review affected docs below
     - Command behavior? → Update SPEC.md + README.md
     - Template/workflow? → Update docs/CI_CD_GUIDE.md + MRBGEMS_GUIDE.md
     - Public API? → Update rbs-inline annotations (Priority 1+)
     - Reference: `.claude/docs/documentation-structure.md` for file mapping
```

#### 位置2: Quality Gates に追加（Line 241後）

**追加内容**:

```markdown
- ✅ Coverage ≥ 80% line, ≥ 50% branch (in CI): `bundle exec rake ci`
- 📝 **Documentation updated** (if implementation changed):
  - Affected docs reviewed and updated in same commit
  - Mapping: See `.claude/docs/documentation-structure.md`
```

### Step 2: tdd-rubocop-cycle.md 修正（15分）

#### 位置: Phase 4 VERIFY & COMMIT セクション内（Line 171後）

**追加内容**:

```markdown
## 4. Documentation updated (if implementation changed)

📝 Review which documents need updating based on code changes:

**Trigger → Target Docs** (See `.claude/docs/documentation-structure.md` for full mapping):

- **Command changed** (lib/picotorokko/commands/*.rb):
  → SPEC.md (command reference)
  → README.md (Commands section)

- **Environment management changed** (lib/picotorokko/env.rb):
  → SPEC.md (Environment Management)
  → README.md

- **Template engines changed** (lib/picotorokko/template/*.rb):
  → docs/MRBGEMS_GUIDE.md

- **Workflow templates changed** (docs/github-actions/*.yml):
  → docs/CI_CD_GUIDE.md

- **Public API changed** (any lib/picotorokko/*.rb public method):
  → rbs-inline annotations (Priority 1+)
  → bundle exec rbs-inline --output sig lib
  → bundle exec steep check

**Action**: Include doc updates in same commit as code changes.
```

### Step 3: testing-guidelines.md 修正（10分）

#### 位置: Quality Gates セクション

**追加内容**: tdd-rubocop-cycle.md と同様の Documentation Check 項目

---

## ファイル変更→ドキュメントマッピング

### マッピング表

| トリガーファイル | 優先度 | 更新対象ドキュメント | 判断基準 |
|------------------|--------|----------------------|---------|
| `lib/picotorokko/commands/*.rb` | **MUST** | SPEC.md, README.md | コマンドの振る舞い変更 |
| `lib/picotorokko/env.rb` | **MUST** | SPEC.md, README.md | 環境管理ロジック変更 |
| `lib/picotorokko/template/*.rb` | SHOULD | docs/MRBGEMS_GUIDE.md | テンプレート生成ロジック変更 |
| `docs/github-actions/*.yml` | **MUST** | docs/CI_CD_GUIDE.md | ワークフローテンプレート変更 |
| Any public method (lib/) | **MUST** (Priority 1+) | rbs-inline annotations | Public API シグネチャ変更 |
| Test files (test/*/\*_test.rb) | OPTIONAL | - | テストロジック変更（ドキュメント不要） |

### 詳細判断基準

**MUST（必須更新）**:
- ✅ ユーザーが直接実行するコマンドの振る舞い変更
- ✅ CLI 引数・オプション追加/削除/変更
- ✅ 設定ファイル構造変更
- ✅ ワークフロー template 変更
- ✅ Public API シグネチャ変更（Ruby 3.4+ with rbs-inline）

**SHOULD（推奨更新）**:
- ⚠️ 内部実装の大幅な変更
- ⚠️ テンプレート生成ロジック変更

**OPTIONAL（任意）**:
- △ マイナーなリファクタリング（振る舞い変更なし）
- △ テストコードのみの変更
- △ コメント文字列の修正

---

## Documentation Check デザイン

### チェックリスト項目

```markdown
📝 **Documentation Check** (before commit):

1. **Code changes analysis**:
   - [ ] lib/picotorokko/commands/*.rb changed?
     → Update SPEC.md + README.md (Commands Reference)

   - [ ] lib/picotorokko/env.rb changed?
     → Update SPEC.md + README.md

   - [ ] lib/picotorokko/template/*.rb changed?
     → Update docs/MRBGEMS_GUIDE.md

   - [ ] docs/github-actions/*.yml changed?
     → Update docs/CI_CD_GUIDE.md

   - [ ] Public API changed?
     → Add/update rbs-inline annotations (Priority 1+)
     → Run: bundle exec rbs-inline --output sig lib
     → Run: bundle exec steep check

2. **Documentation sync verification**:
   - [ ] SPEC.md accurately documents changed commands
   - [ ] README.md reflects API/behavior changes
   - [ ] Guides updated if structure changed
   - [ ] rbs-inline annotations match implementation
```

### 判断フロー

```
Did code change in lib/picotorokko/commands/
   ├─ YES → Update SPEC.md + README.md
   └─ NO → Skip

Did code change in docs/github-actions/
   ├─ YES → Update docs/CI_CD_GUIDE.md
   └─ NO → Skip

Did Public API change
   ├─ YES → Add rbs-inline annotations + run rbs-inline + steep check
   └─ NO → Skip

All docs updated?
   ├─ YES → Ready for commit
   └─ NO → Update docs and re-verify
```

### エラー時のアクション

**Commit 前に気づいた場合**:
1. ドキュメント更新を追加実装
2. 同じ commit に含める（`git add SPEC.md README.md`）
3. Commit message に反映：`Add X feature + update docs`

**Commit 後に気づいた場合**（Push 前）:
1. 新しい commit でドキュメント更新
2. Commit message：`docs: Update SPEC.md for X feature`

**Push 後に気づいた場合**:
1. TODO.md に記録：`[TODO-DOCS-X] Update SPEC.md for X`
2. 次の commit で修正

---

## rbs-inline Generation Workflow

### Priority 1 統合時（Phase 2以降）の標準ワークフロー

**対象**: lib/picotorokko/*.rb ファイルへの rbs-inline annotations 追加時

```
1. rbs-inline annotation をソースコード内に記述
   # @rbs (String) -> Array[String]
   def new_method(name)
   end

2. Commit 前に .rbs ファイル生成
   bundle exec rbs-inline --output sig lib

3. 型チェック実行
   bundle exec steep check

4. エラーがあれば annotation を修正
   → 再度 rbs-inline + steep check

5. Type check OK になったら commit
```

### Commit チェックリスト（Priority 1 統合後）

```markdown
- [ ] rbs-inline annotations added for all new/modified public methods
- [ ] .rbs files generated: bundle exec rbs-inline --output sig lib
- [ ] Type check passes: bundle exec steep check → 0 errors
- [ ] Tests pass: bundle exec rake test
- [ ] RuboCop: bundle exec rubocop → 0 violations
```

---

## CLAUDE.md 統合詳細

### セクション構成

**Location**: Testing & Quality セクション内

**追加セクション構成**:
```
Testing & Quality
  ├─ Development Workflow: TDD with RuboCop Auto-Correction
  │   ├─ Phase 1: RED
  │   ├─ Phase 2: GREEN
  │   ├─ Phase 3: RuboCop
  │   ├─ Phase 4: REFACTOR
  │   └─ Before every commit  ← Documentation Check 追加
  │
  ├─ Quality Gates (ALL must pass before commit)
  │   ├─ Tests pass
  │   ├─ RuboCop: 0 violations
  │   ├─ Coverage ≥ 85% line, ≥ 60% branch
  │   ├─ RBS generated (Priority 1+)
  │   ├─ Type check passes (Priority 1+)
  │   └─ Documentation updated ← 追加
  │
  └─ Documentation Workflow Integration ← 新規セクション
      ├─ When to update docs
      ├─ File change → Doc mapping
      ├─ rbs-inline generation (Priority 1+)
      └─ Checklist
```

### Before every commit 追加文言

```markdown
- 📝 **Documentation Check** (if implementation changed):
  - Review `git diff` to see what changed
  - Check file mapping in `.claude/docs/documentation-structure.md`
  - Update relevant docs in same commit
  - Reference: Priority 3 Phase 1 design in `.claude/docs/documentation-automation-design.md`
```

### Quality Gates 追加文言

```markdown
- 📝 **Documentation updated** (if implementation changed):
  - Affected files identified using change mapping
  - Docs updated in same commit as code changes
  - No docs lag behind implementation
```

---

## 実装チェックリスト

### Phase 1 完了条件

- [ ] CLAUDE.md "Before every commit" セクションに📝 Documentation Check 追加
- [ ] CLAUDE.md "Quality Gates" セクションに Documentation updated 追加
- [ ] .claude/docs/tdd-rubocop-cycle.md に Documentation Checklist 追加
- [ ] .claude/docs/testing-guidelines.md に Documentation Check 追加
- [ ] .claude/docs/documentation-structure.md にファイル変更マッピング表追加
- [ ] TODO.md Quality Gates "Pre-Commit Checks" に Documentation Check 追加
- [ ] 変更をすべて commit：`docs: Add Documentation Check to CLAUDE.md workflow`

### Phase 1 後の確認方法

**実装後の検証**:
```bash
# テンプレート確認
grep -n "Documentation Check" CLAUDE.md

# マッピング表確認
grep -A 10 "ファイル変更→ドキュメント" .claude/docs/documentation-structure.md

# 実際のワークフローテスト
# 1. コマンド実装を変更（lib/picotorokko/commands/env.rb）
# 2. Documentation Check に従って SPEC.md + README.md を更新
# 3. Commit & verify
```

---

## 関連ドキュメント

### 参考資料

- **TODO.md**: Priority 3 Planned Features セクション
- **type-system-strategy.md**: rbs-inline annotations との連携
- **tdd-rubocop-cycle.md**: TDD サイクル（修正対象）
- **documentation-structure.md**: 詳細なファイルマッピング

### 実装フェーズ状況（Session 3 - 2025-11-14）

**Phase 1**: ✅ COMPLETE
- CLAUDE.md に Documentation Check 統合
- tdd-rubocop-cycle.md に Phase 4 Documentation セクション追加
- testing-guidelines.md に Quality Gates 更新
- documentation-structure.md に完全なファイルマッピング表作成

**Phase 2**: ✅ COMPLETE
- Claude Skill "documentation-sync" 実装完了
- `.claude/skills/documentation-sync/` に 2 つのガイドドキュメント
  * README.md: Skill 概要、使用例、統合ポイント
  * sync-documentation.md: 実装アルゴリズム、シナリオ例、エラーハンドリング
- 特徴: `git diff` 解析 → マッピング表参照 → 優先度付きチェックリスト生成

**Phase 3**: ✅ COMPLETE (Session 3 実装)
- Git post-commit hook 実装: `.git/hooks/post-commit`
- **機能**:
  * Commit 後に自動実行
  * 変更されたファイルを検出
  * documentation-structure.md のマッピング表に基づいて対象ドキュメント判定
  * 優先度別（🔴MUST / 🟡SHOULD / ⚪OPTIONAL）チェックリスト表示
  * 非ブロッキング: 常に exit 0 (commit を邪魔しない)
  * カラー出力でユーザーフレンドリー

- **使用ワークフロー**:
  ```
  git commit ...
    ↓
  Hook 実行（自動）
    ↓
  変更ファイル検出
    ↓
  マッピング表参照
    ↓
  ドキュメント更新提案 + チェックリスト表示
    ↓
  次の commit 前に docs 更新（開発者判断）
  ```

**Phase 4**: Planned (将来)
- CI Documentation Validation
- SPEC.md と実装の一貫性チェック
- コマンドリスト自動比較
- CI 段階での警告/エラー

---

**状態**: Priority 3 Phase 1-3 完全実装済み
**最終日**: 2025-11-14
**次のアクション**: Option 3 (gem publish) または Phase 4 Planning
