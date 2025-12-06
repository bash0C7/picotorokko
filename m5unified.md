# m5unified.rb Implementation Specification

M5UnifiedのC++ライブラリをPicoRubyから使用可能なmrbgemに自動変換するスクリプト。

---

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
├── CppParser (regex-based)
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
│   ├── render_cpp_wrapper()  - ports/esp32/m5unified_wrapper.cpp生成
│   └── render_ruby_lib()     - mrblib/m5unified.rb生成
├── CppWrapperGenerator
│   ├── generate()            - extern "C" ラッパー生成
│   ├── generate_wrapper_function() - C++ラッパー関数生成
│   └── flatten_method_name() - 名前空間フラット化
├── CMakeGenerator
│   ├── generate()            - CMakeLists.txt生成
│   └── generate_component_registration() - idf_component_register生成
├── ApiPatternDetector
│   ├── detect_patterns()     - M5Unified APIパターン検出
│   ├── detect_button_classes() - Buttonクラス検出
│   └── is_predicate_method?() - 述語メソッド判定
└── Entry point
    └── main()               - コマンドライン実行
```

---

## Implemented Features

### Repository Management
M5Unified リポジトリの管理（clone, update, info取得）

**実装内容**:
- `M5UnifiedRepositoryManager` クラス
- git コマンドでリポジトリをクローン・更新
- コミットハッシュとブランチ名を取得
- Open3でシェルコマンド実行

---

### Header File Reading & C++ Parsing
C++ヘッダーファイルの読み込みと軽量パース

**実装内容**:
- `HeaderFileReader` クラス - `.h`ファイルを列挙・読込
- `CppParser` クラス - 正規表現ベースの軽量パーサー
- クラス・メソッド・パラメータ抽出
- namespace対応（完全なASTパースではなく実用的な正規表現パース）

---

### Type Mapping
C++ 型から mruby 型への自動変換

**実装内容**:
- `TypeMapper` クラス
- 13種類の整数型対応（int, int8_t～int64_t, uint8_t～uint64_t, unsigned int, long, unsigned long, size_t）
- float, double, bool, char*, void型対応
- const修飾子とリファレンス型の自動正規化
- ポインタ型判定

**型マッピングテーブル**:
```
C++型                  → mruby型
int, int8_t, ...
uint8_t, ..., size_t   → MRBC_TT_INTEGER
float, double          → MRBC_TT_FLOAT
const char*, char*     → MRBC_TT_STRING
bool                   → MRBC_TT_TRUE
void                   → nil
Type*（ポインタ）      → MRBC_TT_OBJECT
Type&（参照型）        → ポインタとして扱う
```

---

### mrbgem Directory Structure Generation
mrbgem用のディレクトリ構造とテンプレート生成

**実装内容**:
- `MrbgemGenerator` クラス
- ディレクトリ構造自動作成
- 各テンプレートファイルの自動生成

**生成ディレクトリ構造**:
```
mrbgem-picoruby-m5unified/
├── mrbgem.rake
├── mrblib/
│   └── m5unified.rb
├── src/
│   └── m5unified.c
├── ports/
│   └── esp32/
│       └── m5unified_wrapper.cpp
├── CMakeLists.txt
└── README.md
```

---

### C Binding Code Generation
mrubyc用のCバインディングコード自動生成

**実装内容**:
- Forward declarations（static mrbc_class ポインタ）
- Method wrappers（mrbc_m5unified_* 関数）
- Parameter type conversion（型別にGET_*_ARG マクロ生成）
- Return value marshalling（型別にSET_RETURN_* マクロ生成）
- gem_init関数生成（mrbc_define_class/method呼び出し）

**生成コード例**:
```c
/* Forward declarations */
static mrbc_class *c_M5Display;

/* Method wrapper */
static void mrbc_m5unified_begin(mrbc_vm *vm, mrbc_value *v, int argc) {
  M5.begin();
  SET_RETURN(mrbc_nil_value());
}

