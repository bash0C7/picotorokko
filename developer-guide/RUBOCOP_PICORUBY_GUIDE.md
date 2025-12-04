# PicoRuby RuboCop Custom Cop Implementation Guide

> **For**: **ptrk gem developers** implementing RuboCop Cop infrastructure
>
> **Not for**: PicoRuby application developers (use `ptrk rubocop setup` instead)
>
> **Goal**: Automatically detect unsupported PicoRuby methods via custom RuboCop Cops deployed by `ptrk rubocop setup`

---

# 完全実装計画

> **このドキュメント**: PicoRuby 用 RuboCop カスタム Cop テンプレート実装の完全ガイド
>
> **参照元**: `TODO.md` の "PicoRuby RuboCop Configuration Template" タスク

---

## 📌 背景・目的

### 問題の定義

PicoRuby アプリケーション開発者が生成した Ruby スクリプトに対して、**CRuby には存在するが PicoRuby では使えない標準クラス・メソッドが混在する可能性がある**。

例：
```ruby
# CRuby では OK、PicoRuby では NG
str = "hello"
str.downcase!          # ❌ 破壊的メソッドは未実装
str.unicode_normalize  # ❌ 未実装
arr = [1, 2, 2, 3]
arr.combination(2)     # ❌ Enumerable メソッド未実装
```

### 解決する価値

RuboCop のカスタム Cop により、開発時に**警告レベル**で不適切なメソッド使用を指摘。エラーではなく警告なので、開発者は必要に応じて抑制コメント（`# rubocop:disable PicoRuby/UnsupportedMethod`）で除外できる。

### ptrk gem の役割

**ptrk gem は「テンプレート提供者」として機能**：
- ❌ データファイルを同梱しない（バージョン管理が複雑）
- ✅ データ抽出スクリプト（Ruby スクリプト）を提供
- ✅ ユーザーが必要に応じて `ptrk rubocop update` でデータ生成
- ✅ 常に最新の PicoRuby 定義を取得可能

---

## 🔍 調査結果サマリー

### 1. picoruby.github.io の構造

**リポジトリ**: https://github.com/picoruby/picoruby.github.io

**ドキュメント生成パイプライン**:
```
picoruby/mrbgems/*/sig/*.rbs (RBS型定義ファイル)
                    ↓
                Steep + RBS 解析
                    ↓
            RBSDoc Generator
                    ↓
pages/rbs_doc/*.md (Markdown ドキュメント)
```

**実態**:
- 204個の `.md` ファイル（クラス/モジュールドキュメント）
- パス: `pages/rbs_doc/Array.md`, `pages/rbs_doc/String.md` など
- フォーマット: YAML フロントマター + Markdown セクション

**Markdown フォーマット例** (Array.md):
```markdown
---
title: class Array
keywords: Array
tags: [class]
summary: Array class of PicoRuby
sidebar: picoruby_sidebar
permalink: Array.html
folder: rbs_doc
---

## Type aliases
（型エイリアス定義）

## Singleton methods
### new
```ruby
Array.new(?Integer capacity) -> instance
Array[element0, element1, ...] -> instance
```

## Instance methods
### each
```ruby
instance.each() -> self
instance.each() { |element| ... } -> self
```

### map
```ruby
instance.map() -> Enumerator
instance.map() { |element| ... } -> [result0, result1, ...]
```
```

**抽出対象**:
- クラス名（H1 `# class ClassName`）
- セクション（H2 `## Instance methods`, `## Singleton methods`）
- メソッド名（H3 `### method_name`）
- メソッドシグネチャ（Ruby コードブロック）

### 2. CRuby メソッド抽出方法（検証済み）

**全コアクラスメソッド取得コマンド**:

```bash
ruby -e "
require 'json'
core_classes = %w[Array String Hash Integer Float Symbol Regexp Range Enumerable Kernel]
result = core_classes.map do |name|
  begin
    klass = Object.const_get(name)
    {
      name => {
        instance_methods: klass.instance_methods(false).sort.map(&:to_s),
        class_methods: (klass.methods - Class.methods).sort.map(&:to_s)
      }
    }
  rescue => e
    puts \"Error: #{name} - #{e.message}\"
    {}
  end
end.inject(&:merge)
puts JSON.pretty_generate(result)
"
```

**出力フォーマット**:
```json
{
  "Array": {
    "instance_methods": ["&", "*", "+", "-", "<<", "all?", "any?", "append", ..., "zip"],
    "class_methods": ["[]", "try_convert"]
  },
  "String": {
    "instance_methods": ["%", "*", "+", "<<", "<=>", "==", "===", "=~", "[]", ..., "zip"],
    "class_methods": ["try_convert"]
  }
}
```

**重要**: `instance_methods(false)` で**クラス固有**のメソッドのみ抽出（継承メソッド除外）。

### 3. RuboCop カスタム Cop の実装パターン

#### AST（Abstract Syntax Tree）ノードマッチャー

RuboCop では **Parser gem** が生成する AST に対してパターンマッチングを行う。

**基本構文**:
```ruby
def_node_matcher :pattern_name, <<~PATTERN
  (node_type
    child1
    child2)
PATTERN
```

**例: メソッド呼び出しのマッチング**

