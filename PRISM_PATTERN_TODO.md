# Prism::Pattern ワンライナー Skill 実装 - TODO

検証完了日：2025-11-08
ステータス：検証完了 → Skill 作成済み → 次フェーズへ

---

## 📋 このセッションで完了した内容

### ✅ 検証・分析

- [x] Prism 0.19.0（Ruby 3.3.6）基本動作確認
- [x] Prism::Pattern API 機能確認
- [x] grep vs Prism::Pattern 精度比較テスト
  - Precision: grep 25% → Prism::Pattern 100%
  - False positive: grep 75% → Prism::Pattern 0%
- [x] Fast gem との比較分析
- [x] Claude Code on Web 対応可否の調査（非対応確定）

### ✅ PoC 実装

- [x] /tmp/prism_search.rb（基本 CLI ツール）
- [x] /tmp/prism_block_puts_search_v4.rb（ブロック検索応用例）
- [x] テストコード・検証スクリプト群

### ✅ ドキュメント作成

- [x] 検証レポート（Feasibility Report）
- [x] grep vs Prism 詳細比較レポート
- [x] 実装戦略ドキュメント
- [x] Skill コンテンツ完成（/tmp/prism-search-skill-content.md）
- [x] Subagent 統合案（explore 更新用）

### ✅ Skill ファイル作成（Web版対応）

**このセッションで完了**

```
.claude/skills/prism-search/SKILL.md
```

内容：
- Prism::Pattern の基本ガイド
- パターン構文ガイド
- 基本的な使い方（5 パターン）
- 実用例（3 例）
- grep との精度比較
- よくある質問
- トラブルシューティング

---

## 📌 次のセッション（ローカル）で実施すること

### ローカル環境

- [ ] ~/.claude/agents/explore.md を更新
  - Prism::Pattern 精密探索セクション追加
  - パターン構文説明追加
  - 実装スクリプト呼び出し方法の説明
  - 参考：/tmp/explore-updated.md

### プロジェクトリポジトリ

- [ ] scripts/prism_search.rb を配置
  - 出典：/tmp/prism_search.rb

- [ ] scripts/prism_block_puts_search.rb を配置
  - 出典：/tmp/prism_block_puts_search_v4.rb

- [ ] 実行権限設定
  ```bash
  chmod +x scripts/prism_search.rb
  chmod +x scripts/prism_block_puts_search.rb
  ```

- [ ] README.md に記載（オプション）
  - Prism::Pattern セクション追加
  - 使用例掲載

---

## 📂 参考資料（/tmp に保存済み）

### 実装用

- `prism-search-skill-content.md` → .claude/skills/prism-search/SKILL.md
- `explore-updated.md` → 次セッションで explore.md に統合

### 検証レポート（参考）

- `GREP_VS_PRISM_COMPARISON_REPORT.md`
- `PRISM_PATTERN_FEASIBILITY_REPORT.md`
- `PRISM_PATTERN_IMPLEMENTATION_STRATEGY.md`

### PoC スクリプト

- `prism_search.rb`
- `prism_block_puts_search_v4.rb`
- `test_puts_patterns.rb`（テストコード）

---

## 🎯 検証結果まとめ

### 精度比較

**テスト：ブロック内の puts 検索**

| 指標 | grep | Prism::Pattern |
|-----|------|------------|
| Precision | 25% | **100%** |
| False positive | 75% | **0%** |
| コンテキスト情報 | なし | あり |
| 複雑パターン対応 | 不可 | **可能** |

### アーキテクチャ決定

**Subagent + Skill の組み合わせ**

- Web版：Skill（基本ガイダンス）
- ローカル：Subagent（explore 統合、自動実行）

### 外部依存

✅ **ゼロ**（Ruby 3.3+ 標準搭載 Prism のみ使用）

---

## ✨ 完成後の効果

✅ Ruby コード検索精度：4 倍向上（25% → 100%）
✅ Web ユーザーもローカルユーザーも利用可能
✅ 自動委譲で透過的な実行（ローカル）
✅ ブロック・メソッド・クラス正確分別可能
✅ false positive ゼロで信頼性向上

---

## 🚀 実装優先度

1. **高優先**：explore.md 統合（ローカル、実行自動化）
2. **中優先**：scripts/ 配置（両環境で利用可能化）
3. **低優先**：README 記載（ドキュメント強化）

---

## 📝 注記

