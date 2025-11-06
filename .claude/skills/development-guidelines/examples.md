# Documentation Examples

## Documentation Standards

- Add comments for non-obvious logic
- Document public methods with expected inputs/outputs
- Use structured comments for sections:

```ruby
# ============================================
# LED 制御モジュール
# ============================================

# パターン定義
PATTERNS = {
  pulse: [10, 20, 30, 20, 10],
  rainbow: [255, 0, 0, 255, 255, 0, 0, 255]
}
```

## File Headers

Not required for `.rb` files (embedded context is minimal). If needed:

```ruby
# R2P2-ESP32 LED animation engine
# Implements: WS2812B addressable RGB control

require 'atom'
```

## Testing & Verification

- Always test with `rake monitor` before commit
- Check memory usage: `rake check_env`
- Manual verification on hardware when possible
- Include expected behavior in commit messages

## References

- PicoRuby stdlib: Check `.claude/skills/picoruby-constraints/`
- Build system: Check `.claude/skills/project-workflow/`