void mrbc_m5unified_gem_init(mrbc_vm *vm) {
  c_M5Display = mrbc_define_class(vm, "M5Display", 0, 0, 0);
  mrbc_define_method(vm, c_M5Display, "begin", mrbc_m5unified_begin);
}
```

**型別パラメータ変換**:
- `MRBC_TT_INTEGER` → `GET_INT_ARG(n)`
- `MRBC_TT_FLOAT` → `GET_FLOAT_ARG(n)`
- `MRBC_TT_STRING` → `GET_STRING_ARG(n)`
- `MRBC_TT_OBJECT` → `GET_OBJECT_ARG(n)`

**型別戻り値マーシャリング**:
- `MRBC_TT_INTEGER` → `SET_RETURN_INTEGER(vm, 0);`
- `MRBC_TT_FLOAT` → `SET_RETURN_FLOAT(vm, 0.0);`
- `MRBC_TT_STRING` → `SET_RETURN_STRING(vm, "");`
- `nil` → `/* void return */`

---

### C++ Wrapper & CMake Generation
extern "C" ラッパー関数生成と ESP-IDF CMakeLists.txt 生成

**実装内容**:
- `CppWrapperGenerator` クラス
  - extern "C" ラッパーファイル（m5unified_wrapper.cpp）生成
  - 名前空間フラット化（M5.BtnA.wasPressed → m5unified_btnA_wasPressed）
  - 戻り値型自動変換（bool → int）
  - M5Unified API呼び出しの実装

- `CMakeGenerator` クラス
  - CMakeLists.txt 自動生成
  - idf_component_register() ブロック生成
  - ソースファイルと依存関係の設定

**生成ファイル例** (m5unified_wrapper.cpp):
```cpp
#include <M5Unified.h>

extern "C" {
  void m5unified_begin(void) {
    M5.begin();
  }

  int m5unified_btnA_wasPressed(void) {
    return M5.BtnA.wasPressed();
  }
}
```

---

### M5Unified API Pattern Detection
M5Unified固有のAPIパターン自動検出と最適化

**実装内容**:
- `ApiPatternDetector` クラス
- Button → BtnA/BtnB/BtnC singleton マッピング
- Ruby述語接尾辞の自動付与（wasPressed → wasPressed?）
- Display class 検出と特別処理

**検出パターン例**:
```ruby
{
  button_classes: ["Button"],
  singleton_mapping: { "Button" => ["BtnA", "BtnB", "BtnC"] },
  predicate_methods: ["wasPressed", "isPressed"],
  display_classes: ["Display"]
}
```

---

### End-to-End Integration
実際のM5Unifiedリポジトリを使用した統合テスト

**実装内容**:
- M5Unifiedリポジトリのクローン
- ヘッダーファイル自動列挙
- C++ パース・型マッピング
- mrbgem生成・検証
- 生成されたコード品質確認

---

## Dependencies

### Required Gems
```ruby
gem "test-unit"
gem "rubocop"
```

### System Requirements
- Ruby 3.4+
- git (for repository management)
- C++ compiler (for ESP32 compilation, not required for code generation)

---

## Remaining Work

### Phase 3: Integration Testing with Actual M5Unified

実装済みのm5unified.rbスクリプトを使用して、実際のM5Unifiedリポジトリでの E2E テストを実施。

**タスク**:
- 実際の M5Unified リポジトリをクローンして、生成されたmrbgemをコンパイル
- ESP32実機でのコンパイル・動作確認
- 生成されたコードが正確にM5Unifiedの全APIをカバーしていることを検証
- エッジケース（特殊な型、複雑なパラメータ）への対応確認

---

## References

- [M5Unified GitHub](https://github.com/m5stack/M5Unified)
- [mrubyc API Reference](https://github.com/mrubyc/mrubyc)
- [PicoRuby Documentation](https://github.com/picoruby/picoruby)
- [Blog: PicoRubyでM5Unifiedを使う](https://blog.silentworlds.info/picorubyxiang-kenom5unified-m5gfx-mrbgemwozuo-ruhua/)