```ruby
# コード例
[1, 2, 3].upcase

# AST表現
(send
  (array
    (int 1)
    (int 2)
    (int 3))
  :upcase)
```

```ruby
# パターン定義
def_node_matcher :array_method_call?, <<~PATTERN
  (send (array ...) $_ ...)
PATTERN
```

**キャプチャ構文**:
- `$_` - 単一要素をキャプチャ
- `$...` - 可変長配列をキャプチャ
- `${:method1 :method2}` - いずれかの値にマッチしてキャプチャ

#### Cop の基本構造

```ruby
module RuboCop
  module Cop
    module PicoRuby
      class UnsupportedMethod < Base
        # メッセージテンプレート
        MSG = "Method `%{class}#%{method}` may not be supported in PicoRuby"

        # 重要度レベル（convention, warning, error）
        # Base クラスの Severity デフォルトは convention
        severity :warning

        # パフォーマンス最適化: 特定メソッドのみチェック
        RESTRICT_ON_SEND = %i[upcase downcase gsub unicode_normalize].freeze

        # ノード訪問メソッド
        def on_send(node)
          # ノード処理ロジック
        end
      end
    end
  end
end
```

**オンハンド（on_XXX メソッド）一覧**:
- `on_send` - メソッド呼び出し
- `on_const` - 定数参照
- `on_ivar` - インスタンス変数
- `on_str` - 文字列リテラル
- `on_array` - 配列リテラル

### 4. ptrk gem のテンプレート機構

#### 既存パターン: `ptrk ci setup`

**実装**: `lib/pra/commands/ci.rb` (23-46行)

```ruby
def setup
  source = File.join(GEM_DIR, 'templates', 'docs', 'github-actions', 'esp32-build.yml')
  target = File.join(Dir.pwd, '.github', 'workflows', 'esp32-build.yml')

  if File.exist?(target)
    return unless yes?("Overwrite #{target}? (y/N)")
  end

  FileUtils.mkdir_p(File.dirname(target))
  FileUtils.cp(source, target)
  puts "✅ CI workflow configured at #{target}"
end
```

**特徴**:
- 静的ファイル（ERB でない）をコピー
- 上書き確認プロンプト（interactive）
- シンプルで理解しやすい

#### テンプレートディレクトリ構造

```
lib/pra/templates/
├── mrbgem_app/        # mrbgem 生成用（ERB テンプレート）
└── ci/                # CI テンプレート（静的ファイル）
    └── esp32-build.yml
```

**PicoRuby RuboCop テンプレートも同じパターン採用**:
```
lib/pra/templates/
├── mrbgem_app/
├── ci/
└── rubocop/           # 新規追加
    ├── .rubocop.yml
    ├── lib/rubocop/cop/picoruby/unsupported_method.rb
    ├── scripts/update_methods.rb
    ├── data/README.md
    └── README.md
```

---

## 💡 責務の明確化

### ptrk gem の責務 ✅

1. **データ抽出スクリプト提供** (`scripts/update_methods.rb`)
   - picoruby.github.io クローン/pull
   - RBS doc パース
   - CRuby メソッド抽出
   - 差分計算
   - JSON 出力

2. **カスタム Cop 実装** (`lib/rubocop/cop/picoruby/unsupported_method.rb`)
   - AST ノードパターンマッチング
   - メソッド検出ロジック
   - 警告メッセージ生成

3. **RuboCop 設定テンプレート** (`.rubocop.yml`)
   - Cop 有効化
   - 重要度レベル設定

4. **ptrk コマンド提供**
   - `ptrk rubocop setup` - テンプレート配置
   - `ptrk rubocop update` - ユーザー環境でスクリプト実行

### ユーザーの責務 🎯

1. **初回セットアップ**
   ```bash
   ptrk rubocop setup
   ```
   → テンプレートがプロジェクトに配置される

2. **データベース生成**
   ```bash
   ptrk rubocop update
   ```
   → ユーザー環境で最新 PicoRuby 定義を取得・処理

3. **RuboCop 実行**
   ```bash
   bundle exec rubocop
   ```
   → 静的解析実行、警告表示

**メリット**: PicoRuby がアップデートされたら、ユーザーは単に `ptrk rubocop update` を再実行すれば最新の定義を取得可能。gem バージョンアップ不要。

---

## 🏗️ アーキテクチャ設計

### ディレクトリ構造（全体）

```
`ptrk-gem/                                   # ptrk gem ルート
├── lib/
│   ├── pra/
│   │   ├── commands/
│   │   │   ├── ci.rb              # 既存
│   │   │   ├── build.rb           # 既存
│   │   │   ├── ...
│   │   │   └── rubocop.rb         # 新規作成
│   │   └── templates/
│   │       ├── mrbgem_app/        # 既存
│   │       ├── ci/                # 既存
│   │       └── rubocop/           # 新規ディレクトリ
│   │           ├── .rubocop.yml
│   │           ├── lib/
│   │           │   └── rubocop/
│   │           │       └── cop/
│   │           │           └── picoruby/
│   │           │               └── unsupported_method.rb
│   │           ├── scripts/
│   │           │   └── update_methods.rb
│   │           ├── data/
│   │           │   └── README.md
│   │           └── README.md
│   └── tasks/
│       └── rubocop_template.rake  # 新規作成（オプション）
├── test/
│   └── pra/
│       └── commands/
│           ├── ci_test.rb         # 既存
│           └── rubocop_test.rb    # 新規作成
└── TODO_rubocop_picoruby.md        # このファイル

ユーザープロジェクト（ptrk rubocop setup 実行後）：
my-picoruby-project/
├── .rubocop.yml
├── lib/
│   └── rubocop/
│       └── cop/
│           └── picoruby/
│               └── unsupported_method.rb
├── scripts/
│   └── update_methods.rb
├── data/                           # 初期は空（README.mdのみ）
│   └── README.md
├── README.md                       # セットアップガイド
└── app.rb                          # ユーザーのコード
```

