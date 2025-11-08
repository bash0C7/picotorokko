# TODO: mrbgems Support Implementation

アプリケーション専用PicoRuby mrbgem（App）の雛形生成・管理機能を実装するピョン。

**関連ドキュメント**: [CLAUDE.md](CLAUDE.md) のTODO Management セクション

---

## 🎯 機能概要

`pra mrbgems generate` コマンドと `pra build setup` の拡張で、以下を実現：

1. **テンプレート生成**: `mrbgems/App/` ディレクトリに Rubyクラス + C拡張を生成
2. **Build Config登録**: `patch/picoruby/build_config/xtensa-esp.rb` で `conf.gem local: '../../../../mrbgems/App'` を自動追加
3. **CMakeLists.txt登録**: `patch/picoruby-esp32/CMakeLists.txt` で App/src/app.c をSRCSに追加
4. **パッチシステム統合**: 既存のpatchシステムで自分用にカスタマイズ可能

---

## Phase 1: 基盤調査（実装前の検証）

### 1-1. picoruby-irqの実装パターン確認

- [ ] **picoruby-irqのファイル構造を確認**
  ```bash
  # /tmp にクローン
  git clone --depth 1 https://github.com/picoruby/picoruby.git /tmp/picoruby

  # 確認対象ファイル
  cat /tmp/picoruby/mrbgems/picoruby-irq/mrbgem.rake
  cat /tmp/picoruby/mrbgems/picoruby-irq/mrblib/irq.rb
  ls -la /tmp/picoruby/mrbgems/picoruby-irq/src/
  cat /tmp/picoruby/mrbgems/picoruby-irq/src/irq.c
  ```
- [ ] **確認項目**:
  - [ ] PICORUBY_VM_MRUBYCマクロの使い方
  - [ ] クラスメソッドのみを提供する実装パターン
  - [ ] 初期化関数の命名規則（mrbc_xxx_init）
  - [ ] mrbgem.rakeの依存関係記述方法

### 1-2. xtensa-esp.rbの相対パス検証

- [ ] **テスト環境をセットアップして実ファイルを確認**
  ```bash
  # 既存環境がなければセットアップ
  pra build setup test-env

  # build_configファイルを確認
  cat build/current/R2P2-ESP32/components/picoruby-esp32/picoruby/build_config/xtensa-esp.rb

  # ディレクトリ相対関係を確認
  ls -la build/current/R2P2-ESP32/
  pwd  # ビルド時のカレントディレクトリを記録
  ```
- [ ] **確認項目**:
  - [ ] build_config実行時のカレントディレクトリ
  - [ ] 既存mrbgemの登録パターン（core:, github:, local:）
  - [ ] `conf.gem local:` で相対パス指定が機能するか

### 1-3. CMakeLists.txtのAPP mrbgem追加パターン検証

- [ ] **picoruby-esp32 CMakeLists.txtの構造確認**
  ```bash
  cat build/current/R2P2-ESP32/components/picoruby-esp32/CMakeLists.txt | head -50
  ```
- [ ] **確認項目**:
  - [ ] ${COMPONENT_DIR}からの相対パス計算方法
  - [ ] SRCSセクションへの追加位置
  - [ ] 既存mrbgemsの記載パターン

---

## Phase 2: テンプレートファイル実装

### 2-1. テンプレートディレクトリ作成

- [ ] Create `lib/pra/templates/mrbgem_app/` directory structure

### 2-2. mrbgem.rake.erb実装

- [ ] Write `lib/pra/templates/mrbgem_app/mrbgem.rake.erb`

### 2-3. mrblib/app.rb.erb実装

- [ ] Write `lib/pra/templates/mrbgem_app/mrblib/app.rb.erb`

### 2-4. src/app.c.erb実装

- [ ] Write `lib/pra/templates/mrbgem_app/src/app.c.erb`
  - PICORB_VM_MRUBYCマクロで囲む
  - `mrbc_<%= c_prefix %>_init()` 初期化関数を定義
  - `<%= class_name %>.version` クラスメソッドを実装（整数を返す）
  - コメントは日本語、体言止め

### 2-5. README.md.erb実装

- [ ] Write `lib/pra/templates/mrbgem_app/README.md.erb`

---

## Phase 3: `pra mrbgems`コマンド実装

### 3-1. コマンドクラス実装

- [ ] Create `lib/pra/commands/mrbgems.rb`
  - `generate(name = 'App')` メソッド実装
  - テンプレート変数定義

### 3-2. テストファイル実装

- [ ] Create `test/commands/mrbgems_test.rb`

### 3-3. CLIエントリーポイント更新

- [ ] Update `lib/pra/cli.rb`

### 3-4. ヘルプ表示確認

- [ ] Test: `pra help mrbgems` and `pra mrbgems generate --help`

---

## Phase 4: `pra build setup`拡張

### 4-1. Appのmrbgem雛形自動生成

- [ ] Extend `lib/pra/commands/build.rb` setup method

### 4-2. build_configパッチ自動生成

- [ ] Implement `generate_build_config_patch()` method
  - Patch content: Add line `conf.gem local: '../../../../mrbgems/App'`

### 4-3. CMakeLists.txtパッチ自動生成

- [ ] Implement `generate_cmake_patch()` method
  - Patch content: Add SRCS line `${COMPONENT_DIR}/../../mrbgems/App/src/app.c`

### 4-4. パッチ生成タイミング調整

- [ ] Modify `pra build setup` flow

### 4-5. テスト実装

- [ ] Test: `pra build setup` generates all App files

---

## Phase 5: ドキュメント整備

### 5-1. README.mdに`pra mrbgems`セクション追加

- [ ] Add section with usage example and structure

### 5-2. mrbgem開発ガイド作成

- [ ] Create `docs/MRBGEMS_GUIDE.md`

---

## 🔧 技術詳細

### 生成ディレクトリ構造

```
project_root/
├── mrbgems/
│   └── App/
│       ├── mrbgem.rake
│       ├── mrblib/
│       │   └── app.rb          # Class App定義
│       ├── src/
│       │   └── app.c           # mrbc_app_init関数
│       └── README.md
├── patch/
│   ├── picoruby/
│   │   └── build_config/
│   │       └── xtensa-esp.rb   # conf.gem local追加
│   └── picoruby-esp32/
│       └── CMakeLists.txt      # SRCS追加
└── .picoruby-env.yml
```

### テンプレート変数マッピング

| 変数 | デフォルト |
|------|-----------|
| `mrbgem_name` | "App" |
| `class_name` | "App" |
| `c_prefix` | "app" |
| `author_name` | git config user.name |

### build_configパッチ仕様

```ruby
conf.gem local: '../../../../mrbgems/App'
```

相対パス: 起点（build_config/）から4階層上 → mrbgems/App

### CMakeLists.txtパッチ仕様

```cmake
${COMPONENT_DIR}/../../mrbgems/App/src/app.c
```

相対パス: 起点（picoruby-esp32/）から2階層上 → mrbgems/App/src/app.c

---

## ✅ 実装完了基準

- [ ] Phase 1: 調査・検証完了
- [ ] Phase 2: テンプレートファイル作成完了
- [ ] Phase 3: コマンド・テスト完了
- [ ] Phase 4: build setup拡張・パッチ生成完了
- [ ] Phase 5: ドキュメント整備完了