- Skill ファイルは既に完成済み（.claude/skills/prism-search/SKILL.md）
- ローカル環境での実装は次セッション
- 参考資料は全て /tmp に保存済み

---

## 🎯 ワンライナー実装コマンド

**Skill と Subagent は ruby コマンドのワンライナーのみで完結。scripts/ は使用しない。**

### 📌 基本的なパターン検索（DefNode, ClassNode, CallNode など）

```bash
ruby -r prism -e '
pattern = ARGV.shift || "DefNode"
files = ARGV.empty? ? ["-"] : ARGV
files.each do |file|
  code = file == "-" ? $stdin.read : File.read(file)
  ast = Prism.parse(code)
  pattern_obj = Prism::Pattern.new(pattern)
  matches = pattern_obj.scan(ast)
  lines = code.lines
  matches.each do |node|
    line = node.location.start_line
    node_type = node.class.name.sub(/^Prism::/, "")
    name_info = node.respond_to?(:name) ? " [#{node.name}]" : ""
    puts "#{file}:#{line}: #{node_type}#{name_info}"
    puts "  #{lines[line - 1]&.strip}"
  end
  puts "[Found #{matches.count}] #{file}" unless matches.empty?
end
' DefNode lib/pra/commands/env.rb
```

### 📌 ブロック内の puts を検索

```bash
ruby -r prism -e '
filepath = ARGV[0] || $stdin.read
code = File.exist?(filepath) ? File.read(filepath) : filepath
ast = Prism.parse(code)
lines = code.lines

def collect_nodes(node, type = nil)
  nodes = []
  stack = [node]
  while stack.any?
    current = stack.shift
    nodes << current if type.nil? || current.is_a?(type)
    stack.concat(current.child_nodes.compact) if current.respond_to?(:child_nodes)
  end
  nodes
end

blocks = collect_nodes(ast, Prism::BlockNode)
found = 0
blocks.each do |block|
  body_nodes = collect_nodes(block.body)
  puts_calls = body_nodes.select { |n| n.is_a?(Prism::CallNode) && n.message == "puts" }
  next if puts_calls.empty?
  found += 1
  puts "【Block #{found}】 Line #{block.location.start_line}"
  puts_calls.each do |c|
    line_num = c.location.start_line
    puts "    - Line #{line_num}: #{lines[line_num - 1]&.strip}"
  end
end
puts "✅ Total: #{found} blocks with puts"
' target_file.rb
```

### 📌 特定のメソッドを検索

```bash
ruby -r prism -e '
pattern = ARGV.shift || "DefNode[name: :initialize]"
file = ARGV[0] || "-"
code = file == "-" ? $stdin.read : File.read(file)
ast = Prism.parse(code)
pattern_obj = Prism::Pattern.new(pattern)
matches = pattern_obj.scan(ast)
lines = code.lines
matches.each do |node|
  line = node.location.start_line
  puts "#{file}:#{line}: #{node.class.name.sub(/^Prism::/, "")} [#{node.name}]"
  puts "  #{lines[line - 1]&.strip}"
end
puts "[Found #{matches.count}]"
' "DefNode[name: :initialize]" app.rb
```

### 📌 stdin からの検索

```bash
cat file.rb | ruby -r prism -e '
pattern = ARGV[0] || "DefNode"
code = $stdin.read
ast = Prism.parse(code)
pattern_obj = Prism::Pattern.new(pattern)
matches = pattern_obj.scan(ast)
lines = code.lines
matches.each do |node|
  line = node.location.start_line
  puts "<stdin>:#{line}: #{node.class.name.sub(/^Prism::/, "")}"
  puts "  #{lines[line - 1]&.strip}"
end
' "DefNode"
```

---

## 🔄 Skill（Web版）での利用方法

`.claude/skills/prism-search/SKILL.md` では以下のような形式でユーザーにガイダンスを提供：

```
## 基本的な検索

\`\`\`bash
ruby -r prism -e '
pattern = ARGV.shift || "DefNode"
files = ARGV.empty? ? ["-"] : ARGV
# ... (上記のワンライナーコード)
' パターン ファイル
\`\`\`

例：
\`\`\`bash
ruby -r prism -e '...' DefNode lib/pra/commands/env.rb
\`\`\`
```

---

## 🤖 Subagent（ローカル）での実装

`~/.claude/agents/explore.md` の Prism::Pattern セクションでは：

- 上記のワンライナーコマンドを参考に
- Bash ツールで直接実行
- 結果を分析して詳細説明を提供