### データフロー

```
                      [picoruby.github.io]
                              ↓
                      (git clone/pull)
                              ↓
        [scripts/update_methods.rb]
               ↙              ↘
        (RBS doc パース)   (CRuby メソッド取得)
             ↓                   ↓
    [picoruby_supported_    [cruby_core_
     methods.json]           methods.json]
             ↘              ↙
              (差分計算)
                 ↓
    [picoruby_unsupported_
      methods.json]
                 ↓
    [unsupported_method.rb]
      (Cop がロード)
                 ↓
    [bundle exec rubocop]
      (メソッド検出・警告表示)
```

---

## 📋 実装ステップ詳細

### Phase 1: データ抽出スクリプト実装

#### 1.1 ディレクトリ作成

```bash
mkdir -p lib/pra/templates/rubocop/{lib/rubocop/cop/picoruby,scripts,data}
```

#### 1.2 スクリプト実装

**ファイル**: `lib/pra/templates/rubocop/scripts/update_methods.rb`

```ruby
#!/usr/bin/env ruby
# PicoRuby method database updater
# Usage: ruby scripts/update_methods.rb
# Generates data/picoruby_supported_methods.json and data/picoruby_unsupported_methods.json

require 'json'
require 'fileutils'
require 'tmpdir'

class MethodDatabaseUpdater
  # Configuration
  PICORUBY_REPO = 'https://github.com/picoruby/picoruby.github.io.git'.freeze
  WORK_DIR_NAME = 'picoruby_github_io_tmp'.freeze
  SCRIPT_DIR = File.expand_path(__dir__)
  TEMPLATE_DIR = File.expand_path('..', SCRIPT_DIR)
  DATA_DIR = File.join(TEMPLATE_DIR, 'data')

  # Core classes to analyze
  CORE_CLASSES = %w[
    Array String Hash Integer Float Symbol Regexp Range
    Enumerable Numeric Kernel File Dir
  ].freeze

  def initialize
    @work_dir = File.join(Dir.tmpdir, WORK_DIR_NAME)
  end

  def run
    puts "🚀 Starting PicoRuby method database update..."

    begin
      clone_or_pull_repo
      picoruby_methods = extract_picoruby_methods
      cruby_methods = extract_cruby_methods
      unsupported = calculate_unsupported(cruby_methods, picoruby_methods)

      save_data(picoruby_methods, unsupported)
      display_summary(picoruby_methods, unsupported)

      puts "✅ Database update completed successfully!"
    rescue => e
      puts "❌ Error: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  private

  # ========== Repository Management ==========

  def clone_or_pull_repo
    if Dir.exist?(@work_dir)
      puts "📦 Repository already cloned. Pulling latest changes..."
      Dir.chdir(@work_dir) do
        result = system('git pull origin main 2>/dev/null')
        raise "Failed to pull repository" unless result
      end
    else
      puts "📥 Cloning picoruby.github.io repository..."
      FileUtils.mkdir_p(File.dirname(@work_dir))
      cmd = "git clone #{PICORUBY_REPO} #{@work_dir}"
      result = system("#{cmd} 2>/dev/null")
      raise "Failed to clone repository" unless result
    end
  end

  # ========== Data Extraction ==========

  def extract_picoruby_methods
    puts "🔍 Extracting PicoRuby methods from RBS documentation..."

    rbs_doc_dir = File.join(@work_dir, 'pages', 'rbs_doc')
    raise "RBS doc directory not found at #{rbs_doc_dir}" unless Dir.exist?(rbs_doc_dir)

    methods = {}

    Dir.glob(File.join(rbs_doc_dir, '*.md')).each do |file|
      class_name = File.basename(file, '.md')

      # Extract methods from this file
      file_methods = parse_rbs_doc(file, class_name)
      methods[class_name] = file_methods if file_methods.any?
    end

    methods
  end

  def parse_rbs_doc(file, class_name)
    content = File.read(file)
    methods = { instance: [], class: [], includes: [] }

    # Extract section headings and method signatures
    current_section = nil
    in_code_block = false

    content.each_line do |line|
      # Detect sections
      if line =~ /^## (Singleton methods|Instance methods|Attr accessors|Include)/
        current_section = $1.downcase.gsub(' ', '_').to_sym
        next
      end

      # Detect method names (H3 headings)
      if line =~ /^### (\w+)/
        method_name = $1
        case current_section
        when :singleton_methods
          methods[:class] << method_name unless methods[:class].include?(method_name)
        when :instance_methods
          methods[:instance] << method_name unless methods[:instance].include?(method_name)
        when :attr_accessors
          # Attr accessors are also instance methods
          methods[:instance] << method_name unless methods[:instance].include?(method_name)
        when :include
          methods[:includes] << method_name unless methods[:includes].include?(method_name)
        end
      end
    end

    methods
  end

  def extract_cruby_methods
    puts "🔍 Extracting CRuby core class methods..."

    methods = {}

    CORE_CLASSES.each do |class_name|
      begin
        klass = Object.const_get(class_name)
        methods[class_name] = {
          instance: klass.instance_methods(false).sort.map(&:to_s),
          class: (klass.methods - Class.methods).sort.map(&:to_s)
        }
      rescue NameError => e
        puts "⚠️  Warning: Could not load #{class_name} - #{e.message}"
      end
    end

    methods
  end

  # ========== Data Processing ==========

  def calculate_unsupported(cruby_methods, picoruby_methods)
    puts "📊 Calculating unsupported methods..."

    unsupported = {}

    cruby_methods.each do |class_name, cruby_data|
      picoruby_data = picoruby_methods[class_name] || { instance: [], class: [] }

      unsupported_instance = cruby_data[:instance] - picoruby_data[:instance]
      unsupported_class = cruby_data[:class] - picoruby_data[:class]

      if unsupported_instance.any? || unsupported_class.any?
        unsupported[class_name] = {
          instance: unsupported_instance,
          class: unsupported_class
        }
      end
    end

    unsupported
  end

  # ========== File Output ==========

  def save_data(picoruby_methods, unsupported)
    FileUtils.mkdir_p(DATA_DIR)

    # Save supported methods
    supported_path = File.join(DATA_DIR, 'picoruby_supported_methods.json')
    File.write(supported_path, JSON.pretty_generate(picoruby_methods))
    puts "💾 Saved: #{supported_path}"

    # Save unsupported methods
    unsupported_path = File.join(DATA_DIR, 'picoruby_unsupported_methods.json')
    File.write(unsupported_path, JSON.pretty_generate(unsupported))
    puts "💾 Saved: #{unsupported_path}"
  end

  def display_summary(picoruby_methods, unsupported)
    puts "\n📈 Summary:"
    total_supported = picoruby_methods.values.sum { |h| h[:instance].size + h[:class].size }
    total_unsupported = unsupported.values.sum { |h| h[:instance].size + h[:class].size }

    puts "  ✅ Supported: #{total_supported} methods across #{picoruby_methods.size} classes"
    puts "  ⚠️  Unsupported: #{total_unsupported} methods"
  end
end

# Run if executed directly
MethodDatabaseUpdater.new.run if __FILE__ == $0
```

