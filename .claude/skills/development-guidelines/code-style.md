# Ruby Code Style

## Naming

```ruby
# Constants: UPPER_SNAKE_CASE
LED_COUNT = 25
MAX_BRIGHTNESS = 255

# Methods: snake_case
def set_led_color(index, color)
  # ...
end

# Variables: snake_case
current_intensity = 100
sensor_readings = []
```

## Structure

- Keep methods short (<20 lines when possible)
- Avoid deep nesting (max 2-3 levels for embedded)
- Pre-allocate arrays and buffers
- Use early returns for error conditions

```ruby
def process_sensor_data(raw_data)
  return nil if raw_data.empty?

  # Process...
  normalized = normalize(raw_data)

  return nil if normalized.sum == 0

  apply_filter(normalized)
end
```

## Comments Placement

✅ Explain complex logic:
```ruby
# I2C スレーブアドレス。MPU6886 デフォルト
I2C_ADDR = 0x68
```

✅ Explain *why* a workaround exists:
```ruby
# メモリ制限のため、ローカル配列で予約
colors = Array.new(25, [0, 0, 0])
```

❌ State the obvious:
```ruby
# インクリメント
i += 1

# レッドチャネル設定
color[0] = 255
```

## Error Handling

Prefer defensive patterns:

```ruby
def safe_led_write(index, color)
  # ガード節で早期終了
  return false if index < 0 || index >= 25
  return false if color.nil? || color.size != 3

  # 本処理
  set_pixel(index, color)
  true
end
```

## Performance Considerations

- Minimize allocations in loops
- Cache computed values when used multiple times
- Use integer math when possible (avoid Float)
- Profile with `rake monitor` output
