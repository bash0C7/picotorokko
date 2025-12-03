# m5unified.rb Implementation Specification

プロトタイプ実装によるM5Unified mrbgem自動生成ツール。すべてのロジックをシングルファイル（`m5unified.rb`）に集約し、t-wada style TDDで段階的に実装。

## Overview

M5UnifiedのC++ライブラリをPicoRubyから使用可能なmrbgemに自動変換するスクリプト。以下のステップで処理：

1. M5Unifiedリポジトリの管理（clone/update）
2. C++ヘッダーの読み込み
3. tree-sitterによるC++パース
4. 型マッピング
5. mrbgem生成

## Architecture

```
m5unified.rb (single file)
├── M5UnifiedRepositoryManager
│   ├── clone(url, branch)    - リポジトリをクローン
│   ├── update()              - git pull で更新
│   └── info()                - コミット・ブランチ情報取得
├── HeaderFileReader
│   ├── list_headers()        - .hファイルを列挙
│   └── read_file(path)       - ファイル内容を読み込み
├── CppParser (tree-sitter)
│   ├── parse(header_content) - C++をパース
│   ├── extract_classes()     - クラス定義抽出
│   ├── extract_methods()     - メソッド定義抽出
│   └── extract_types()       - パラメータ・戻り値の型抽出
├── TypeMapper
│   ├── map_type(cpp_type)    - C++型をmruby型に変換
│   └── generate_conversion() - 型変換コード生成
├── MrbgemGenerator
│   ├── generate()            - 全体のオーケストレーション
│   ├── create_structure()    - ディレクトリ構造作成
│   ├── render_mrbgem_rake()  - mrbgem.rake生成
│   ├── render_c_bindings()   - src/m5unified.c生成
│   └── render_ruby_lib()     - mrblib/m5unified.rb生成
└── Entry point
    └── main() - コマンドライン実行
```

## Implemented Components

### ✅ Phase 1.1: M5Unified Repository Management

**状態**: 完了
**ファイル**: `m5unified.rb` (lines 1-57)
**テスト**: `m5unified_test.rb` (test_clone_m5unified_repository, test_update_existing_repository, etc.)

**機能**:
- `M5UnifiedRepositoryManager` クラス
  - `new(path)` - 管理オブジェクト初期化
  - `clone(url:, branch:)` - リポジトリをクローン
  - `update()` - 既存リポジトリを`git pull`で更新
  - `info()` - コミットハッシュとブランチ名を返す
  - `path` - リポジトリパス（attr_reader）

**テスト**:
```ruby
✓ test_clone_m5unified_repository
✓ test_update_existing_repository
✓ test_repository_path_returns_correct_path
✓ test_repository_info_contains_required_fields
```

**詳細**:
- `vendor/m5unified/`ディレクトリにクローン
- 既存ディレクトリがある場合は削除して再クローン
- git pull で最新版に更新可能
- Open3でシェルコマンド実行

**制約**:
- git コマンドがインストール済みであることが前提
- インターネット接続が必要（クローン時）

---

### ✅ Phase 1.2: C++ Header File Enumeration and Reading

**状態**: 完了
**ファイル**: `m5unified.rb` (lines 59-88)
**テスト**: `m5unified_test.rb` (test_enumerate_header_files_from_repository, test_read_header_file_content)

**機能**:
- `HeaderFileReader` クラス
  - `new(repo_path)` - リーダー初期化
  - `list_headers()` - `.h`ファイルを列挙（src/, include/から）
  - `read_file(file_path)` - ファイル内容を読み込み

**テスト**:
```ruby
✓ test_enumerate_header_files_from_repository
✓ test_read_header_file_content
```

**詳細**:
- `src/`と`include/`ディレクトリを検索
- `Dir.glob("**/*.h")`で再帰的に`.h`ファイルを検出
- ファイルを昇順でソート
- `File.read()`で内容を読み込み
- ファイル存在チェック（存在しない場合は例外）

