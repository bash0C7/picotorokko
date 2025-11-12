# t-wada style TDD: picotorokko 開発ワークフロー完全ガイド

**作成日**: 2025-11-13
**対象**: Phase 5 以降のすべての開発者
**参考**: CLAUDE.md, type-system-strategy.md, type-annotation-guide.md

---

## 目次

1. [t-wada style TDD とは](#t-wada-style-tdd-とは)
2. [Micro-Cycle 詳細](#micro-cycle-詳細)
3. [実例: 新規コマンド追加](#実例-新規コマンド追加)
4. [実例: 既存機能の改善](#実例-既存機能の改善)
5. [Quality Gates の統合](#quality-gates-の統合)
6. [よくあるアンチパターン](#よくあるアンチパターン)
7. [Tidy First との連携](#tidy-first-との連携)

---

## t-wada style TDD とは

### 本質

**t-wada style TDD** は、実際のテスト駆動開発における正統なアプローチ。多くの人が誤解している「テストを書く」というアクションではなく、**設計と品質を継続的に改善するプロセス**。

**3つの柱**:

1. **Type-First Design** (annotation先行)
   - メソッドシグネチャを最初に型で定義
   - コントラクト明確化

2. **Test-Driven Development** (真のTDD)
   - RED: テストが失敗する状態を作る
   - GREEN: 最小限の実装でテスト通過
   - REFACTOR: 設計改善、コード品質向上

3. **Tidy First** (継続的改善)
   - 小さな改善を積み重ねる
   - リファクタリングは常に品質向上を目指す

### なぜ重要か

**従来の「テスト駆動」との違い**:

```
❌ 従来のテスト駆動（誤った理解）
テストを書く → 実装する → テスト通過 → 終了
（品質はテストの本数に依存、設計改善なし）

✅ t-wada style TDD
設計(Annotation) → テスト → 実装 → 改善 → 品質向上
（継続的な設計改善、品質は構造的に向上）
```

---

## Micro-Cycle 詳細

### サイクル全体像

```
┌─────────────────────────────────────────────────────────┐
│ t-wada style TDD Micro-Cycle (1-5分)                    │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. ANNOTATION (2分)                                    │
│     型シグネチャを annotation で定義                     │
│     # @rbs (String) -> Array[String]                    │
│                                                          │
│  2. RED (1分)                                           │
│     テスト作成・失敗確認                                │
│     bundle exec rake test → ❌                          │
│                                                          │
│  3. GREEN (1分)                                         │
│     最小限の実装でテスト通過 + 型チェック               │
│     bundle exec rake test → ✅                          │
│     bundle exec rbs-inline --output sig lib             │
│     bundle exec steep check → ✅                        │
│                                                          │
│  4. RUBOCOP (30秒)                                      │
│     スタイル自動修正                                    │
│     bundle exec rubocop -A                              │
│                                                          │
│  5. REFACTOR (1-2分)                                    │
│     実装改善 + 型定義精密化                             │
│     bundle exec rbs-inline --output sig lib             │
│     bundle exec steep check → ✅                        │
│                                                          │
│  6. COMMIT (30秒)                                       │
│     全 quality gates 通過確認                           │
│     bundle exec rake ci → ✅                            │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 各フェーズ詳細

#### Phase 1: ANNOTATION (型定義) - 2分

**何をするか**:
- メソッドシグネチャの型を rbs-inline annotation で定義
- コメント行で説明文も追加
- 実装コードはまだ書かない

**例**:

```ruby
module Picotorokko
  module Commands
    class Env < Thor
      # Show environment configuration
      #
      # @rbs (String) -> void
      #
      # @example
      #   Env.new.show("latest")
      desc "show NAME", "Show environment definition"
      option :verbose, type: :boolean, default: false
      def show(name)
        # Implementation comes in GREEN phase
      end
    end
  end
end
```

**ポイント**:
- 引数型と戻り値型を明確に
- 説明文をコメントで付記
- 例示 (@example) を含める
- 実装スケルトン（method signature + 説明）だけ

**チェックリスト**:
- [ ] メソッドシグネチャが型で定義されている
- [ ] 説明文が記述されている
- [ ] @example コメントが含まれている
- [ ] 実装コードはまだない

---

#### Phase 2: RED (テスト) - 1分

**何をするか**:
- テストを書く（実装なし）
- テストが失敗することを確認

**例**:

```ruby
# test/commands/env_test.rb

class EnvTest < Test::Unit::TestCase
  def test_show_displays_environment
    output = capture_stdout { Commands::Env.new.show("latest") }
    assert_match(/R2P2-ESP32/, output)
  end

  def test_show_with_verbose_option
    output = capture_stdout {
      Commands::Env.new.invoke(:show, ["latest"], verbose: true)
    }
    assert_match(/commit/, output)
  end
end
```

**実行**:

```bash
bundle exec rake test
# → ❌ FAIL: undefined method `show'
```

**ポイント**:
- ユーザーの視点でテストを書く
- 実装の詳細は気にしない
- 失敗するテストであることを確認

**チェックリスト**:
- [ ] テストが実装なしで書かれている
- [ ] テスト実行して失敗を確認 (❌)
- [ ] 失敗メッセージが明確である

---

#### Phase 3: GREEN (実装) - 1分

**何をするか**:
- 最小限の実装でテストを通す
- 型チェックも同時に通す
- 「とりあえず動く」レベルで OK

**例**:

```ruby
module Picotorokko
  module Commands
    class Env < Thor
      # Show environment configuration
      #
      # @rbs (String) -> void
      #
      # @example
      #   Env.new.show("latest")
      desc "show NAME", "Show environment definition"
      option :verbose, type: :boolean, default: false
      def show(name)
        config = Picotorokko::Env.get_environment(name)
        puts JSON.pretty_generate(config) if config
      end
    end
  end
end
```

**実行**:

```bash
bundle exec rake test
# → ✅ PASS

bundle exec rbs-inline --output sig lib
bundle exec steep check
# → ✅ 0 errors (annotation の型と実装が一致)
```

**ポイント**:
- テストを通すことだけを目的
- 美しさ、効率性は後で
- 型チェックも同時に通す（annotation の型と実装の矛盾を検出）

**チェックリスト**:
- [ ] テスト実行して通過 (✅)
- [ ] rbs-inline --output sig lib 実行成功
- [ ] steep check → 0 errors
- [ ] 実装は最小限（冗長性なし）

---

#### Phase 4: RUBOCOP - 30秒

**何をするか**:
- スタイル違反を自動修正

**実行**:

```bash
bundle exec rubocop -A

# 出力例:
# lib/picotorokko/commands/env.rb:123:4: C: Layout/SpaceAfterComma: Space after comma missing.
# ...
# Modified 1 file
```

**ポイント**:
- `-A` フラグで自動修正
- 修正後 `bundle exec rake test` で再確認（修正で壊れてないか）

**チェックリスト**:
- [ ] bundle exec rubocop -A 実行
- [ ] テスト再実行して PASS 確認 (✅)

---

#### Phase 5: REFACTOR (改善) - 1-2分

**何をするか**:
- コード品質を向上
- 型定義を精密化
- Tidy First の原則に従う

**例1: 実装改善**

```ruby
# Before (Green フェーズ)
def show(name)
  config = Picotorokko::Env.get_environment(name)
  puts JSON.pretty_generate(config) if config
end

# After (REFACTOR)
def show(name)
  Picotorokko::Env.validate_env_name!(name)

  config = Picotorokko::Env.get_environment(name)
  unless config
    warn "Environment not found: #{name}"
    return
  end

  puts JSON.pretty_generate(config)
end
```

**例2: 型定義精密化**

```ruby
# Before (Green フェーズ)
# @rbs (String) -> void
def show(name)
  # ...
end

# After (REFACTOR)
# Show environment definition
# Raises RuntimeError if environment not found
#
# @rbs (String) -> void
def show(name)
  # ...
end
```

**実行**:

```bash
bundle exec rbs-inline --output sig lib
bundle exec steep check
# → ✅ 0 errors

bundle exec rake test
# → ✅ PASS

bundle exec rubocop
# → 0 violations
```

**ポイント**:
- 1つの責務に集中
- Tidy First: 小さな改善を積み重ねる
- テストと型チェックは常に通す状態を保つ

**チェックリスト**:
- [ ] コード品質向上（処理の追加、エラーハンドリング等）
- [ ] 型定義が実装を正確に表現
- [ ] steep check → 0 errors
- [ ] rake test → PASS
- [ ] rubocop → 0 violations

---

#### Phase 6: COMMIT - 30秒

**何をするか**:
- すべての quality gates が通ることを確認
- コミット

**実行**:

```bash
bundle exec rake ci
# → ✅ All tests pass
# → ✅ RuboCop: 0 violations
# → ✅ Steep check: 0 errors
# → ✅ Coverage ≥ 85% line, ≥ 60% branch

git add .
git commit -m "feat: add env show command

Display environment configuration by name.

Includes proper error handling and type safety via rbs-inline annotations."
```

**ポイント**:
- `rake ci` で全ゲート通過確認
- commit message は命令形（「Add」「Fix」）
- body には why を記述（what ではなく）

**チェックリスト**:
- [ ] bundle exec rake ci → success
- [ ] git status clean
- [ ] commit message は命令形
- [ ] body に why が記述

---

## 実例: 新規コマンド追加

### 例: `ptrk config validate` コマンド追加

**Goal**: 環境設定ファイル (.picoruby-env.yml) を検証するコマンド

### ANNOTATION フェーズ

```ruby
# lib/picotorokko/commands/config.rb

module Picotorokko
  module Commands
    # Configuration management commands
    # @rbs < Thor
    class Config < Thor
      # Validate configuration file
      #
      # Shows validation results and exits with status code
      # 0 = valid, 1 = invalid
      #
      # @rbs () -> void
      #
      # @example
      #   ptrk config validate
      #
      desc "validate", "Validate configuration file"
      def validate
        # Implementation in GREEN phase
      end

      # Show configuration
      #
      # @rbs (String) -> void
      #
      # @example
      #   ptrk config show latest
      #
      desc "show NAME", "Show configuration by name"
      def show(name)
        # Implementation in GREEN phase
      end
    end
  end
end
```

### RED フェーズ

```ruby
# test/commands/config_test.rb

class ConfigTest < Test::Unit::TestCase
  def test_validate_with_valid_config
    # Create valid config file
    File.write(env_file, valid_config_yaml)

    output = capture_stdout { Commands::Config.new.validate }
    assert_match(/valid/i, output)
  end

  def test_validate_with_invalid_config
    File.write(env_file, "invalid: yaml: content:")

    output = capture_stdout { Commands::Config.new.validate }
    assert_match(/invalid/i, output)
  end

  def test_show_displays_configuration
    File.write(env_file, valid_config_yaml)

    output = capture_stdout { Commands::Config.new.show("latest") }
    assert_match(/R2P2-ESP32/, output)
  end

  private

  def env_file
    File.join(Picotorokko::Env.project_root, ".picoruby-env.yml")
  end

  def valid_config_yaml
    # ...
  end
end
```

**実行**:

```bash
bundle exec rake test
# → ❌ FAIL: undefined method `validate'
```

### GREEN フェーズ

```ruby
module Picotorokko
  module Commands
    class Config < Thor
      # Validate configuration file
      #
      # @rbs () -> void
      desc "validate", "Validate configuration file"
      def validate
        begin
          YAML.load_file(env_file)
          puts "✓ Configuration is valid"
        rescue => e
          puts "✗ Configuration is invalid: #{e.message}"
        end
      end

      # Show configuration
      #
      # @rbs (String) -> void
      desc "show NAME", "Show configuration by name"
      def show(name)
        config = Picotorokko::Env.get_environment(name)
        puts JSON.pretty_generate(config) if config
      end

      private

      def env_file
        File.join(Picotorokko::Env.project_root, ".picoruby-env.yml")
      end
    end
  end
end
```

**実行**:

```bash
bundle exec rake test
# → ✅ PASS

bundle exec rbs-inline --output sig lib/picotorokko/commands/config.rb
bundle exec steep check
# → ✅ 0 errors
```

### REFACTOR フェーズ

```ruby
module Picotorokko
  module Commands
    class Config < Thor
      # Validate configuration file
      #
      # Checks YAML syntax and required environment definitions
      #
      # @rbs () -> void
      desc "validate", "Validate configuration file"
      def validate
        return if validate_file_exists && validate_yaml_syntax && validate_environments

        exit 1
      end

      # Show configuration
      #
      # @rbs (String) -> void
      desc "show NAME", "Show configuration by name"
      def show(name)
        Picotorokko::Env.validate_env_name!(name)

        config = Picotorokko::Env.get_environment(name)
        if config
          puts JSON.pretty_generate(config)
        else
          warn "Environment not found: #{name}"
        end
      end

      private

      # @rbs () -> bool
      def validate_file_exists
        unless File.exist?(env_file)
          puts "✗ Configuration file not found: #{env_file}"
          return false
        end
        puts "✓ Configuration file found"
        true
      end

      # @rbs () -> bool
      def validate_yaml_syntax
        YAML.load_file(env_file)
        puts "✓ YAML syntax is valid"
        true
      rescue => e
        puts "✗ YAML syntax error: #{e.message}"
        false
      end

      # @rbs () -> bool
      def validate_environments
        config = YAML.load_file(env_file)
        return true if config.empty?

        config.each do |name, _|
          Picotorokko::Env.validate_env_name!(name)
        end
        puts "✓ All environment names are valid"
        true
      rescue => e
        puts "✗ Environment validation error: #{e.message}"
        false
      end

      def env_file
        File.join(Picotorokko::Env.project_root, ".picoruby-env.yml")
      end
    end
  end
end
```

**実行**:

```bash
bundle exec rake test → ✅
bundle exec rubocop -A → 修正
bundle exec rbs-inline --output sig lib
bundle exec steep check → ✅
bundle exec rake ci → ✅
```

### COMMIT

```bash
git add lib/picotorokko/commands/config.rb sig/picotorokko/commands/config.rbs test/commands/config_test.rb

git commit -m "feat: add config command for validation

Add 'ptrk config validate' to check .picoruby-env.yml syntax and structure.
Includes validation for environment names and YAML format.

Type-safe implementation with rbs-inline annotations."
```

---

## 実例: 既存機能の改善

### 例: env.rb に エラーハンドリング追加

**Goal**: validate_env_name! のエラーメッセージを改善

### ANNOTATION → RED → GREEN → REFACTOR → COMMIT

**Step 1: ANNOTATION (型を再確認)**

```ruby
# 既存の annotation を確認
# @rbs (String) -> void
def self.validate_env_name!(name)
  # 実装を改善 (GREEN フェーズ)
end
```

**Step 2: RED (テスト追加)**

```ruby
def test_validate_env_name_with_invalid_characters
  assert_raises(RuntimeError) do
    Picotorokko::Env.validate_env_name!("invalid name!")
  end
end

def test_validate_env_name_error_message_is_descriptive
  error = assert_raises(RuntimeError) do
    Picotorokko::Env.validate_env_name!("123-invalid")
  end
  assert_match(/must start with letter/, error.message)
end
```

**Step 3: GREEN (実装改善)**

```ruby
# @rbs (String) -> void
def self.validate_env_name!(name)
  case name
  when /\A[a-z0-9_-]+\z/i
    # Valid
  else
    raise RuntimeError, "Invalid environment name '#{name}': must contain only alphanumeric characters, hyphens, and underscores"
  end
end
```

**Step 4: REFACTOR (さらに改善)**

```ruby
VALID_ENV_NAME_PATTERN: Regexp #: Regexp

# Environment name must start with letter, contain only alphanumeric, hyphen, underscore
# @rbs () -> Regexp
def self.valid_env_name_pattern
  /\A[a-z][a-z0-9_-]*\z/i
end

# Validate environment name format
# @rbs (String) -> void
def self.validate_env_name!(name)
  return if valid_env_name_pattern.match?(name)

  raise RuntimeError, build_validation_error_message(name)
end

# @rbs (String) -> String
private_class_method def self.build_validation_error_message(name)
  "Invalid environment name '#{name}'. " \
  "Must start with a letter and contain only alphanumeric characters, hyphens, and underscores."
end
```

**Step 5: COMMIT**

```bash
git commit -m "refactor: improve env name validation error messages

Provide clearer error messages when environment name validation fails.
Extracted pattern to constant for reusability.

Maintains type safety via rbs-inline annotations."
```

---

## Quality Gates の統合

### Pre-Commit Checklist

```markdown
## Before Every Commit

### 1. ANNOTATION ✅
- [ ] Type signature defined via @rbs comment
- [ ] Description and @example included
- [ ] Type matches actual implementation intent

### 2. RED ✅
- [ ] Test written
- [ ] Test fails: bundle exec rake test → ❌

### 3. GREEN ✅
- [ ] bundle exec rake test → ✅
- [ ] bundle exec rbs-inline --output sig lib
- [ ] bundle exec steep check → ✅

### 4. RUBOCOP ✅
- [ ] bundle exec rubocop -A
- [ ] bundle exec rake test → ✅ (verify not broken)

### 5. REFACTOR ✅
- [ ] Code quality improved (not just passing tests)
- [ ] bundle exec rbs-inline --output sig lib
- [ ] bundle exec steep check → ✅
- [ ] bundle exec rake test → ✅

### 6. COMMIT ✅
- [ ] bundle exec rake ci → ✅
- [ ] git add . (all changed files including .rbs)
- [ ] git commit with descriptive message
- [ ] git log verify recent commits
```

---

## よくあるアンチパターン

### ❌ Anti-Pattern 1: 実装を先に書く

```ruby
❌ WRONG FLOW
class Config < Thor
  def validate
    # Implementation first!
    # ...
  end
end

# Then try to write test
def test_validate
  # ...
end
```

**問題**: テストが要件ではなく実装に従う（テストの意味なし）

**✅ 正しい流れ**:
```ruby
✅ RIGHT FLOW
# ANNOTATION
# @rbs () -> void
desc "validate", "Validate configuration"
def validate
  # No implementation yet
end

# RED
def test_validate
  # What should validate do?
end

# GREEN, REFACTOR, COMMIT
```

### ❌ Anti-Pattern 2: Annotation なしで実装

```ruby
❌ WRONG
def show(name)
  config = get_environment(name)
  puts JSON.pretty_generate(config)
end

# (no annotation!)
```

**問題**: 型安全性なし、IDE サポートなし、保守性低い

**✅ 正しい方法**:
```ruby
✅ RIGHT
# Show environment configuration
#
# @rbs (String) -> void
def show(name)
  config = get_environment(name)
  puts JSON.pretty_generate(config)
end
```

### ❌ Anti-Pattern 3: REFACTOR フェーズをスキップ

```ruby
❌ WRONG
# GREEN フェーズで止まる
def process(items)
  result = []
  items.each { |item| result << item.upcase }
  result
end

# すぐに COMMIT （品質改善なし）
```

**問題**: 技術負債蓄積、テストにだけ頼る

**✅ 正しい方法**:
```ruby
✅ RIGHT
# GREEN
def process(items)
  items.map(&:upcase)
end

# REFACTOR で改善
# @rbs (Array[String]) -> Array[String]
def process(items)
  items.map { |item| item.upcase }
end

# さらに改善
# @rbs (Array[String]) -> Array[String]
def process(items)
  items.map(&:upcase)
end

# COMMIT
```

---

## Tidy First との連携

### Tidy First: 小さな改善

> 「小さな改善を積み重ねることで、大きな変化を実現する」 (Kent Beck)

### REFACTOR フェーズで実践

**例1: メソッド抽出**

```ruby
# Before (Green)
def validate
  return unless File.exist?(env_file)
  YAML.load_file(env_file)
  puts "✓ Valid"
end

# After (Refactor - Tidy First)
def validate
  validate_file_exists
  validate_yaml_syntax
  puts "✓ Valid"
end

private

# @rbs () -> void
def validate_file_exists
  raise RuntimeError unless File.exist?(env_file)
end

# @rbs () -> void
def validate_yaml_syntax
  YAML.load_file(env_file)
end
```

**例2: 変数名改善**

```ruby
# Before
def show(name)
  x = get_environment(name)
  puts JSON.pretty_generate(x)
end

# After (Refactor - Tidy First)
# @rbs (String) -> void
def show(name)
  config = get_environment(name)
  puts JSON.pretty_generate(config)
end
```

**例3: エラーハンドリング追加**

```ruby
# Before (Green)
def show(name)
  config = get_environment(name)
  puts JSON.pretty_generate(config)
end

# After (Refactor - Tidy First)
# @rbs (String) -> void
def show(name)
  validate_env_name!(name)

  config = get_environment(name)
  if config
    puts JSON.pretty_generate(config)
  else
    warn "Not found: #{name}"
  end
end
```

### Tidy First + t-wada style TDD = 継続的品質向上

```
Micro-Cycle (1-5分)
  ↓
ANNOTATION → RED → GREEN → RUBOCOP → REFACTOR (Tidy First) → COMMIT
  ↓
品質が継続的に向上
```

---

## まとめ

### t-wada style TDD の 6 ステップ

1. **ANNOTATION**: 型で設計を明確化
2. **RED**: 要件をテストで表現
3. **GREEN**: 最小限で実装
4. **RUBOCOP**: スタイル統一
5. **REFACTOR**: 品質を継続的に改善（Tidy First）
6. **COMMIT**: 全ゲート通過で確認

### 本質

> **設計 → テスト → 実装 → 改善 → 品質向上**
>
> テストを書くことではなく、品質を継続的に向上させるプロセス

---

**ガイド作成日**: 2025-11-13
**対象**: すべての picotorokko 開発者
**参考**: CLAUDE.md, type-system-strategy.md, t-wada style TDD by Hiroshi Sano