**重要ポイント**:
- `instance_methods(false)` で継承メソッド除外
- RBS doc パースは `^### method_name` で識別
- tmpdir に git clone → 本番データは汚さない
- 依存: `git` コマンド（スクリプト内で呼び出し）

#### 1.3 初期データファイル

**ファイル**: `lib/pra/templates/rubocop/data/README.md`

```markdown
# PicoRuby Method Database

This directory contains JSON files with method support information for PicoRuby.

## Initial Setup Required

The JSON data files (`picoruby_supported_methods.json`, `picoruby_unsupported_methods.json`)
are **not included** by default to keep the template lightweight and ensure you always have
the latest PicoRuby method definitions.

**Generate the database:**

```bash
ptrk rubocop update
```

Or manually:

```bash
ruby scripts/update_methods.rb
```

## File Structure

### picoruby_supported_methods.json
Methods that are available in PicoRuby. Example:

```json
{
  "Array": {
    "instance": ["each", "map", "select", "size", "[]", "[]=", ...],
    "class": ["new", "[]"]
  },
  "String": {
    "instance": ["upcase", "downcase", "size", ...],
    "class": ["new"]
  }
}
```

### picoruby_unsupported_methods.json
Methods available in CRuby but NOT in PicoRuby. Used by RuboCop Cop:

```json
{
  "Array": {
    "instance": ["combination", "permutation", "repeated_permutation", ...],
    "class": []
  },
  "String": {
    "instance": ["unicode_normalize", "encode", "gsub!", ...],
    "class": []
  }
}
```

## Updating the Database

When PicoRuby is updated or you want to refresh the method list:

```bash
ptrk rubocop update
```

This will:
1. Clone/pull the latest picoruby.github.io
2. Extract method definitions from RBS documentation
3. Compare with CRuby methods
4. Regenerate the JSON files
```

### Phase 2: カスタム Cop 実装

#### 2.1 Cop コード実装

**ファイル**: `lib/pra/templates/rubocop/lib/rubocop/cop/picoruby/unsupported_method.rb`