**制約**:
- `src/`または`include/`ディレクトリが存在しない場合はスキップ（エラーなし）
- バイナリファイルの処理は考慮していない（テキストファイルのみ）

---

### ✅ Phase 1.3: C++ Parsing with tree-sitter

**状態**: 完了（正規表現ベースの実装）
**ファイル**: `m5unified.rb` (lines 90-161)
**テスト**: `m5unified_test.rb` (test 7-10)

**機能**:
- `CppParser` クラス
  - `new(code)` - C++コードを初期化
  - `extract_classes()` - クラス定義を抽出

**テスト**:
```ruby
✓ test_cpp_parser_extracts_class_names
✓ test_cpp_parser_extracts_method_names
✓ test_cpp_parser_extracts_return_types
✓ test_cpp_parser_extracts_parameters
```

**詳細実装**:
- 正規表現ベースの軽量パーサー（tree-sitterの依存を避ける）
- `class ClassName { ... };` パターンをマッチ
- メソッド宣言パターン：`return_type method_name(params);`
- パラメータをカンマで分割し、型名を抽出
- 複数メソッド・パラメータに対応

**データ構造**:
```ruby
{
  name: "ClassName",
  methods: [
    {
      name: "methodName",
      return_type: "int",
      parameters: [
        { type: "int", name: "x" },
        { type: "float", name: "y" }
      ]
    }
  ]
}
```

**今後の改善**:
- ruby_tree_sitterを使った完全なASTパース（namespace対応など）
- const修飾子・static修飾子の抽出
- テンプレートメソッドの処理

---

### ✅ Phase 1.4: Type Mapping

**状態**: 完了
**ファイル**: `m5unified.rb` (lines 163-207)
**テスト**: `m5unified_test.rb` (test 11-14)

**機能**:
- `TypeMapper` クラス
- C++ 型から mrubyc 型への変換

**実装内容**:
- `TypeMapper.map_type(cpp_type)` - C++型をmrubyc型に変換
- `normalize_type(cpp_type)` - const修飾子・参照型を正規化
- `pointer_type?(cpp_type)` - ポインタ型判定
- `TYPE_MAPPING` ハッシュ - 型マッピングテーブル

**型マッピングテーブル**:
```
C++型                  → mrubyc型
int, int8_t, ...,
uint8_t, ..., size_t   → MRBC_TT_INTEGER
float, double          → MRBC_TT_FLOAT
const char*, char*     → MRBC_TT_STRING
bool                   → MRBC_TT_TRUE
void                   → nil
Type*（ポインタ）      → MRBC_TT_OBJECT
Type&（参照型）        → ポインタとして扱う
```

**テスト結果**:
```ruby
✓ test_type_mapper_maps_integer_types
✓ test_type_mapper_maps_float_types
✓ test_type_mapper_maps_string_and_bool_types
✓ test_type_mapper_maps_void_and_pointer_types
```

**詳細実装**:
- クラスメソッドのみ（stateless design）
- 13種類の整数型サポート（int, int8_t～int64_t, uint8_t～uint64_t, unsigned int, long, unsigned long, size_t）
- const修飾子とリファレンス型を自動削除
- char* は MRBC_TT_STRING、その他ポインタは MRBC_TT_OBJECT
- 未知の型はデフォルト MRBC_TT_OBJECT

---

### ✅ Phase 1.5: mrbgem Directory Structure Generation

**状態**: 完了
**ファイル**: `m5unified.rb` (lines 210-292)
**テスト**: `m5unified_test.rb` (test 15-25)

**機能**:
- `MrbgemGenerator` クラス
- mrbgem ディレクトリ構造生成
- テンプレートファイル生成

**実装内容**:
- `MrbgemGenerator.new(output_path)` - 初期化
- `generate(cpp_data)` - メイン処理
- `create_structure` - ディレクトリ作成
- `render_mrbgem_rake` - mrbgem.rake 生成
- `render_c_bindings(cpp_data)` - C バインディングスケルトン生成
- `render_ruby_lib(cpp_data)` - Ruby ドキュメント生成
- `render_readme(cpp_data)` - README 生成

