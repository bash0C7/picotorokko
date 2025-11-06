# PicoRuby Code Examples and References

## Common Patterns

✅ **Good**:
```ruby
# Pre-allocate arrays
leds = Array.new(25, [0, 0, 0])

# Simple iteration
leds.each { |led| process(led) }

# Tail recursion converted to loop
depth = 0
while depth < max_depth
  process(depth)
  depth += 1
end
```

❌ **Avoid**:
```ruby
# Dynamic growth in loop
buffer = []
1000.times { |i| buffer << i }  # Memory spikes

# Deep nesting
def recursive_calc(n)
  recursive_calc(n - 1)  # Stack overflow risk
end

# Heavy string ops
str = ""
100.times { |i| str += i.to_s }  # Excessive allocation
```

## References

- R2P2-ESP32 GitHub: [picoruby](https://github.com/picoruby)
- ESP-IDF memory: heap fragmentation on embedded systems