```ruby
# frozen_string_literal: true

module RuboCop
  module Cop
    module PicoRuby
      # Detects methods that are not supported in PicoRuby
      #
      # CRuby has many methods that PicoRuby doesn't implement due to memory
      # constraints. This cop warns when unsupported methods are used on core
      # class instances.
      #
      # @example
      #   # bad
      #   str = "hello"
      #   str.unicode_normalize  # Not supported in PicoRuby
      #   str.gsub!(/l/, 'L')    # In-place methods often not supported
      #
      #   arr = [1, 2, 2, 3]
      #   arr.combination(2)     # Enumerable methods may not be fully implemented
      #
      #   # good
      #   str = "hello"
      #   str.upcase             # Supported method
      #   str.size               # Supported method
      #
      #   arr = [1, 2, 3]
      #   arr.each { |x| puts x } # Supported enumerable method
      #
      # @see https://picoruby.org for PicoRuby documentation
      class UnsupportedMethod < Base
        MSG = "Method `%<class>s#%<method>s` may not be supported in PicoRuby. " \
              "Verify in the RBS documentation or disable with `# rubocop:disable PicoRuby/UnsupportedMethod`"

        SETUP_MSG = "PicoRuby method database not found. " \
                    "Run 'ptrk rubocop update' to generate it."

        # Performance optimization: only check these methods that are likely to be unsupported
        RESTRICT_ON_SEND = %i[
          gsub! upcase! downcase! sub! subb! tr_s! squeeze! strip! lstrip! rstrip!
          unicode_normalize encode convert combination permutation repeated_permutation
          downto upto
        ].freeze

        def on_send(node)
          return unless @unsupported_methods

          receiver_type = infer_receiver_type(node.receiver)
          return unless receiver_type
          return unless core_class?(receiver_type)

          method_name = node.method_name.to_s
          return unless unsupported?(receiver_type, method_name)

          add_offense(
            node.loc.selector,
            message: format(MSG, class: receiver_type, method: method_name)
          )
        end

        private

        def setup_offenses
          super
          load_unsupported_methods
        end

        def load_unsupported_methods
          data_path = find_data_file('picoruby_unsupported_methods.json')
          return false unless data_path && File.exist?(data_path)

          content = File.read(data_path)
          @unsupported_methods = JSON.parse(content)
          true
        rescue StandardError => e
          puts "Warning: #{SETUP_MSG} (#{e.class})"
          false
        end

        def find_data_file(filename)
          # Check multiple possible locations
          possible_paths = [
            # Current directory structure
            File.join(Dir.pwd, 'data', filename),
            # Relative to script directory
            File.expand_path("../../../data/#{filename}", __dir__),
            # Fallback
            File.join(Dir.pwd, filename)
          ]

          possible_paths.find { |path| File.exist?(path) }
        end

        def infer_receiver_type(receiver_node)
          return nil unless receiver_node

          case receiver_node.type
          when :array
            'Array'
          when :str
            'String'
          when :hash
            'Hash'
          when :int
            'Integer'
          when :float
            'Float'
          when :sym
            'Symbol'
          when :send
            # Handle method calls: String.new.upcase
            if receiver_node.method_name == :new && receiver_node.receiver&.const_type?
              receiver_node.receiver.const_name.to_s
            end
          when :const
            # Direct constant: String, Array, etc.
            receiver_node.const_name.to_s
          end
        end

        def core_class?(class_name)
          %w[Array String Hash Integer Float Symbol Range Regexp].include?(class_name)
        end

        def unsupported?(class_name, method_name)
          return false unless @unsupported_methods
          return false unless @unsupported_methods[class_name]

          class_data = @unsupported_methods[class_name]
          class_data['instance'].include?(method_name) ||
            class_data['class'].include?(method_name)
        end
      end
    end
  end
end
```

**重要ポイント**:
- `setup_offenses` フック（RuboCop 1.27+）で初期化
- JSON ロード失敗時は graceful に失敗（エラーではなく警告）
- `RESTRICT_ON_SEND` で性能最適化（全メソッドではなく可疑メソッドのみチェック）
- レシーバーの型推論はリテラルベース（変数は推論不可）

### Phase 3: RuboCop 設定テンプレート

**ファイル**: `lib/pra/templates/rubocop/.rubocop.yml`

```yaml
require:
  - ./lib/rubocop/cop/picoruby/unsupported_method.rb

AllCops:
  TargetRubyVersion: 3.3
  NewCops: enable
  Exclude:
    - 'vendor/**/*'
    - 'node_modules/**/*'
    - 'tmp/**/*'
    - '.git/**/*'

# PicoRuby-specific cop
PicoRuby/UnsupportedMethod:
  Enabled: true
  Description: 'Detects methods that may not be available in PicoRuby'
  Severity: warning

# Standard RuboCop rules (optional baseline)
Style/StringLiterals:
  EnforcedStyle: single_quotes

Layout/LineLength:
  Max: 100
  Exclude:
    - 'Rakefile'
    - '**/*.rake'
```

### Phase 4: テンプレート README

**ファイル**: `lib/pra/templates/rubocop/README.md`

```markdown
# PicoRuby RuboCop Configuration

RuboCop configuration with custom cop for PicoRuby development.

## Quick Start

### 1. Generate method database (required before first use)

```bash
ptrk rubocop update
```

This will:
- Clone picoruby.github.io (if not already cloned)
- Extract method definitions from PicoRuby RBS docs
- Generate `data/picoruby_supported_methods.json`
- Generate `data/picoruby_unsupported_methods.json`

### 2. Run RuboCop

```bash
bundle exec rubocop
```

### 3. Fix violations

```bash
bundle exec rubocop --autocorrect-all
```