**生成ディレクトリ構造**:
```
mrbgem-picoruby-m5unified/
├── mrbgem.rake              # Gem specification
├── mrblib/
│   └── m5unified.rb         # Ruby documentation
├── src/
│   └── m5unified.c          # C binding skeleton
└── README.md                # Gem documentation
```

**テスト結果**:
```ruby
✓ test_mrbgem_generator_initializes_with_output_path
✓ test_mrbgem_generator_creates_directory_structure
✓ test_mrbgem_generator_creates_mrbgem_rake
✓ test_mrbgem_generator_creates_mrblib_ruby
✓ test_mrbgem_generator_creates_src_c
✓ test_mrbgem_generator_creates_readme
✓ test_mrbgem_rake_contains_specification
✓ test_mrblib_ruby_lists_classes
✓ test_src_c_includes_class_definitions
✓ test_mrbgem_generator_generate_returns_true
✓ test_mrbgem_generator_handles_empty_data
```

**詳細実装**:
- インスタンス初期化で output_path を保持
- generate() メソッドで各テンプレート生成を実行
- 文字列連結によるシンプルなテンプレート実装
- 動的コンテンツは cpp_data から抽出したクラス名を使用

---

### ⏳ Phase 1.6: C Binding Code Generation

**状態**: 未実装
**ファイル**: `m5unified.rb` (予定)
**テスト**: `m5unified_test.rb` (予定)

**生成対象コード**:
- `mrbgem.rake` - ビルド設定
- `src/m5unified.c` - Cバインディング実装
  - `mrbc_define_class()` コード
  - `mrbc_define_method()` コード
  - 型変換関数
- `mrblib/m5unified.rb` - Rubyドキュメント

**テスト計画**:
- Cコードが構文的に正確に生成される
- クラス・メソッド定義が正確に出力される

---

## Development Process

### TDD Cycle (t-wada style)

各マイクロサイクル（Phase）で以下を実施：

1. 🔴 **Red**: テストを書いて失敗させる
2. 🟢 **Green**: 最小限のコードで通す
3. 🔧 **RuboCop**: `bundle exec rubocop m5unified.rb m5unified_test.rb --autocorrect-all`
4. ♻️ **Refactor**: コードをクリーンアップ
5. 💾 **Commit**: git add & commit

### Completed Cycles

#### Cycle 1: M5Unified Repository Management

- **Red**: Repository manager テストを4つ追加
- **Green**: M5UnifiedRepositoryManager クラス実装
- **RuboCop**: 30 offenses corrected, 1 offense remains (documentation comment)
- **Refactor**: 完了
- **Commit**: `Implement M5Unified repository manager with clone and update operations`

#### Cycle 2: C++ Header File Enumeration and Reading

- **Red**: HeaderFileReader テストを2つ追加（失敗：NameError）
- **Green**: HeaderFileReader クラス実装（list_headers, read_file）
- **RuboCop**: 4 offenses corrected
- **Refactor**: 完了
- **Commit**: `Implement C++ header file reader for M5Unified repository`

#### Cycle 3: C++ Parsing with Regex-based Parser

- **Red**: CppParser テストを4つ追加（失敗：NameError）
- **Green**: CppParser クラス実装（正規表現ベース）
  - クラス・メソッド・パラメータ抽出
  - ruby_tree_sitter依存回避
- **RuboCop**: 0 offenses corrected (1 documentation warning ignored)
- **Refactor**: 完了
- **Commit**: `Implement C++ parser with regex-based method extraction`

#### Cycle 4: Type Mapping

- **Red**: TypeMapper テストを4つ追加（失敗：NameError）
- **Green**: TypeMapper クラス実装
  - map_type() メソッド
  - normalize_type() - const/参照型正規化
  - pointer_type?() - ポインタ判定
  - TYPE_MAPPING ハッシュ（13種類の整数型対応）
