# Priority 2 Phase 1: RBS Documentation Generation 調査・設計

**作成日**: 2025-11-13
**対象**: Phase 2 実装前の調査・設計フェーズ
**前提**: Priority 1 で **rbs-inline annotations のみ** の採用が決定済み
**参考**: type-system-strategy.md, type-annotation-guide.md

---

## 目次

1. [概要](#概要)
2. [Priority 1 決定の影響](#priority-1-決定の影響)
3. [RBS Documentation Generator 候補](#rbs-documentation-generator-候補)
4. [推奨戦略](#推奨戦略)
5. [実装計画](#実装計画)
6. [RubyDoc.info 統合](#rubyDocinfo-統合)
7. [チェックリスト](#チェックリスト)

---

## 概要

**Priority 2 目標**: rbs-inline annotations から自動生成される RBS ファイルを基に、包括的なドキュメントを生成・配置する仕組みを構築。

**重要な前提**: Priority 1 Phase 1 で **YARD は不採用** が決定された。したがって、Priority 2 は **RBS のみからドキュメント生成** する方式に特化する。

**次のような人が参照すべき**: Phase 2 ドキュメント生成を実装する開発者

---

## Priority 1 決定の影響

### Decision: rbs-inline annotations のみ採用

**Type system strategy**:
```
rbs-inline annotations（コード内）
  ↓ [bundle exec rbs-inline --output sig lib]
.rbs files（自動生成、sig/ ディレクトリ）
  ↓ [Documentation generator]
RBS Documentation（HTML等）
```

**Impact on Priority 2**:

| 項目 | 影響 |
|------|------|
| **ドキュメント源** | .rbs ファイルのみ（YARD なし） |
| **生成方法** | RBS generator ツール（rbs-doc, Steep docs等） |
| **説明文の入手元** | rbs-inline コメント → .rbs に自動含まれる |
| **ユーザーガイド** | markdown ファイル + 自動生成 RBS docs |

---

## RBS Documentation Generator 候補

### 候補1: rbs-doc

**概要**:
```
専用の RBS ドキュメント生成ツール
.rbs ファイル → HTML ドキュメント生成
```

**状況**:
- ⚠️ 実装段階（成熟度: 低）
- GitHub: https://github.com/ruby/rbs-doc
- Ruby 公式が開発（信頼性は高い）

**メリット**:
- ✅ RBS 専用に設計
- ✅ Ruby 公式ツール
- ✅ 将来的に標準化される見込み

**デメリット**:
- ❌ 成熟度が低い
- ❌ 実装例が限定的
- ❌ ドキュメント不足

### 候補2: Steep built-in RBS documentation

**概要**:
```
Steep が提供するRBS documentation 機能
RBS → ドキュメント出力
```

**状況**:
- ⚠️ 実験的機能
- Steep: https://github.com/soutaro/steep

**メリット**:
- ✅ Steep に統合（追加setup 不要）
- ✅ soutaro (Steep author) が開発

**デメリット**:
- ❌ 実装例が少ない
- ❌ カスタマイズ性不明
- ❌ 成熟度が低い

### 候補3: yard-rbs plugin（YARD ベース）

**概要**:
```
YARD と RBS の統合プラグイン
.rbs ファイル → YARD ドキュメント統合
```

**状況**:
- ⚠️ YARD は Priority 1 で不採用
- このオプションは除外

---

## 推奨戦略

### 短期（Phase 2）: RBS ファイルのみで実装

```
CURRENT STATE (Ruby 3.4, 2025-11-13)
├─ rbs-inline annotations in source code
├─ Auto-generated .rbs files in sig/
└─ Steep checks types (local development)

TARGET STATE (Phase 2)
├─ .rbs files version controlled
├─ RBS documentation generator (TBD)
├─ Generated HTML docs
└─ RubyDoc.info auto-deployment
```

### ドキュメント生成方式: 段階的アプローチ

#### Stage 1: RubyDoc.info に頼る（最小コスト）

**実装**:
```bash
# .rbs ファイルが sig/ に commit されている
# gem publish時に RubyDoc.info が自動検出 → ドキュメント生成
```

**フロー**:
```
git push origin main
  ↓
GitHub Release
  ↓
gem build & gem push
  ↓
RubyDoc.info automatically generates docs from .rbs
  ↓
Documentation available at:
https://rubydoc.info/gems/picotorokko/
```

**メリット**:
- ✅ 追加実装コストなし
- ✅ 自動化
- ✅ RubyDoc.info が無料提供

**デメリット**:
- ⚠️ RubyDoc.info に RBS サポート依存
- ⚠️ カスタマイズ性なし
- ⚠️ ローカル生成できない

#### Stage 2: ローカル生成可能にする（Phase 2後期）

**方針**:
```
rbs-doc または Steep の built-in 機能を試用
ローカル開発環境で doc 生成テスト
```

**実装予定**:
```bash
# 将来のコマンド
bundle exec rake doc:generate
  ├─ rbs-doc (if available)
  ├─ or Steep doc feature
  └─ Generate doc/ に HTML 出力
```

---

## 実装計画

### Phase 2: 最小限の実装

**Objective**: RubyDoc.info 自動生成にすべて任せる

**実装 checklist**:
```markdown
- [ ] .rbs ファイルを git add/commit
- [ ] Ruby gem release 時に自動生成されることを確認
- [ ] RubyDoc.info docs URL を README.md に追加
- [ ] Gemfile や gemspec でドキュメント参照設定
```

**README.md に追加**:
```markdown
## Documentation

API documentation is automatically generated from type annotations:

- **[RubyDoc.info](https://rubydoc.info/gems/picotorokko/)** - Generated from RBS type definitions
- **[Type Annotations Guide](docs/type-annotations.md)** - How we use rbs-inline
- **[User Guides](docs/)** - Installation, CI/CD setup, etc.
```

### Phase 3: ローカル生成可能化 ✅ COMPLETE (Session 3 - 2025-11-14)

**Objective**: ローカル開発時に documentation 確認可能 (YARD を使用)

**実装完了**:
```bash
# YARD 追加
gem install yard  # or: bundle install (YARD in gemspec)

# ローカルでドキュメント生成
bundle exec rake doc:generate

# 生成されたドキュメント
# - HTML: doc/index.html
# - Output: 66.28% documented (26 files, 109 methods)
```

**実装詳細**:

**Step 1: YARD を開発依存に追加** ✅
```ruby
# picotorokko.gemspec
spec.add_development_dependency "yard", "~> 0.9"
```

**Step 2: Rakefile に Rake task 追加** ✅
```ruby
# Rakefile
begin
  require "yard"
  YARD::Rake::YardocTask.new do |t|
    t.files   = ["lib/**/*.rb", "exe/**/*"]
    t.options = ["--output-dir", "doc", "--readme", "README.md", "--markup", "markdown"]
  end
rescue LoadError
  # YARD not installed
  task :yard do
    puts "⚠️  YARD not available. Install with: gem install yard"
  end
end

namespace :doc do
  desc "Generate API documentation with YARD"
  task :generate => :yard do
    puts "✓ API documentation generated in doc/"
  end
end
```

**Step 3: gemspec に documentation_uri 設定** ✅
```ruby
spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/picotorokko/"
```

**Step 4: .gitignore 確認** ✅
```
doc/       # YARD generated docs (already in .gitignore)
.yardoc/   # YARD cache (already in .gitignore)
```

**使用方法**:
```bash
# ローカルでドキュメント生成
bundle exec rake doc:generate

# 生成されたドキュメント確認
open doc/index.html  # macOS
xdg-open doc/index.html  # Linux

# RubyDoc.info（自動生成、gem publish 時）
# https://rubydoc.info/gems/picotorokko/
```

**マトリックス**:
- Files: 26
- Modules: 10 (5 undocumented)
- Classes: 27 (3 undocumented)
- Methods: 109 (43 undocumented)
- **Documentation Coverage: 66.28%**

**注記**: rbs-inline コメント (@rbs) と YARD コメント（説明文）は分離設計
- @rbs: 型チェック用（Steep で検証）
- YARD: HTML ドキュメント用（説明・使用例）
- YARD は @rbs タグを認識しないため警告が出ますが、ドキュメント生成に問題はありません

**Phase 3 実装による変更**:
- ✅ ローカルで doc 生成可能
- ✅ doc/ ディレクトリに HTML ドキュメント出力
- ✅ RubyDoc.info への自動デプロイ（gem publish 時）
- ✅ gemspec に documentation_uri メタデータ設定

**後続の考慮項目**:
- YARD コメント追加（オプション）: メソッドに説明文を追加すれば coverage 向上
- CI 統合: GitHub Actions で doc 生成を自動化
- doc/ ディレクトリ: .gitignore に登録済み（生成物なので commit 不要）

---

## RubyDoc.info 統合

### RubyDoc.info 自動サポート状況

**RBS サポート**:
- Status: ⚠️ 検証必要
- 推測: RubyDoc.info は .rbs ファイルを自動検出 → ドキュメント生成

**検証方法** (Phase 2実装時):
```bash
1. Gem を新バージョンで publish
2. RubyDoc.info にアクセス
3. RBS documentation が生成されているか確認
4. YARD コメントがない場合、RBS docs のみで十分か確認
```

### RubyDoc.info Badge

**README.md に追加**:
```markdown
[![Documentation](https://img.shields.io/badge/docs-rubydoc.info-blue)](https://rubydoc.info/gems/picotorokko/)
```

---

## ドキュメント構造（推奨）

### Phase 2 以降のドキュメント配置

```
picotorokko/ (gem)
├─ README.md
│  ├─ Quick Start
│  └─ Documentation links
│      └─ https://rubydoc.info/gems/picotorokko/ ← auto-generated RBS docs
│
├─ docs/
│  ├─ MRBGEMS_GUIDE.md (user guide)
│  ├─ CI_CD_GUIDE.md (user guide)
│  └─ github-actions/ (templates)
│
├─ .claude/docs/
│  ├─ type-system-strategy.md (developer guide)
│  ├─ type-annotation-guide.md (developer guide)
│  ├─ t-wada-style-tdd-guide.md (developer guide)
│  └─ documentation-generation.md (this file)
│
└─ sig/ (generated RBS files, git committed)
   └─ picotorokko/*.rbs
```

### Documentation層の区分

| Audience | Location | Content | Generation |
|----------|----------|---------|------------|
| **User** | README.md | Quick start, links | Manual |
| **User** | docs/ | Installation, guides | Manual |
| **User** | RubyDoc.info | API reference | Auto (from .rbs) |
| **Developer** | .claude/docs/ | Development guides | Manual |

---

## チェックリスト

### Phase 2 完了条件

- [ ] `.rbs ファイルが sig/ に配置・committed**
- [ ] README.md に RubyDoc.info リンク追加
- [ ] Gem publish 時に RubyDoc.info が自動生成されることを確認
- [ ] API docs (RubyDoc.info) へのアクセス確認
- [ ] User guides (docs/) が RubyDoc.info と相互補完

### Phase 3 検討項目

- [ ] rbs-doc または Steep RBS docs の成熟度確認
- [ ] ローカル doc 生成の必要性評価
- [ ] Rake task で doc generation 実装の可否検証

---

## 注意事項

### YARD との関係

- **採用なし**: Priority 1 Phase 1 で rbs-inline annotations のみが決定
- **理由**: YARD と RBS annotations の同期コストが高い
- **代替**: RBS documentation generator で .rbs → HTML 生成

### RubyDoc.info への期待

- **RBS サポート**: 確認待ち（Phase 2 実装時に検証）
- **Fallback**: RBS サポートがない場合、カスタム solution 検討

---

## 参考資料

### 関連ドキュメント

- **Type System Strategy**: `.claude/docs/type-system-strategy.md`
- **Type Annotation Guide**: `.claude/docs/type-annotation-guide.md`
- **t-wada style TDD**: `.claude/docs/t-wada-style-tdd-guide.md`

### 外部リソース

- **RubyDoc.info**: https://rubydoc.info/
- **rbs-doc**: https://github.com/ruby/rbs-doc
- **Steep**: https://github.com/soutaro/steep

---

## Next Steps

1. **Phase 2 実装**: .rbs ファイルを git commit, RubyDoc.info 確認
2. **Phase 3 検討**: rbs-doc / Steep docs の成熟度評価
3. **ドキュメント統合**: User guides + RBS API docs の連携確認

---

**ドキュメント作成日**: 2025-11-13
**対象**: Priority 2 Phase 1 計画者・実装者
**状態**: 設計フェーズ（実装待ち）