## Understanding Warnings

### PicoRuby/UnsupportedMethod

This custom cop warns when you use a method that **might not be available** in PicoRuby.

**Example**:
```
app.rb:15:5: W: PicoRuby/UnsupportedMethod: Method `String#unicode_normalize` may not be supported in PicoRuby.
    str.unicode_normalize
```

**Why warning, not error?**
- Not all PicoRuby environments have the same features
- You may have extended PicoRuby with custom mrbgems
- Some methods might work despite the warning

**How to handle**:

1. **Option A: Use an alternative method**
   ```ruby
   # Before (may not work)
   str.unicode_normalize

   # After (known to work)
   str.upcase
   ```

2. **Option B: Disable the check for this line**
   ```ruby
   str.unicode_normalize # rubocop:disable PicoRuby/UnsupportedMethod
   ```

3. **Option C: Disable for a block**
   ```ruby
   # rubocop:disable PicoRuby/UnsupportedMethod
   result = str.unicode_normalize
   result += str.gsub(/a/, 'b')  # Also disabled
   # rubocop:enable PicoRuby/UnsupportedMethod
   ```

## Updating the Database

When PicoRuby releases new features:

```bash
ptrk rubocop update
```

This will fetch the latest method definitions from picoruby.github.io.

## Configuration

Edit `.rubocop.yml` to customize:

- **Severity**: Change `warning` to `convention` (less important) or `error` (block merge)
- **Exclude**: Add paths to skip checking
- **TargetRubyVersion**: Set to your Ruby version

## Troubleshooting

### "PicoRuby method database not found"

Run:
```bash
ptrk rubocop update
```

### RuboCop doesn't load the custom cop

Check:
1. `.rubocop.yml` exists in project root
2. `lib/rubocop/cop/picoruby/unsupported_method.rb` exists
3. Run `bundle exec rubocop --show-cops PicoRuby` to verify

### Method is marked unsupported but actually works

The warning is based on official RBS documentation from picoruby.github.io.
If a method works in your environment, you can safely disable the warning.

## References

- [PicoRuby Official Documentation](https://picoruby.org)
- [picoruby.github.io RBS Docs](https://github.com/picoruby/picoruby.github.io)
- [RuboCop Documentation](https://docs.rubocop.org)
```

### Phase 5: ptrk コマンド実装

#### 5.1 Rubocop コマンドクラス

**ファイル**: `lib/pra/commands/rubocop.rb`

```ruby
require 'fileutils'
require 'thor'

module Pra
  module Commands
    class Rubocop < Thor
      desc 'setup', 'Setup RuboCop configuration for PicoRuby development'
      long_desc <<~LONGDESC
        Sets up RuboCop configuration with PicoRuby custom cop.

        This command copies the RuboCop template to your project:
        - .rubocop.yml
        - lib/rubocop/cop/picoruby/unsupported_method.rb
        - scripts/update_methods.rb
        - data/README.md
        - README.md (setup guide)

        After setup, run 'ptrk rubocop update' to generate the method database.
      LONGDESC
      def setup
        source_dir = File.expand_path('../../templates/rubocop', __dir__)
        target_dir = Dir.pwd

        copy_template_files(source_dir, target_dir)

        puts "\n✅ RuboCop configuration has been set up!"
        puts ""
        puts "Next steps:"
        puts "  1. Run: ptrk rubocop update"
        puts "     (generates method database from latest PicoRuby definitions)"
        puts ""
        puts "  2. Run: bundle exec rubocop"
        puts "     (checks your code)"
        puts ""
        puts "See README.md for more details."
      end

      desc 'update', 'Update PicoRuby method database'
      long_desc <<~LONGDESC
        Updates the PicoRuby method database using the latest definitions from
        picoruby.github.io.

        This will:
        1. Clone or pull picoruby.github.io
        2. Extract method definitions from RBS documentation
        3. Compare with CRuby to find unsupported methods
        4. Generate data/picoruby_supported_methods.json
        5. Generate data/picoruby_unsupported_methods.json

        Run this whenever:
        - Setting up for the first time (after 'ptrk rubocop setup')
        - PicoRuby has been updated with new methods
        - You want to refresh the method database
      LONGDESC
      def update
        script_path = File.join(Dir.pwd, 'scripts', 'update_methods.rb')

        unless File.exist?(script_path)
          puts "❌ Update script not found."
          puts ""
          puts "Please run 'ptrk rubocop setup' first to set up the RuboCop configuration."
          exit 1
        end

        puts "🚀 Running method database update..."
        puts ""

        # Execute the update script
        success = system("ruby #{script_path}")

        unless success
          puts ""
          puts "❌ Update failed. Please check the error above."
          exit 1
        end
      end

      private

      def copy_template_files(source, target)
        files_to_copy = [
          '.rubocop.yml',
          'lib',
          'scripts',
          'data',
          'README.md'
        ]

        files_to_copy.each do |file|
          source_path = File.join(source, file)
          target_path = File.join(target, file)

          if File.exist?(target_path)
            unless yes?("#{file} already exists. Overwrite? (y/N)")
              puts "⏭️  Skipped: #{file}"
              next
            end
            FileUtils.rm_rf(target_path)
          end

          if File.directory?(source_path)
            FileUtils.cp_r(source_path, target_path)
          else
            FileUtils.cp(source_path, target_path)
          end
          puts "✅ Copied: #{file}"
        end
      end
    end
  end
end
```

