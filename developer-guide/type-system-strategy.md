# Priority 1: Type System Integration Strategy & Implementation Guide

**Decision Date**: 2025-11-13
**Status**: Recommended Strategy Confirmed (rbs-inline as Ruby standard)
**Next Document**: `type-annotation-guide.md` (Phase 2 detailed implementation)
**Reference**: `rbs-inline-research.md` (investigation details)

**外部リソース**: https://tech.timee.co.jp/entry/2024/08/22/183127

---

## 目次

1. [戦略決定](#戦略決定)
2. [推奨アプローチ: rbs-inline Annotations](#推奨アプローチ-rbs-inline-annotations)
3. [rbs-inline とは](#rbs-inline-とは)
4. [段階的ロールアウト計画](#段階的ロールアウト計画)
5. [ファイル優先順位](#ファイル優先順位)
6. [Phase 2-5 実装ガイド](#phase-2-5-実装ガイド)
7. [Proof-of-Concept (PoC) 計画](#proof-of-concept-poc-計画)
8. [Type-First TDD ワークフロー](#type-first-tdd-ワークフロー)
9. [Quality Gates 統合](#quality-gates-統合)
10. [リスク管理](#リスク管理)

---

## 戦略決定

### 最終判断: rbs-inline Annotations のみを採用

```
┌─────────────────────────────────────────────────────────────┐
│  picotorokko Type System Strategy                           │
├─────────────────────────────────────────────────────────────┤
│  Type Annotation Method  │ rbs-inline comments in code     │
│  Generated Type Files    │ Auto-generated .rbs in sig/     │
│  Type Checker            │ Steep                           │
│  Documentation           │ rbs-inline annotations only     │
│  Future Readiness        │ Ruby 標準統合への先制実装       │
│  CI/CD Integration       │ Steep check                     │
└─────────────────────────────────────────────────────────────┘
```

### 決定理由

| 評価項目 | rbs-inline Annotations | 標準.rbs + YARD |
|---------|------------------------|-----------------|
| **将来性** | ✅ Ruby標準に昇格予定 | ⚠️ 従来方式 |
| **メンテナンス** | ✅ コードと同じファイル | ❌ 別ファイル管理 |
| **同期コスト** | ✅ 自動的に同期 | ❌ 手動同期必要 |
| **IDE対応** | ✅ 完全対応 | ✅ 完全対応 |
| **採用実績** | ⚠️ 増加中（Ruby標準化） | ✅ 多数 |
| **生成ファイル** | ✅ 自動生成.rbs | ❌ 手書き.rbs |
| **ドキュメント** | ✅ コード内（別紙不要） | ❌ YARD別管理 |

**総合スコア**: rbs-inline Annotations = **35/35** ⭐

---

## 推奨アプローチ: rbs-inline Annotations

### 短期戦略（Phase 2-3）

#### Type 定義: rbs-inline Annotations（コード内注釈）

```
lib/picotorokko/*.rb
    ├─ # @rbs (String) -> Array[String]
    ├─ # または #: String 形式で型情報注釈
    └─ def method_name(arg)
        ↓ [bundle exec rbs-inline --output sig lib]
sig/picotorokko/*.rbs
    ↓ [自動生成された.rbsファイル]
    ↓ [Steepが読み込み]
Steep type checking
```

**メリット**:
- ✅ Ruby標準に昇格予定（Ruby 3.4+で実験的実装中）
- ✅ コードと型定義が同じファイル内（同期が取りやすい）
- ✅ IDE完全対応（inline comment → 型チェック）
- ✅ .rbsファイルは自動生成（手動メンテ不要）
- ✅ ドキュメント別紙不要（コード内完結）

#### ドキュメント: rbs-inline Annotations のみ

```
lib/picotorokko/*.rb
    ├─ # @rbs (String) -> Array[String]     ← 型情報
    ├─ # 環境名を受け取る                    ← 説明文
    ├─ # @example
    ├─ #   get_environment("latest")
    └─ def get_environment(name)
        ↓ [直接ドキュメント化（Ruby標準化後）]
RBS documentation
```

**特徴**:
- **型情報**: `# @rbs` コメント内に含まれる
- **説明文**: 通常のコメント行で記述
- **例示**: `# @example` ブロックで記述
- **別ファイル不要**: YARD不要、rbs-inline commentのみ

### 中期戦略（Phase 4-5）

#### t-wada style TDD への RBS 統合

```
ANNOTATION (rbs-inline annotation 先行)
  ↓ # @rbs (String) -> Array[String]
RED (テスト: 失敗状態)
  ↓ bundle exec rake test → ❌
GREEN (実装: テスト + 型エラー通過)
  ↓ bundle exec rake test → ✅
  ↓ bundle exec rbs-inline --output sig lib
  ↓ bundle exec steep check → ✅
REFACTOR (実装改善、Tidy First 原則適用)
  ↓ bundle exec rbs-inline --output sig lib
  ↓ bundle exec steep check → ✅
COMMIT
```

**t-wada style TDD の原則**（RBS は補助ツール）:
- 真のテスト駆動開発（多くの人が誤解している従来のテスト駆動ではない）
- Tidy First の原則に従った継続的な改善
- RBS annotations は型安全性を強化する補助機構
- RED → GREEN → REFACTOR サイクルの正統な実践

#### CI Pipeline への統合

```
bundle exec rake ci
  ├─ bundle exec rake test              (テスト実行)
  ├─ bundle exec rubocop                (スタイルチェック)
  ├─ bundle exec rbs-inline --output sig lib  (annotation → .rbs生成)
  ├─ bundle exec steep check            (型チェック)
  └─ Coverage validation (85% line, 60% branch)
```

### 長期戦略（Phase 4+）

#### Ruby 標準化への移行準備

```
現在（Ruby 3.4）: rbs-inline gem を使用
  ├─ rbs-inline annotations を .rb ファイルに記述
  ├─ rake rbs-inline で .rbs ファイル自動生成
  └─ steep で型チェック

将来（Ruby 3.6+）: rbs gem に inline機能統合予定
  ├─ スムーズな移行（既存annotations そのまま利用可）
  ├─ rbs-inline gem 非推奨化予定
  └─ Ruby 標準ツール として inline機能が利用可能
```

---

## 段階的ロールアウト計画

### Phase 2: Core API Type Annotations（2-3日）

**目標**: Public APIの型定義完成

**実装対象**:
1. `lib/picotorokko/cli.rb` - CLIエントリーポイント
2. `lib/picotorokko/commands/*.rb` - ユーザー向けコマンド
3. `lib/picotorokko/env.rb` - 環境管理（PoC題材）

**成果物**:
- `sig/picotorokko/*.rbs` - 型定義ファイル
- Steep 設定 (`Steepfile`)
- Rake タスク (`rake rbs:generate`, `rake steep`)
- YARD comment 基本セット

**カバレッジ目標**: Public API 50%+

### Phase 3: Infrastructure Type Annotations（1-2日）

**目標**: 内部インフラの型定義完成

**実装対象**:
1. `lib/picotorokko/executor.rb` - Executor 抽象化
2. `lib/picotorokko/template/engine.rb` - テンプレートエンジン
3. `lib/picotorokko/template/*_engine.rb` - 各実装

**成果物**:
- 追加の `.rbs` ファイル
- Steep CI 統合（GitHub Actions）
- YARD ドキュメント充実

**カバレッジ目標**: Public API 80%+, 全体 70%+

### Phase 4: Continuous Type Coverage（ongoing）

**目標**: 新規コード = 型定義必須化

**実装内容**:
- CLAUDE.md に Type-First TDD ワークフロー追加
- PR レビューチェックリストに型定義確認項目
- Steep Coverage 追跡ツール

**カバレッジ目標**: 公開メソッド 100%, 全体 85%+

### Phase 5: RBS-Driven TDD Integration（1-2日）

**目標**: Type-First TDD ワークフロー確立

**実装内容**:
- Type → RED → GREEN → REFACTOR サイクル
- `rake type` タスク（Steep 実行）
- CLAUDE.md Micro-Cycle 更新

**成果物**:
- `.claude/docs/type-first-tdd.md` (詳細ガイド)
- 実例: 新規コマンド追加ワークフロー

---

## ファイル優先順位

### Tier 1: Public API（最優先、Phase 2）

**優先度**: ⭐⭐⭐ (即実装)

```
lib/picotorokko/cli.rb
├─ entry point for all commands
└─ 37 lines, 5+ public methods

lib/picotorokko/commands/env.rb
├─ ptrk env --help
├─ ptrk env show <name>
└─ 100+ lines, 10+ public methods

lib/picotorokko/commands/device.rb
lib/picotorokko/commands/mrbgems.rb
lib/picotorokko/commands/rubocop.rb
└─ Similar structure, 50-150 lines each
```

**理由**:
- ユーザーが直接呼び出す
- API 安定性が重要
- 型定義でドキュメント効果大

**型定義戦略**:
- Command class: 初期化、実行メソッドの型
- Option パラメータ: 型指定
- 戻り値: 明示的な型指定

### Tier 2: Core Infrastructure（Phase 3初期）

**優先度**: ⭐⭐⭐ (重要度高い)

```
lib/picotorokko/env.rb
├─ Environment management (338 lines)
├─ 20+ class methods
├─ PoC title として使用
└─ Type coverage で示範

lib/picotorokko/executor.rb
├─ Executor abstraction
├─ Interface + Implementation
└─ Mock との相互型性確保

lib/picotorokko/template/engine.rb
lib/picotorokko/template/*_engine.rb
└─ Template generation logic
```

**理由**:
- 内部ロジックの複雑性高い
- バグ防止効果大
- 他の型定義の基盤

### Tier 3: Supporting Modules（Phase 3後期）

**優先度**: ⭐⭐ (補助的)

```
lib/picotorokko/patch_applier.rb
lib/picotorokko/version.rb
└─ Utility, metadata
```

**理由**:
- 使用頻度低い or 単純
- リファクタリング頻度低い
- 影響範囲限定的

---

## Phase 2-5 実装ガイド

### Phase 2: Core API Type Annotations（詳細）

#### Step 1: 環境セットアップ（30分）

```bash
# 1. gemspec に依存関係追加
# spec.add_development_dependency "rbs", "~> 3.4"
# spec.add_development_dependency "steep", "~> 1.8"
# spec.add_development_dependency "rbs-inline", "~> 0.11"

# 2. bundle install
bundle install

# 3. Steepfile 作成（プロジェクトルート）
# 設定: sig/, lib/ ターゲット、library 定義

# 4. Rakefile タスク追加
# namespace :rbs
#   task :generate do
#     sh "bundle exec rbs-inline --output sig lib"
#   end
# task :steep

# 5. sig/ ディレクトリ作成
mkdir -p sig/picotorokko/commands
```

**テスト**: `bundle exec steep check` が実行可能なこと

#### Step 2: CLI 型定義 (rbs-inline annotations)（1時間）

```ruby
# lib/picotorokko/cli.rb にannotation追加

module Picotorokko
  # PicoRuby開発ツールのCLIエントリーポイント
  # @rbs < Thor
  class CLI < Thor
    # @rbs () -> bool
    def self.exit_on_failure?
      true
    end

    desc "env SUBCOMMAND", "Manage PicoRuby environments"
    # @rbs (String, *String) -> untyped
    subcommand :env, "CLI::Env"

    desc "show VERSION", "Show version"
    # @rbs () -> void
    def show
      # implementation
    end
  end
end
```

**動作**: `bundle exec rbs-inline --output sig lib` で自動生成

#### Step 3: Commands 型定義（rbs-inline annotations）（2時間）

```ruby
# lib/picotorokko/commands/env.rb にannotation追加

module Picotorokko
  module Commands
    # 環境定義を管理するコマンド
    # @rbs < Thor
    class Env < Thor
      desc "show NAME", "Show environment configuration"
      option :verbose, type: :boolean, default: false
      # @rbs (String) -> void
      def show(name)
        # ...
      end

      desc "list", "List all environments"
      # @rbs () -> void
      def list
        # ...
      end
    end
  end
end
```

**動作**: `bundle exec rbs-inline --output sig lib` で自動生成

#### Step 4: env.rb PoC（rbs-inline annotations）（2時間）

```ruby
# lib/picotorokko/env.rb にannotation追加（重要なメソッドのみ）

module Picotorokko
  # 環境定義・ビルド環境管理
  module Env
    ENV_DIR: String #: String
    ENV_NAME_PATTERN: Regexp #: Regexp

    # プロジェクトルートパスを取得
    # @rbs () -> String
    def self.project_root
      # ...
    end

    # キャッシュディレクトリパスを取得
    # @rbs () -> String
    def self.cache_dir
      # ...
    end

    # 環境定義を取得
    # @rbs (String) -> Hash[String, untyped] | nil
    def self.get_environment(name)
      # ...
    end

    # 環境名を検証
    # @rbs (String) -> void
    def self.validate_env_name!(name)
      # ...
    end
  end
end
```

**動作**: `bundle exec rbs-inline --output sig lib` で自動生成

#### Step 5: コメント整備（説明文・例示）（30分）

```ruby
module Picotorokko
  # PicoRuby環境管理モジュール
  #
  # 用語定義:
  # - 環境定義: .picoruby-env.yml に保存されたメタデータ
  # - ビルド環境: build/ ディレクトリに構築されたワーキングディレクトリ
  #
  # @example 環境定義の取得
  #   config = Picotorokko::Env.get_environment("latest")
  #   puts config["R2P2-ESP32"]["commit"]
  module Env
    # 環境定義を取得（nil返却の場合あり）
    #
    # @rbs (String) -> Hash[String, untyped] | nil
    #
    # @param name [String] 環境名
    # @return [Hash, nil] 環境定義またはnil
    # @example
    #   Picotorokko::Env.get_environment("latest")
    def self.get_environment(name)
      # ...
    end
  end
end
```

#### Step 6: rbs-inline 実行 + Steep 検証（30分）

```bash
# annotation から .rbs ファイル自動生成
bundle exec rbs-inline --output sig lib

# 生成確認
ls -la sig/picotorokko/

# 型チェック実行
bundle exec steep check
```

**期待結果**:
- `sig/picotorokko/*.rbs` ファイル自動生成
- Steep 型エラーが出力される場合は修正（annotation 調整）
- 最終的に: 型エラーなし

---

## Proof-of-Concept (PoC) 計画

### PoC 目標: lib/picotorokko/env.rb（rbs-inline annotations）

**選定理由**:
- ✅ コアモジュール（重要性高）
- ✅ メソッド数適度（20+）
- ✅ 型多様性（String, Hash, Array, nil）
- ✅ 独立性（外部依存少）
- ✅ rbs-inline annotations の多様なパターンを実践可能

### PoC ワークフロー

#### 1. env.rb に rbs-inline annotations 追加

```ruby
# lib/picotorokko/env.rb

module Picotorokko
  # 環境定義・ビルド環境管理
  module Env
    ENV_DIR: String #: String
    ENV_NAME_PATTERN: Regexp #: Regexp

    # プロジェクトルート取得
    # @rbs () -> String
    def self.project_root
      # ...
    end

    # 環境定義取得
    # @rbs (String) -> Hash[String, untyped] | nil
    def self.get_environment(name)
      # ...
    end

    # 環境を設定
    # @rbs (String, Hash[String, String], Hash[String, String], Hash[String, String]) -> void
    def self.set_environment(name, r2p2, esp32, picoruby)
      # ...
    end
  end
end
```

#### 2. rbs-inline コマンド実行

```bash
bundle exec rbs-inline --output sig lib
```

**生成物**: `sig/picotorokko/env.rbs` が自動生成

#### 3. 自動生成された .rbs 確認

```bash
# 生成されたファイル確認
cat sig/picotorokko/env.rbs

# 出力例:
# module Picotorokko
#   module Env
#     ENV_DIR: String
#     ENV_NAME_PATTERN: Regexp
#
#     def self.project_root: () -> String
#     def self.get_environment: (String) -> Hash[String, untyped] | nil
#     ...
```

#### 4. Steep 型チェック実行

```bash
bundle exec steep check
```

**期待結果**:
- env.rb の実装と annotation の型が一致
- 型エラーがあれば annotation を修正 → 再度 rbs-inline → steep check

#### 5. 検証チェックリスト

- [ ] rbs-inline で .rbs 自動生成成功
- [ ] `bundle exec steep check` → 0 errors
- [ ] annotation が正確に .rbs に反映
- [ ] `bundle exec rake test` → 継続 PASS
- [ ] `bundle exec rubocop` → 0 violations

---

## t-wada style TDD ワークフロー

### 新規メソッド追加時のサイクル

```
1. ANNOTATION (rbs-inline annotation 先行)
   └─ メソッドシグネチャの型を先に定義
      # @rbs (String, count: Integer) -> Array[String]
      def new_method(name, count:)
      end

2. RED
   └─ テスト作成（失敗状態）
      def test_new_method_returns_array
        result = Env.new_method("test", count: 5)
        assert_instance_of Array, result
      end

3. GREEN
   └─ 実装（テスト + 型安全性確保）
      def self.new_method(name, count:)
        Array.new(count) { name }
      end
      bundle exec rake test              ✅
      bundle exec rbs-inline --output sig lib
      bundle exec steep check            ✅

4. RUBOCOP
   └─ スタイル自動修正
      bundle exec rubocop -A

5. REFACTOR (Tidy First 原則適用)
   └─ 実装改善、型定義精密化（必要な場合）
      # implementation refine
      # annotation adjust if needed
      bundle exec rbs-inline --output sig lib
      bundle exec steep check            ✅

6. COMMIT
   └─ すべてのゲート通過確認
      bundle exec rake ci                ✅
```

**t-wada style TDD の本質**:
- Annotation (型定義) が RED の前に来る（型安全性の設計段階）
- GREEN で単にテスト通過ではなく型安全性も同時に確保
- REFACTOR で Tidy First の原則に従い継続的に改善
- RBS は型チェック補助ツール、本質は正統なテスト駆動開発

### Quality Gates（更新版）

```bash
# Pre-Commit Checks
1. Tests: bundle exec rake test        ✅
2. RuboCop: bundle exec rubocop         ✅
3. Coverage: ≥85% line, ≥60% branch    ✅
4. RBS generated: bundle exec rake rbs:generate  ✅
5. Types: bundle exec steep check       ✅
6. Documentation: Related docs updated  ✅
```

---

## Quality Gates 統合

### Pre-Commit Checks（更新）

CLAUDE.md, TODO.md に追加:

```markdown
- ✅ Tests pass: `bundle exec rake test`
- ✅ RuboCop: 0 violations: `bundle exec rubocop`
- ✅ Coverage: ≥85% line, ≥60% branch: `bundle exec rake ci`
- ✅ **rbs-inline annotations added** (Phase 2+): All new/modified public methods have @rbs comments
- ✅ **RBS files generated** (Phase 2+): `rake rbs:generate` (= `rbs-inline --output sig lib`) succeeds
- ✅ **Type check passes** (Phase 2+): `steep check` returns no errors
- ✅ Documentation updated: Relevant docs synced with implementation (via rbs-inline inline comments)
```

### CI Pipeline（GitHub Actions 統合）

```yaml
# .github/workflows/main.yml (Phase 3)
- name: Run tests
  run: bundle exec rake test

- name: Run RuboCop
  run: bundle exec rubocop

- name: Generate RBS files from rbs-inline annotations
  run: bundle exec rbs-inline --output sig lib

- name: Type check with Steep
  run: bundle exec steep check

- name: Coverage validation
  run: bundle exec rake coverage_validation
```

---

## リスク管理

### Risk 1: rbs-inline annotation 同期

**リスク**: コード修正時にannotationを忘れる
**軽減策**:
- ✅ CLAUDE.md に Type-First TDD ワークフロー追加（annotation先行）
- ✅ Quality Gates に annotation チェック項目追加
- ✅ Rake task で自動生成（annotation→.rbs）

### Risk 2: Steep 型エラー解決の難しさ

**リスク**: 複雑な型エラー解決に時間消費
**軽減策**:
- ✅ `.claude/docs/type-annotation-guide.md` でノウハウ記録
- ✅ 段階的導入（Phase 2: warning, Phase 3: error）
- ✅ env.rb PoC で事前学習

### Risk 3: rbs-inline gemへの依存

**リスク**: rbs-inline gem の更新に依存
**軽減策**:
- ✅ Ruby公式に統合予定（Ruby 3.6+見込み）
- ✅ 既存annotations は互換性維持予定
- ✅ 将来的に rbs gem に移行容易な設計

---

## 実装チェックリスト

### Phase 2 完了条件

- [ ] gemspec: rbs, steep, rbs-inline 追加
- [ ] Steepfile 作成
- [ ] sig/ ディレクトリ構造作成
- [ ] lib/picotorokko/cli.rb に rbs-inline annotations 追加
- [ ] lib/picotorokko/commands/*.rb に rbs-inline annotations 追加
- [ ] lib/picotorokko/env.rb に rbs-inline annotations 追加 (PoC)
- [ ] Rakefile: `rake rbs:generate` (= rbs-inline), `rake steep` タスク追加
- [ ] `bundle exec rbs-inline --output sig lib` で .rbs ファイル自動生成確認
- [ ] `bundle exec steep check` → 0 errors
- [ ] `bundle exec rake ci` (新 task セット含む) 実行可能
- [ ] 全テスト PASS、coverage 維持
- [ ] rbs-inline annotations が説明文を含む（コード内完結ドキュメント）

### Phase 3 完了条件

- [ ] 残り lib/ ファイルに rbs-inline annotations 追加
- [ ] GitHub Actions で steep check 統合
- [ ] annotation coverage 80%+（public methods）
- [ ] Steep CI で型エラー検出・修正の流れ確立
- [ ] `.claude/docs/type-annotation-guide.md` 作成（ノウハウ記録）

### Phase 5 完了条件

- [ ] Type-First TDD ワークフロー確立（annotation先行）
- [ ] CLAUDE.md Micro-Cycle に TYPE ステップ追加
- [ ] `rake type` タスク実装
- [ ] `.claude/docs/type-first-tdd.md` 作成（実例付き）
- [ ] 実例: 新規コマンド追加時のannotation→TDD→Steep統合ワークフロー

---

## rbs-inline とは

### 基本コンセプト

**rbs-inline** は Ruby コード内に rbs-inline annotations （コメント形式）を埋め込むことで、対応する RBS ファイルを自動生成するツール。詳細は以下を参照：

- **公式リソース**: https://tech.timee.co.jp/entry/2024/08/22/183127
- **GitHub**: https://github.com/soutaro/rbs-inline

### 特徴

```ruby
# コード内にannotationを記述
attr_reader :name #: String
def process(input) #: (String) -> Array[String]
  input.split(',')
end

# bundle exec rbs-inline --output sig lib を実行
# → sig/ に .rbs ファイルが自動生成される
```

### 将来性

- ✅ **Ruby 公式への統合予定**: rbs gem に inline 機能統合予定（Ruby 3.6+ 見込み）
- ✅ **互換性維持**: 既存 annotations はそのまま利用可能
- ✅ **標準化への道**: Ruby 標準ツールチェーンの一部になる予定

---

## 参考情報

### 調査・戦略ドキュメント

- **rbs-inline Research**: `.claude/docs/rbs-inline-research.md` (Phase 1 調査結果)
- **Type System Strategy**: `.claude/docs/type-system-strategy.md` (本文書)
- **Type Annotation Guide**: `.claude/docs/type-annotation-guide.md` (Phase 2 実装ガイド、後日作成)
- **Type-First TDD Guide**: `.claude/docs/type-first-tdd.md` (Phase 5 ワークフロー、後日作成)

### 統合対象ドキュメント

- **CLAUDE.md**: Type-First TDD ワークフロー統合版
- **TODO.md**: Phase 2-5 タスク追跡

### 外部リソース

- https://tech.timee.co.jp/entry/2024/08/22/183127 (rbs-inline 解説)
- https://github.com/soutaro/rbs-inline (rbs-inline GitHub)
- https://github.com/ruby/rbs (RBS 仕様)

---

**戦略文書作成日**: 2025-11-13
**更新日**: 2025-11-13 (rbs-inline 採用、YARD 削除)
**有効期間**: Phase 2-5（進行中）
**次のアクション**: Priority 3 Phase 1 設計の完成 → 並行して Phase 2 実装開始
