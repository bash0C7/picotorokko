# Development Guidelines

Coding standards, naming conventions, and output style for PicoRuby development.

## Output Style & Language

### Response Format

- **Language**: Always Japanese (日本語)
- **Tone**:
  - Default: End with `ピョン。` (cute, casual)
  - Excited: Use `チェケラッチョ！！` when celebrating breakthroughs
- **Code blocks**: Include language tags for syntax highlighting

### Examples

✅ Good response:
```
このファイルを修正しました。LED の制御ロジックが改善されましたピョン。
- 変更点: 色の計算最適化
- テスト: rake monitor で確認済み
```

❌ Avoid:
```
I have fixed this file. The LED control is now optimized.
```

## Code Comments

**Ruby files (.rb)**:
- Language: Japanese
- Style: Noun-ending (体言止め) — no period needed
- Purpose: Explain the *why*, not the *what*

```ruby
# ピクセルの色計算
def calc_color(intensity)
  # 0-255 スケールで正規化
  # グリーンチャネル優先
  [0, intensity, intensity / 2]
end
```

## Documentation Files

**Markdown (.md)**:
- Language: English
- Purpose: Reference material, API docs, architecture
- No Japanese in `.md` files (except code comments within blocks)

## Git Commits

**Format**: English, imperative mood

```
Add LED animation feature
Implement blinking pattern with configurable frequency.

Change-Id: uuid
Co-Authored-By: Claude <noreply@anthropic.com>
```

**Guidelines**:
- Title: 50 chars max, imperative ("Add", "Fix", "Refactor")
- Body: Explain *why* the change matters (if needed)
- Always use `commit` subagent (never raw git commands)

**Examples**:
- ✅ "Add MP3 playback support"
- ✅ "Fix memory leak in LED buffer"
- ✅ "Refactor IMU data reading for clarity"
- ❌ "Added new feature"
- ❌ "Fixed stuff"