#### 5.2 CLI 登録

**ファイル**: `lib/pra/cli.rb` (既存ファイルに追加)

```ruby
# ... existing code ...

require_relative 'commands/rubocop'

module Pra
  class CLI < Thor
    # ... existing code ...

    subcommand 'rubocop', Pra::Commands::Rubocop

    # ... rest of code ...
  end
end
```

### Phase 6: テスト実装

**ファイル**: `test/pra/commands/rubocop_test.rb`

```ruby
require 'test_helper'
require 'pra/commands/rubocop'

describe Pra::Commands::Rubocop do
  let(:tmpdir) { Dir.mktempdir }
  let(:command) { Pra::Commands::Rubocop.new }

  after { FileUtils.rm_rf(tmpdir) }

  describe '#setup' do
    it 'copies template files to current directory' do
      Dir.chdir(tmpdir) do
        # Mock yes? to always return true
        expect(command).to receive(:yes?).and_return(true)

        command.setup

        assert File.exist?('.rubocop.yml')
        assert File.directory?('lib/rubocop/cop/picoruby')
        assert File.exist?('lib/rubocop/cop/picoruby/unsupported_method.rb')
        assert File.directory?('scripts')
        assert File.exist?('scripts/update_methods.rb')
        assert File.directory?('data')
      end
    end

    it 'shows overwrite prompt if .rubocop.yml exists' do
      Dir.chdir(tmpdir) do
        FileUtils.touch('.rubocop.yml')

        # Mock yes? to return false
        expect(command).to receive(:yes?).and_return(false)

        # This should skip the file
        command.setup

        # File should still be empty (not overwritten)
        assert File.exist?('.rubocop.yml')
      end
    end
  end

  describe '#update' do
    it 'fails if scripts/update_methods.rb does not exist' do
      Dir.chdir(tmpdir) do
        assert_raises(SystemExit) { command.update }
      end
    end

    it 'executes the update script if it exists' do
      Dir.chdir(tmpdir) do
        FileUtils.mkdir_p('scripts')
        File.write('scripts/update_methods.rb', '#!/usr/bin/env ruby; puts "test"')
        File.chmod(0o755, 'scripts/update_methods.rb')

        # This should succeed
        expect(command).to receive(:system).with(/ruby.*update_methods.rb/).and_return(true)

        command.update
      end
    end
  end
end
```

### Phase 7: 動作確認手順

```bash
# 1. テンプレート配置
cd /tmp/test-picoruby-project
ptrk rubocop setup

# 2. ファイル確認
ls -la .rubocop.yml
ls -la lib/rubocop/cop/picoruby/unsupported_method.rb
ls -la scripts/update_methods.rb

# 3. データベース生成
ptrk rubocop update
# → picoruby.github.io クローン、RBS doc パース、JSON 生成

# 4. ファイル確認
ls -la data/picoruby_supported_methods.json
ls -la data/picoruby_unsupported_methods.json

# 5. RuboCop 実行
cat > app.rb << 'EOF'
# Good: supported methods
arr = [1, 2, 3]
arr.each { |x| puts x }

str = "hello"
str.upcase

# Bad: unsupported methods
str.unicode_normalize
arr.combination(2)
EOF

bundle exec rubocop app.rb
# → 警告が表示される
```

---

## 🎯 成果物の全リスト

### ptrk gem 内に追加するファイル

1. **`lib/pra/commands/rubocop.rb`** - RuboCop サブコマンド実装
2. **`lib/pra/templates/rubocop/.rubocop.yml`** - RuboCop 設定テンプレート
3. **`lib/pra/templates/rubocop/lib/rubocop/cop/picoruby/unsupported_method.rb`** - カスタム Cop
4. **`lib/pra/templates/rubocop/scripts/update_methods.rb`** - データ抽出スクリプト
5. **`lib/pra/templates/rubocop/data/README.md`** - データディレクトリ説明
6. **`lib/pra/templates/rubocop/README.md`** - セットアップ・使用ガイド
7. **`test/pra/commands/rubocop_test.rb`** - コマンドのテスト

### ptrk gem 内の修正ファイル

1. **`lib/pra/cli.rb`** - 1行追加（RuboCop サブコマンド登録）

---

## ⚠️ 留意事項

### 1. 型推論の限界

現在の実装はリテラル検出のみ：

```ruby
# ✅ 検出可能
[1, 2, 3].combination(2)     # 配列リテラル
"string".unicode_normalize   # 文字列リテラル
{a: 1}.merge!(b: 2)          # ハッシュリテラル

# ❌ 検出不可（変数の型が不明）
arr = get_array()
arr.combination(2)           # arr の型が推論できない
```

改善には **Steep/RBS 統合** が必要（大規模な拡張）。

### 2. 依存関係

- **git** コマンド（リポジトリクローン/プル）
  - スクリプト実行環境に git が必要
  - CI 環境で実行する場合、git インストール確認
- **インターネット接続** （picoruby.github.io アクセス）
- **tmpdir アクセス** （作業ディレクトリ作成）

