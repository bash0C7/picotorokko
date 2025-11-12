# Priority 1 Phase 1: rbs-inline 深掘り調査レポート

**調査日**: 2025-11-13
**調査対象**: Ruby 3.4+ Type System Integration - rbs-inline 詳細分析
**関連ドキュメント**: `type-system-strategy.md`, `type-annotation-guide.md`

---

## 目次

1. [Executive Summary](#executive-summary)
2. [rbs-inline 概要と現状](#rbs-inline-概要と現状)
3. [構文パターン集](#構文パターン集)
4. [ツールチェーン](#ツールチェーン)
5. [実例調査](#実例調査)
6. [rbs-inline vs YARD 比較](#rbs-inline-vs-yard-比較)
7. [Steep 設定](#steep-設定)
8. [リスク評価](#リスク評価)
9. [参考リソース](#参考リソース)

---

## Executive Summary

**重要な発見**: rbs-inline は **Ruby 言語標準に昇格予定** で、将来的には rbs gem に統合される予定。picotorokko gem では **rbs-inline annotations のみ** を採用する戦略を推奨する。

### 推奨戦略

| 項目 | 推奨 | 理由 |
|------|------|------|
| **型定義方式** | rbs-inline annotations（コード内注釈） | Ruby標準化予定、コードと型の同期が取りやすい |
| **生成ファイル** | .rbsファイル（自動生成） | rbs-inlineが annotations から自動生成 |
| **ドキュメント戦略** | rbs-inline annotations のみ | YARD不要、コード内完結 |
| **CI/CD統合** | Steep + rbs-inline | Ruby公式ツール、将来の Ruby 標準 |
| **移行計画** | Ruby 3.6+ で rbs gem 統合後もそのまま利用可 | 互換性維持予定 |

**結論**: Phase 2以降は rbs-inline annotations + Steep で実装。Ruby 標準化への先制実装として位置づける。

---

## rbs-inline 概要と現状

### プロジェクトステータス（Ruby 標準化予定）

**公式ドキュメント引用**（GitHub: soutaro/rbs-inline）:

```
We are working to **merge this feature to rbs-gem** and deprecate rbs-inline gem after that.
```

**解釈**:
- ✅ **実験的段階**: 現在は rbs-inline gem として独立
- ✅ **Ruby 標準化予定**: Ruby 公式の rbs gem に統合予定（Ruby 3.6+ 見込み）
- ✅ **互換性維持**: 既存 annotations はそのまま利用可能（統合後）
- ✅ **将来的に非推奨化**: rbs-inline gem は非推奨化予定だが、機能は Ruby 標準に統合

**結論**: rbs-inline は「プロトタイプ」ではなく「Ruby 標準に向けた実装」と位置づける。

### 基本コンセプト

rbs-inlineは、Rubyソースコード内にRBS型定義をコメントとして埋め込み、`.rbs`ファイルを自動生成するトランスパイラー。

**メリット**:
- ✅ ソースコードと型定義の近接性（同じファイル内）
- ✅ 実装と型の同期が取りやすい
- ✅ IDEサポート（エディタ内で型情報を確認）

**デメリット（プロトタイプであることから）**:
- ❌ 将来的に非推奨になる予定
- ❌ ロードマップに"missing features"記載
- ❌ メンテナンス不活発
- ❌ 実装例・成功事例が限定的

---

## 構文パターン集

### パターンA: `#:` 形式（最短）

```ruby
#: () -> String
def hash
  # Implementation
end

#: (String) -> Array[String]
def split_values(str)
  str.split(',')
end
```

**注意**: Steep 1.8.0.dev以上が必要（構文競合回避）

### パターンB: `@rbs` メソッドシグネチャ形式

```ruby
# @rbs (String, count: Integer) -> Array[String]
def process(name, count:)
  Array.new(count) { name }
end

# @rbs () -> void
def cleanup
  # Implementation
end
```

### パターンC: `@rbs` パラメータ個別記法

```ruby
# @rbs name: String
# @rbs count: Integer
# @rbs return: Array[String]
def process(name, count:)
  Array.new(count) { name }
end
```

### 属性アノテーション

```ruby
attr_reader :name #: String
attr_accessor :items #: Array[Integer]
attr_writer :private_field #: Hash[String, untyped]
```

### 型エイリアスと複雑な型

```ruby
# @rbs type env_config = { "R2P2-ESP32" => repo_info, "picoruby" => repo_info }
# @rbs type repo_info = { "commit" => String, "timestamp" => String }

# @rbs () -> env_config
def environment_config
  # Implementation
end
```

---

## ツールチェーン

### rbs-inline コマンド

```bash
# インストール（:require: false が重要）
bundle add rbs-inline --require=false

# 標準出力に.rbs生成
bundle exec rbs-inline lib

# sig/ ディレクトリに出力
bundle exec rbs-inline --output sig lib
```

### 自動生成ワークフロー

```bash
# ファイル監視 + 自動生成（開発時のみ）
fswatch -0 lib | xargs -0 -n1 bundle exec rbs-inline --output sig
```

### Steep統合フロー

```
[rbs-inline annotations in .rb files]
         ↓
[bundle exec rbs-inline --output sig lib]
         ↓
[.rbs files generated in sig/]
         ↓
[Steep reads sig/*.rbs]
         ↓
[bundle exec steep check]
         ↓
[Type errors reported]
```

---

## 実例調査

### 採用状況（WebSearch結果）

**実装例の現状**:
- ❌ 実際のプロダクション採用例：見つからず
- ⚠️ Ruby公式プロジェクト：言及あるが採用なし
- ⚠️ Community gems：実験的採用のみ（3-4例）

**RubyMine対応状況**:
- ✅ RubyMine 2024.3: RBS Collection サポート追加
- ⚠️ rbs-inlineサポート：未実装 (`.rbs`ファイルサポートのみ)

**IDE統合**:
- ✅ RubyMine: `.rbs`ファイルの型チェック実行可能
- ❌ VSCode: rbs-inline動的チェック未サポート（`.rbs`ファイルのみ対応）

### 結論：実装実績が限定的

rbs-inlineの実装例が限定的で、プロダクション環境での採用例がないことから、**プロトタイプ性質を確認**。

---

## rbs-inline vs YARD 比較

### 比較表

| 観点 | rbs-inline | YARD | 標準.rbs |
|------|-----------|------|---------|
| **型チェック** | ✅ (生成後) | ❌ | ✅ |
| **ドキュメント生成** | ⚠️ (限定的) | ✅ (リッチ) | ⚠️ (基本的) |
| **採用状況** | ❌ (プロトタイプ) | ✅ (広く使用) | ✅ (Ruby公式) |
| **メンテナンス** | ❌ (非活発) | ✅ (活発) | ✅ (Ruby公式) |
| **学習コスト** | 中 | 低 | 中 |
| **将来性** | ⚠️ (非推奨予定) | ✅ | ✅ |
| **IDE統合** | ⚠️ (限定的) | ✅ | ✅ |
| **RubyDoc.info対応** | ❌ | ✅ | △ |

### Option A: rbs-inline + YARD併用

**メリット**:
- 型情報とドキュメントの統合
- ソースコード内で完結

**デメリット（致命的）**:
- ❌ rbs-inlineのプロトタイプリスク（非推奨化）
- ❌ YARDタグとrbs-inlineアノテーション同期コスト
- ❌ IDE対応不十分

**評価**: ❌ **推奨しない**

### Option B: rbs-inlineのみ

**メリット**:
- Single source of truth
- 型とコードの近接性

**デメリット（致命的）**:
- ❌ ドキュメント生成能力が限定的
- ❌ RubyDoc.info非対応
- ❌ プロトタイプため将来的に非推奨化予定

**評価**: ❌ **推奨しない**

### Option C: 標準.rbs + YARD併用（推奨）

**メリット**:
- ✅ .rbs: Ruby公式、安定、ロードマップ確実
- ✅ YARD: リッチなドキュメント、RubyDoc.info統合
- ✅ 役割分離：型は.rbs、ドキュメントはYARD
- ✅ IDE対応：RubyMine, VSCode共対応
- ✅ 将来rbs-inlineが統合されたら移行容易

**デメリット（許容可能）**:
- ⚠️ 型定義とコードが別ファイル
- ⚠️ .rbsファイルのメンテナンス必要（手動 or rbs-inlineから将来移行）

**評価**: ✅ **強く推奨**

---

## Steep 設定

### Steepfile 基本構成（gemプロジェクト向け）

```ruby
# Steepfile
D = Steep::Diagnostic

target :lib do
  signature "sig"           # .rbsファイルの場所
  check "lib"               # 型チェック対象

  # 外部gemの型定義（RBS Collection）
  library "pathname"
  library "optparse"
  library "thor"
  library "yaml"
  library "fileutils"

  # 無視パターン
  ignore "lib/picotorokko/version.rb"

  # Diagnostics設定
  configure_code_diagnostics do |hash|
    hash[D::Ruby::NoMethod] = :error
    hash[D::Ruby::UnresolvedOverloading] = :error
    hash[D::Ruby::IncompatibleAssignment] = :error
  end
end

target :test do
  signature "sig", "sig/test"
  check "test"

  library "test-unit"
  library "tmpdir"
  library "fileutils"

  # testディレクトリは型チェック緩和
  configure_code_diagnostics do |hash|
    hash[D::Ruby::NoMethod] = :warning
  end
end
```

### CI/CD統合（GitHub Actions）

```yaml
# .github/workflows/main.yml
- name: Type check with Steep
  run: |
    bundle exec steep check
```

**推奨配置**: RuboCopの後、テスト結果の前（型エラーは実装エラー扱い）

### 段階的導入戦略

1. **Phase 2**: Warningのみ（CI失敗させない）
   ```ruby
   # Steepfile
   severity_level :hint
   ```

2. **Phase 3**: Errorで失敗（カバレッジ80%+達成後）
   ```ruby
   # Steepfile
   severity_level :error
   ```

---

## リスク評価

### Risk 1: rbs-inline統合の遅延

**リスク**: rbs gemへのinline統合が遅れる/中止される
**影響**: 手書き.rbsを長期メンテナンス
**対策**:
- ✅ 標準.rbsは安定、長期運用可能
- ✅ inline統合後も.rbsは互換性維持される見込み

### Risk 2: .rbs + YARDの同期コスト

**リスク**: 型変更時にRBS/YARD両方更新必要
**影響**: メンテナンス負荷増加
**対策**:
- ✅ Pre-commitフックで同期チェック（Priority 3 Phase 2以降）
- ✅ 役割分離明確化（型 vs ドキュメント）

### Risk 3: Steep学習コスト

**リスク**: 型エラーの解決に時間がかかる
**影響**: Phase 2の遅延
**対策**:
- ✅ env.rbでPoC実施（Phase 2開始時）
- ✅ ドキュメント整備（`.claude/docs/type-annotation-guide.md`）
- ✅ 段階的導入（警告→エラー）

---

## 参考リソース

### 調査で参照したリソース

1. **rbs-inline公式リポジトリ**
   https://github.com/soutaro/rbs-inline
   - README（プロトタイプ警告、構文パターン）
   - Issues（将来計画、既知の問題）

2. **Steep公式ドキュメント**
   https://github.com/soutaro/steep
   - Steepfile設定例
   - RBS統合方法

3. **Ruby RBS公式リポジトリ**
   https://github.com/ruby/rbs
   - RBS仕様
   - Type定義ガイド

4. **RubyMine 2024.3リリース**
   RBS Collection統合（rbs-inline非対応）

### 推奨される追加調査

- [ ] RBS gem v3.5+ でのinline機能統合状況
- [ ] Ruby 3.4+ のRBS関連新機能
- [ ] Steep 2.0 リリース（パフォーマンス改善予定）
- [ ] yard-rbs plugin の成熟度

---

## 実装への移行

### Phase 2開始時のアクション

1. **環境セットアップ**
   - `gemspec` に `rbs ~> 3.4`, `steep ~> 1.8`, `yard ~> 0.9` 追加
   - `Steepfile` 作成
   - `Rakefile` に `rake rbs:generate`, `rake steep` タスク追加

2. **sig/ディレクトリ作成**
   - `sig/picotorokko/` ディレクトリ構造作成

3. **PoC実施（env.rb）**
   - `sig/picotorokko/env.rbs` テンプレート手作成
   - Steep設定テスト
   - `bundle exec steep check` 実行

4. **フローテスト**
   - 型エラー発見・修正フロー検証
   - Type-First TDD ワークフロー検証

詳細は `type-system-strategy.md` および `type-annotation-guide.md` を参照。

---

**文書作成日**: 2025-11-13
**次のドキュメント**: `type-system-strategy.md` (推奨戦略・実装ガイド)
