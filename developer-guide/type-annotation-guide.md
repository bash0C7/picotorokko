# Priority 1 Phase 2: rbs-inline Annotations 実装ガイド

**作成日**: 2025-11-13
**対象**: Phase 2 Core API Type Annotations 実装
**参考**: type-system-strategy.md, rbs-inline-research.md
**次文書**: t-wada-style-tdd-guide.md (Phase 5)

---

## 目次

1. [概要](#概要)
2. [rbs-inline 構文ガイド](#rbs-inline-構文ガイド)
3. [実装パターン](#実装パターン)
4. [環境セットアップ](#環境セットアップ)
5. [Phase 2 段階別実装](#phase-2-段階別実装)
6. [よくあるエラーと対処法](#よくあるエラーと対処法)
7. [ベストプラクティス](#ベストプラクティス)
8. [Steep 型エラー解決ガイド](#steep-型エラー解決ガイド)

---

## 概要

このガイドは **Phase 2: Core API Type Annotations** を実装するための実践的なノウハウをまとめたもの。

**対象ファイル**:
- `lib/picotorokko/cli.rb`
- `lib/picotorokko/commands/*.rb`
- `lib/picotorokko/env.rb` (PoC)

**目標**:
- 全 public methods に rbs-inline annotations を追加
- `bundle exec rbs-inline --output sig lib` で .rbs 自動生成
- `bundle exec steep check` で 0 errors 達成

---

## rbs-inline 構文ガイド

### 基本形: メソッドシグネチャ

```ruby
# @rbs (String, count: Integer) -> Array[String]
def process(name, count:)
  Array.new(count) { name }
end
```

**構文**: `# @rbs (引数型) -> 戻り値型`

### パターン1: パラメータなし

```ruby
# @rbs () -> String
def version
  VERSION
end
```

### パターン2: キーワード引数

```ruby
# @rbs (name: String, verbose: bool) -> Hash[String, untyped]
def config(name:, verbose: false)
  { name => verbose }
end
```

### パターン3: 可変長引数

```ruby
# @rbs (*String) -> void
def print_all(*items)
  items.each { |item| puts item }
end
```

### パターン4: ブロック付き

```ruby
# @rbs (String) { (String) -> void } -> void
def process_items(prefix, &block)
  ["a", "b"].each { |item| block.call("#{prefix}#{item}") }
end
```

### パターン5: union 型（複数の可能な型）

```ruby
# @rbs (String) -> String | nil
def find_env(name)
  load_env_file[name]
end
```

### パターン6: Array, Hash 型

```ruby
# @rbs (Array[String]) -> Hash[String, Integer]
def count_items(items)
  items.each_with_object({}) { |item, acc| acc[item] ||= 0; acc[item] += 1 }
end
```

### パターン7: 属性の型注釈

```ruby
attr_reader :name #: String
attr_accessor :items #: Array[Symbol]
attr_writer :config #: Hash[String, untyped]
```

### パターン8: 型エイリアス定義

```ruby
# @rbs type env_config = { "R2P2-ESP32" => String, "picoruby" => String }

# @rbs (String) -> env_config
def get_config(name)
  # ...
end
```

### パターン9: クラス継承の型

```ruby
# @rbs < Thor
class CLI < Thor
  # ...
end
```

---

## 実装パターン

### CLI コマンドクラス

```ruby
module Picotorokko
  # PicoRuby開発ツール CLI
  # @rbs < Thor
  class CLI < Thor
    # Exit on failure
    # @rbs () -> bool
    def self.exit_on_failure?
      true
    end

    desc "env SUBCOMMAND", "Manage environments"
    # @rbs (String, *String) -> untyped
    subcommand :env, Commands::Env

    desc "version", "Show version"
    # @rbs () -> void
    def version
      puts Picotorokko::VERSION
    end

    desc "help [COMMAND]", "Describe available commands or one specific command"
    # @rbs (?String) -> void
    def help(command = nil)
      super
    end
  end
end
```

### Thor サブコマンドクラス

```ruby
module Picotorokko
  module Commands
    # Environment management
    # @rbs < Thor
    class Env < Thor
      # 環境定義を表示
      #
      # @rbs (String) -> void
      desc "show NAME", "Display environment definition"
      option :verbose, type: :boolean, default: false
      def show(name)
        config = Picotorokko::Env.get_environment(name)
        puts JSON.pretty_generate(config) if config
      end

      # 環境一覧表示
      #
      # @rbs () -> void
      desc "list", "List all environments"
      def list
        file = Picotorokko::Env.load_env_file
        file.keys.each { |name| puts name }
      end
    end
  end
end
```

### モジュール with クラスメソッド

```ruby
module Picotorokko
  # Environment definition and management
  module Env
    ENV_DIR: String #: String
    ENV_NAME_PATTERN: Regexp #: Regexp

    # Validate environment name
    #
    # @rbs (String) -> void
    def self.validate_env_name!(name)
      unless ENV_NAME_PATTERN.match?(name)
        raise RuntimeError, "Invalid environment name: #{name}"
      end
    end

    # Get environment config
    #
    # @rbs (String) -> Hash[String, untyped] | nil
    def self.get_environment(name)
      validate_env_name!(name)
      data = load_env_file
      data[name]
    end

    # Set environment config
    #
    # @rbs (String, Hash[String, String], Hash[String, String], Hash[String, String]) -> void
    def self.set_environment(name, r2p2, esp32, picoruby)
      validate_env_name!(name)
      data = load_env_file
      data[name] = {
        "R2P2-ESP32" => r2p2,
        "picoruby-esp32" => esp32,
        "picoruby" => picoruby,
        "created_at" => Time.now.strftime("%Y%m%d_%H%M%S")
      }
      save_env_file(data)
    end

    # Load environment file
    #
    # @rbs () -> Hash[String, untyped]
    private_class_method def self.load_env_file
      file = env_file
      return {} unless File.exist?(file)
      YAML.load_file(file) || {}
    end

    # Save environment file
    #
    # @rbs (Hash[String, untyped]) -> void
    private_class_method def self.save_env_file(data)
      File.write(env_file, YAML.dump(data))
    end
  end
end
```

---

## 環境セットアップ

### Step 1: 依存関係追加

```bash
# picotorokko.gemspec に以下を追加
bundle add rbs --group development
bundle add steep --group development
bundle add rbs-inline --group development --require=false

bundle install
```

### Step 2: Steepfile 作成

プロジェクトルート（`.ruby-version` と同階層）に `Steepfile` を作成：

```ruby
D = Steep::Diagnostic

target :lib do
  signature "sig"
  check "lib"

  # External library types
  library "thor"
  library "yaml"
  library "fileutils"
  library "shellwords"
  library "time"
  library "pathname"

  # Configure diagnostics
  configure_code_diagnostics do |hash|
    hash[D::Ruby::NoMethod] = :error
    hash[D::Ruby::UnresolvedOverloading] = :error
    hash[D::Ruby::IncompatibleAssignment] = :error
    hash[D::Ruby::UnexpectedBlockGiven] = :warning
  end
end

target :test do
  signature "sig"
  check "test"

  library "test-unit"
  library "tmpdir"
  library "stringio"

  configure_code_diagnostics do |hash|
    hash[D::Ruby::NoMethod] = :warning
  end
end
```

### Step 3: Rakefile タスク追加

```ruby
# Rakefile

namespace :rbs do
  desc "Generate RBS files from rbs-inline annotations"
  task :generate do
    sh "bundle exec rbs-inline --output sig lib"
    puts "✓ RBS files generated in sig/"
  end

  desc "Clean generated RBS files"
  task :clean do
    FileUtils.rm_rf("sig")
    puts "✓ sig/ directory removed"
  end
end

desc "Run Steep type checking"
task :steep do
  sh "bundle exec steep check"
end

# Integrate into ci task (update existing ci task)
task ci: %i[reset_coverage test rubocop rbs:generate steep coverage_validation] do
  puts "\n✓ CI passed! All tests + RuboCop + types + coverage validated."
end
```

### Step 4: sig/ ディレクトリ作成

```bash
mkdir -p sig/picotorokko/commands
touch sig/.gitkeep
```

### Step 5: .gitignore 更新

```bash
# .gitignore に追加
sig/*.rbs      # Generated RBS files (but commit *.rbs for reproducibility)
```

---

## Phase 2 段階別実装

### Iteration 1: CLI （2時間）

**目標**: `lib/picotorokko/cli.rb` に annotations を追加

**実装**:

```ruby
# lib/picotorokko/cli.rb

module Picotorokko
  # PicoRuby development tool command-line interface
  # @rbs < Thor
  class CLI < Thor
    # @rbs () -> bool
    def self.exit_on_failure?
      true
    end

    # @rbs (String, *String) -> untyped
    subcommand :env, "Commands::Env"

    # @rbs (String, *String) -> untyped
    subcommand :device, "Commands::Device"

    # @rbs (String, *String) -> untyped
    subcommand :mrbgems, "Commands::Mrbgems"

    # @rbs (String, *String) -> untyped
    subcommand :rubocop, "Commands::Rubocop"

    desc "version", "Show version"
    # @rbs () -> void
    def version
      puts Picotorokko::VERSION
    end
  end
end
```

**検証**:

```bash
bundle exec rbs-inline --output sig lib/picotorokko/cli.rb
ls -la sig/picotorokko/cli.rbs
cat sig/picotorokko/cli.rbs
```

### Iteration 2: Commands （3時間）

**目標**: `lib/picotorokko/commands/*.rb` 全てに annotations を追加

```ruby
# lib/picotorokko/commands/env.rb

module Picotorokko
  module Commands
    # Environment management command
    # @rbs < Thor
    class Env < Thor
      desc "show NAME", "Show environment definition"
      option :verbose, type: :boolean, default: false
      # @rbs (String) -> void
      def show(name)
        # Implementation
      end

      desc "list", "List all environments"
      # @rbs () -> void
      def list
        # Implementation
      end
    end
  end
end
```

**各コマンドファイル**:
- `commands/env.rb`
- `commands/device.rb`
- `commands/mrbgems.rb`
- `commands/rubocop.rb`

**検証**:

```bash
bundle exec rbs-inline --output sig lib/picotorokko/commands/*.rb
bundle exec steep check
# Expected: Type errors in env.rb (next iteration)
```

### Iteration 3: env.rb PoC （2時間）

**目標**: `lib/picotorokko/env.rb` に annotations を追加（最重要メソッド）

```ruby
# lib/picotorokko/env.rb （重要メソッドのみ annotation追加）

module Picotorokko
  module Env
    ENV_DIR: String #: String
    ENV_NAME_PATTERN: Regexp #: Regexp

    # @rbs () -> String
    def self.project_root
      # ...
    end

    # @rbs (String) -> Hash[String, untyped] | nil
    def self.get_environment(name)
      # ...
    end

    # @rbs (String) -> void
    def self.validate_env_name!(name)
      # ...
    end
  end
end
```

**検証**:

```bash
bundle exec rbs-inline --output sig lib/picotorokko/env.rb
bundle exec steep check

# 型エラーが出た場合: annotation を修正 → 再度 rbs-inline → steep check
```

### Iteration 4: Steep エラー修正 （1時間）

**steep check で出た型エラーを修正**

```bash
bundle exec steep check

# 出力例:
# lib/picotorokko/env.rb:42:10: error: Type `Hash[String, untyped]` doesn't have method `[]`
# lib/picotorokko/env.rb:42:10:   Can't assign value of type `nil | untyped` to variable of type `Hash[String, untyped]`

# 修正: annotation の型をより正確に
# @rbs (String) -> Hash[String, untyped] | nil
```

---

## よくあるエラーと対処法

### Error 1: Unresolved constant `Hash`

```
error: Unresolved constant `Hash[String, untyped]`
```

**原因**: Steep が RBS Collection にアクセスできていない

**対処**:

```bash
# Steepfile を確認
cat Steepfile

# library "..." を追加
library "yaml"

# 再実行
bundle exec steep check
```

### Error 2: Method not found in nil

```
error: Type `nil` doesn't have method `[]`
```

**原因**: Union 型の handling

**修正**:

```ruby
# Before
# @rbs (String) -> Hash[String, untyped]
def get_config(name)
  data = load_file
  data[name]  # ← data が nil の場合があるのに無視
end

# After
# @rbs (String) -> Hash[String, untyped] | nil
def get_config(name)
  data = load_file
  return nil unless data
  data[name]
end
```

### Error 3: Unresolved method parameter type

```
error: Unresolved overloading `String#split`
```

**原因**: 引数の型が曖昧

**修正**:

```ruby
# Before
# @rbs () -> Array
def split_items
  items.split(',')
end

# After
# @rbs () -> Array[String]
def split_items
  items.split(',')
end
```

---

## ベストプラクティス

### Rule 1: annotation は実装の直前に配置

```ruby
✅ Good
# @rbs (String) -> Array[String]
def process(name)
  # Implementation
end

❌ Bad
# Implementation somewhere

# @rbs (String) -> Array[String]
def process(name)
end
```

### Rule 2: 説明文との組み合わせ

```ruby
✅ Good
# Process items with given name
#
# @rbs (String, count: Integer) -> Array[String]
# @example
#   process("test", count: 3)
def process(name, count:)
  # ...
end

❌ Bad
# @rbs (String, count: Integer) -> Array[String]
def process(name, count:)
  # ... (説明文なし)
end
```

### Rule 3: Private メソッドも annotation

```ruby
✅ Good
# @rbs (Hash) -> void
private_class_method def self.save_config(data)
  # ...
end

❌ Bad
private_class_method def self.save_config(data)
  # ... (annotation なし)
end
```

### Rule 4: 複雑な型は型エイリアスで定義

```ruby
✅ Good
# @rbs type env_config = { "R2P2-ESP32" => String, "picoruby" => String }
# @rbs (String) -> env_config
def get_config(name)
  # ...
end

❌ Bad
# @rbs (String) -> { "R2P2-ESP32" => String, "picoruby" => String }
def get_config(name)
  # ... (複雑で読みにくい)
end
```

---

## Steep 型エラー解決ガイド

### 頻出エラーパターン

#### パターン1: Nil check

**エラー**:
```
Type `String | nil` doesn't have method `upcase`
```

**解決**:

```ruby
# Before
def process(name)
  name.upcase  # ← name が nil の可能性
end

# After
def process(name)
  return nil if name.nil?
  name.upcase
end

# Annotation
# @rbs (String | nil) -> String | nil
def process(name)
  return nil if name.nil?
  name.upcase
end
```

#### パターン2: Array 要素型

**エラー**:
```
Can't assign value of type `String | nil` to variable of type `String`
```

**解決**:

```ruby
# Before
# @rbs () -> Array[String]
def get_items
  ["a", nil, "b"].compact  # ← nil を含む可能性
end

# After
# @rbs () -> Array[String]
def get_items
  ["a", "b"]
end

# または
# @rbs () -> Array[String | nil]
def get_items
  ["a", nil, "b"]
end
```

#### パターン3: Hash access

**エラー**:
```
Can't assume field to exist
```

**解決**:

```ruby
# Before
# @rbs (String) -> String
def get_value(key)
  hash[key]  # ← key が存在しない可能性
end

# After
# @rbs (String) -> String | nil
def get_value(key)
  hash[key]
end

# または fetch を使う
# @rbs (String) -> String
def get_value(key)
  hash.fetch(key, "default")
end
```

---

## Commit Checklist (Phase 2完了時)

```markdown
## Phase 2 Completion Checklist

- [ ] gemspec: rbs, steep, rbs-inline 依存関係追加
- [ ] Steepfile 作成・設定確認
- [ ] Rakefile: rake rbs:generate, rake steep タスク追加
- [ ] sig/ ディレクトリ構造作成
- [ ] lib/picotorokko/cli.rb に rbs-inline annotations 追加
- [ ] lib/picotorokko/commands/*.rb に rbs-inline annotations 追加
- [ ] lib/picotorokko/env.rb に rbs-inline annotations 追加 (PoC)
- [ ] bundle exec rbs-inline --output sig lib 実行
- [ ] bundle exec steep check → 0 errors
- [ ] bundle exec rake test → all passing
- [ ] bundle exec rubocop → 0 violations
- [ ] bundle exec rake ci → success
- [ ] .rbs files committed (sig/*.rbs)
- [ ] Commit message: "feat: add rbs-inline annotations to public API"
```

---

## 次のステップ (Phase 3, Phase 5)

- **Phase 3**: 残り lib/ ファイルに annotations 追加 + GitHub Actions 統合
- **Phase 5**: t-wada style TDD ワークフロー確立 (参照: `t-wada-style-tdd-guide.md`)

---

**ガイド作成日**: 2025-11-13
**対象**: Phase 2 実装者
**参考**: type-system-strategy.md, rbs-inline-research.md