### 3. データベース更新タイミング

- **初回**: `ptrk rubocop setup` → `ptrk rubocop update` 必須
- **継続**: ユーザーが必要に応じて `ptrk rubocop update` 実行
- **gem バージョン**: データ更新のためにアップグレード不要（最新定義を常に取得）

### 4. RBS doc の構造変更への耐性

picoruby.github.io の Markdown フォーマットが変更された場合、`update_methods.rb` の正規表現を更新必要。

監視チェックポイント:
- `^### method_name` の行フォーマット
- `## Instance methods` / `## Singleton methods` セクション

---

## 🔄 ユーザーワークフロー例

### シナリオ1: 初回セットアップ

```bash
# ユーザーディレクトリ
$ cd my-picoruby-project
$ ptrk rubocop setup
✅ RuboCop configuration has been set up!

Next steps:
  1. Run: ptrk rubocop update
  2. Run: bundle exec rubocop

See README.md for more details.

$ ptrk rubocop update
🚀 Starting PicoRuby method database update...
📥 Cloning picoruby.github.io repository...
🔍 Extracting PicoRuby methods from RBS documentation...
🔍 Extracting CRuby core class methods...
📊 Calculating unsupported methods...
💾 Saved: data/picoruby_supported_methods.json
💾 Saved: data/picoruby_unsupported_methods.json

📈 Summary:
  ✅ Supported: 1,234 methods across 45 classes
  ⚠️  Unsupported: 567 methods

✅ Database update completed successfully!

$ bundle exec rubocop
Inspecting 5 files
..W..

app.rb:15:5: W: PicoRuby/UnsupportedMethod: Method `String#unicode_normalize` may not be supported in PicoRuby.
    str.unicode_normalize

5 files inspected, 1 offense detected
```

### シナリオ2: PicoRuby アップデート時

```bash
# 3ヶ月後、PicoRuby がアップデートされた

$ ptrk rubocop update
🚀 Starting PicoRuby method database update...
📦 Repository already cloned. Pulling latest changes...
🔍 Extracting PicoRuby methods from RBS documentation...
🔍 Extracting CRuby core class methods...
📊 Calculating unsupported methods...
💾 Saved: data/picoruby_supported_methods.json
💾 Saved: data/picoruby_unsupported_methods.json

📈 Summary:
  ✅ Supported: 1,456 methods across 48 classes (↑ 222 methods!)
  ⚠️  Unsupported: 345 methods (↓ 222 methods!)

✅ Database update completed successfully!

# 前の警告が消えているかもしれない
$ bundle exec rubocop
Inspecting 5 files
.....

5 files inspected, 0 offenses detected
```

---

## 📚 参考資料・コマンド集

### CRuby メソッド抽出

```ruby
# 単一クラス
ruby -e "puts Array.instance_methods(false).sort"

# 複数クラス（JSON 形式）
ruby -e "
require 'json'
classes = %w[Array String Hash]
result = classes.map do |name|
  klass = Object.const_get(name)
  { name => { instance: klass.instance_methods(false).sort.map(&:to_s) } }
end.inject(&:merge)
puts JSON.pretty_generate(result)
"
```

### picoruby.github.io サンプルクエリ

```bash
# RBS doc ファイル一覧
curl https://api.github.com/repos/picoruby/picoruby.github.io/contents/pages/rbs_doc | \
  jq '.[] | .name' | head -20

# 特定クラスの Markdown 取得
curl https://raw.githubusercontent.com/picoruby/picoruby.github.io/main/pages/rbs_doc/Array.md
```

### RuboCop AST 確認

```bash
# コードの AST 表示
ruby -e "
require 'parser/current'
code = '[1,2,3].upcase'
ast = Parser::CurrentRuby.parse(code)
puts ast.inspect
"

# RuboCop コップのリスト表示
bundle exec rubocop --show-cops
bundle exec rubocop --show-cops PicoRuby
```

---

## 🚀 実装開始チェックリスト

- [ ] Phase 1: データ抽出スクリプト実装
  - [ ] テンプレートディレクトリ作成
  - [ ] `update_methods.rb` 実装・ローカルテスト
  - [ ] `data/README.md` 作成
- [ ] Phase 2: カスタム Cop 実装
  - [ ] `unsupported_method.rb` 実装
  - [ ] テスト用 Ruby ファイルで動作確認
- [ ] Phase 3: RuboCop 設定
  - [ ] `.rubocop.yml` テンプレート作成
- [ ] Phase 4: テンプレート README
  - [ ] `README.md` 作成（セットアップ・使用方法）
- [ ] Phase 5: ptrk コマンド実装
  - [ ] `lib/pra/commands/rubocop.rb` 実装
  - [ ] `lib/pra/cli.rb` に登録
- [ ] Phase 6: テスト実装
  - [ ] `test/pra/commands/rubocop_test.rb` 実装・実行
- [ ] Phase 7: 動作確認
  - [ ] 実プロジェクトで setup → update → rubocop を実行
- [ ] Phase 8: commit
  - [ ] git add + commit（commit subagent 使用）

---

**記述日**: 2025-11-08
**作成者**: Claude Code
**参照**: `TODO.md` - PicoRuby RuboCop Configuration Template タスク