- **RuboCop**: 3 offenses corrected (1 documentation warning remains)
- **Refactor**: 完全な TYPE_MAPPING を追加（すべての整数型バリエーション対応）
- **Commit**: `Implement TypeMapper class for C++ to mruby type conversion`

#### Cycle 5: mrbgem Directory Structure Generation

- **Red**: MrbgemGenerator テストを11個追加（失敗：NameError）
- **Green**: MrbgemGenerator クラス実装
  - initialize(output_path) - 初期化
  - generate(cpp_data) - メイン処理
  - create_structure - ディレクトリ作成
  - render_mrbgem_rake - mrbgem.rake 生成
  - render_c_bindings - C スケルトン生成
  - render_ruby_lib - Ruby ドキュメント生成
  - render_readme - README 生成
- **RuboCop**: 15 offenses corrected (2 warnings remain - acceptable)
- **Refactor**: 最小限（コード品質良好）
- **Commit**: `Implement mrbgem directory structure generation`

---

## Testing Strategy

### Test Structure

- `m5unified_test.rb` - test/unit 使用
- 各マイクロサイクルで新しいテストを追加
- テストが通ってからRefactor/Commit

### Test Execution

```bash
ruby -I. m5unified_test.rb
```

**現在の状態**:
```
10 tests, 22 assertions, 0 failures, 0 errors
```

---

## Code Quality

### RuboCop Status

**Last run**: After Phase 1.1 implementation
- **Total offenses**: 30 (all corrected)
- **Remaining offenses**: 1 (Style/Documentation - expected, can be ignored)
- **Status**: ✅ PASS

### Metrics

- Lines of code: ~57 (M5UnifiedRepositoryManager)
- Test coverage: 4 tests covering all public methods
- Cyclomatic complexity: Low (simple, straightforward logic)

---

## Dependencies

### Required Gems

```ruby
# Gemfile (existing)
gem "test-unit"

# Gemfile (to be added in Phase 1.3)
gem "tree_sitter", "~> 1.0"
```

### System Requirements

- Ruby 3.4+
- git (for repository management)
- tree-sitter (will be installed via gem in Phase 1.3)

---

## Next Steps

1. **Phase 1.2**: C++ Header File Enumeration and Reading
   - Implement `HeaderFileReader` class
   - Test `.h` file enumeration in M5Unified repo
   - Handle multiple directories (src/, include/)

2. **Phase 1.3**: C++ Parsing with tree-sitter
   - Add `gem 'tree_sitter'` to Gemfile
   - Implement `CppParser` class
   - Extract class and method signatures

3. **Phase 1.4**: Type Mapping
   - Implement `TypeMapper` class
   - Create mapping tables for C++ ↔ mruby types

4. **Phase 1.5**: mrbgem Structure Generation
   - Implement `MrbgemGenerator` class
   - Create directory and file structure

5. **Phase 1.6**: C Binding Code Generation
   - Generate mrbgem.rake
   - Generate src/m5unified.c with bindings
   - Generate mrblib/m5unified.rb documentation

6. **Phase 2**: Thor Integration
   - Split `m5unified.rb` into `lib/picotorokko/m5unified/`
   - Create `lib/picotorokko/commands/m5unified.rb`
   - Integrate with `ptrk` CLI

---

## Notes

- **Prototype approach**: すべてのロジックを1ファイルに詰め込み、動作を確認してからモジュール分割
- **TDD discipline**: 完璧なRed → Green → RuboCop → Refactor → Commitサイクルを維持
- **Documentation**: このmdファイルを常に最新状態に保ち、別セッションでの継続を容易に

---

## References

- [M5Unified GitHub](https://github.com/m5stack/M5Unified)
- [tree-sitter Ruby binding](https://github.com/tree-sitter/ruby-tree-sitter)
- [mrubyc API Reference](https://github.com/mrubyc/mrubyc)
- [Blog: PicoRubyでM5Unifiedを使う](https://blog.silentworlds.info/picorubyxiang-kenom5unified-m5gfx-mrbgemwozuo-ruhua/)

