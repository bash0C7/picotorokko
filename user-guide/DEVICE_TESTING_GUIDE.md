# PicoRuby Device Testing Guide

## Introduction

This guide explains how to write and run tests for PicoRuby applications on actual devices (ESP32) using the Picotest framework integrated with ptrk.

**Key Features**:
- Test code generated automatically by `ptrk init`
- Hardware mocking with Picotest doubles (no special hardware setup needed)
- Run tests on actual ESP32 devices with real hardware interaction
- CI/CD integration support
- Serial output parsing for automated validation

---

## Quick Start

### 1. Initialize Project with Test Template

```bash
ptrk init my-sensor-app
cd my-sensor-app
```

This creates a project structure with:
- `test/app_test.rb` - Generated test template with examples
- `Mrbgemfile` - Includes `picoruby-picotest` dependency
- `storage/home/app.rb` - Application entry point

### 2. Review Generated Test Template

```bash
cat test/app_test.rb
```

The template includes:
- Basic assertion examples
- Stub example (ADC hardware)
- Any-instance stub example (GPIO)
- Mock example with call count verification
- Conditional stub example (I2C with multiple addresses)
- Complete API reference comments

### 3. Write Your First Test

Edit `test/sensor_test.rb`:

```ruby
# test/sensor_test.rb
class SensorTest < Picotest::Test
  def setup
    # Optional: setup code run before each test
  end

  def test_read_temperature
    # Stub ADC hardware (no actual hardware needed)
    stub_any_instance_of(ADC).read_raw { 750 }

    # Create sensor and test logic
    sensor = Sensor.new(27)
    result = sensor.read_temperature

    # 750 raw value → (750 - 500) / 10.0 = 25.0°C
    assert_equal 25.0, result
  end

  def teardown
    # Optional: cleanup code run after each test
    # Picotest doubles are automatically cleaned up
  end
end
```

### 4. Run Tests on Device

**Step 1: Build with test code**
```bash
ptrk device build --test
```

**Step 2: Flash to ESP32**
```bash
ptrk device flash
```

**Step 3: Monitor and parse results**
```bash
ptrk device monitor --test
```

You should see:
```
Running SensorTest...
  test_read_temperature . PASS

Summary
SensorTest:
  success: 1, failure: 0, exception: 0, crash: 0

Total: success: 1, failure: 0, exception: 0, crash: 0

=== Picotest completed (exit code: 0) ===

✓ test_read_temperature
Summary: 1 passed, 0 failed
```

---

## Picotest Doubles Reference

### What are Picotest Doubles?

Picotest doubles allow you to:
- **Replace hardware method behavior** without actual hardware
- **Verify method calls** were made (useful for testing hardware interaction code)
- **Return different values** based on arguments
- **Mock C extension methods** (GPIO, I2C, ADC, SPI, etc.)

### Stub (Replace Return Value)

A stub replaces a method's return value. Use when you only care about what the method returns.

#### Single Instance Stub

```ruby
def test_adc_single_instance
  # Create object
  adc = ADC.new(27)

  # Stub read_raw to return 750
  stub(adc).read_raw { 750 }

  # Now this ADC instance always returns 750
  assert_equal 750, adc.read_raw
  assert_equal 750, adc.read_raw  # Still 750
end
```

#### All Instances Stub

Use `stub_any_instance_of` when you don't control object creation or want to stub the entire class.

```ruby
def test_gpio_all_instances
  # Stub ALL GPIO instances
  stub_any_instance_of(GPIO).read { 1 }

  # Both instances return stubbed value
  gpio1 = GPIO.new(5, GPIO::IN)
  gpio2 = GPIO.new(10, GPIO::IN)

  assert_equal 1, gpio1.read
  assert_equal 1, gpio2.read
end
```

### Mock (Replace Return Value + Verify Call Count)

A mock is like a stub, but also verifies the method was called the expected number of times.

#### Verify Exact Call Count

```ruby
def test_led_blink
  # Expect set_level to be called exactly 4 times
  mock_any_instance_of(GPIO).set_level(4) { nil }

  # Create LED and blink
  led = LED.new(2)
  led.blink(2)  # 2 blinks = 4 calls to set_level (ON/OFF × 2)

  # Teardown automatically verifies: was called exactly 4 times?
  # If not (e.g., 3 or 5 times), test fails
end
```

### Conditional Stubs (Return Different Values)

Use a block to return different values based on method arguments.

#### By Address (I2C Example)

```ruby
def test_i2c_multiple_addresses
  stub_any_instance_of(I2C).read do |address, length|
    case address
    when 0x50 then [0x12, 0x34]      # Sensor 1
    when 0x51 then [0xAA, 0xBB]      # Sensor 2
    else [0x00]                        # Default
    end
  end

  i2c = I2C.new(0, sda: 21, scl: 22)

  assert_equal [0x12, 0x34], i2c.read(0x50, 2)
  assert_equal [0xAA, 0xBB], i2c.read(0x51, 2)
  assert_equal [0x00],       i2c.read(0x99, 2)
end
```

#### By Pin Number (GPIO Example)

```ruby
def test_gpio_state_by_pin
  stub_any_instance_of(GPIO).read do
    # Return different values for different pins
    @pin ||= extract_pin_from_context

    case @pin
    when 5 then 1
    when 10 then 0
    else -1
    end
  end

  gpio1 = GPIO.new(5, GPIO::IN)
  gpio2 = GPIO.new(10, GPIO::IN)

  assert_equal 1, gpio1.read
  assert_equal 0, gpio2.read
end
```

---

## Real-World Examples

### Example 1: Temperature Sensor

**Application Code** (`storage/home/sensor.rb`):
```ruby
class Sensor
  def initialize(pin)
    @adc = ADC.new(pin)
  end

  def read_temperature
    # ADC reads 0-4095, calibrated to -50°C to +50°C
    raw = @adc.read_raw
    celsius = (raw - 2048) / 40.96
    celsius.round(1)
  end
end
```

**Test** (`test/sensor_test.rb`):
```ruby
class SensorTest < Picotest::Test
  def test_read_at_0_celsius
    # 0°C = (2048 + 0) raw value
    stub_any_instance_of(ADC).read_raw { 2048 }

    sensor = Sensor.new(27)
    assert_equal 0.0, sensor.read_temperature
  end

  def test_read_at_25_celsius
    # 25°C = (2048 + 1024) raw value
    stub_any_instance_of(ADC).read_raw { 3072 }

    sensor = Sensor.new(27)
    assert_equal 25.0, sensor.read_temperature
  end

  def test_read_at_minus_10_celsius
    # -10°C = (2048 - 410) raw value
    stub_any_instance_of(ADC).read_raw { 1638 }

    sensor = Sensor.new(27)
    assert_equal -10.0, sensor.read_temperature
  end
end
```

### Example 2: LED Control

**Application Code** (`storage/home/led.rb`):
```ruby
class LED
  def initialize(pin)
    @gpio = GPIO.new(pin, GPIO::OUT)
  end

  def on
    @gpio.set_level(1)
  end

  def off
    @gpio.set_level(0)
  end

  def blink(count)
    count.times do
      on
      delay(100)
      off
      delay(100)
    end
  end

  private

  def delay(ms)
    # Dummy delay for testing
    sleep(ms / 1000.0)
  end
end
```

**Test** (`test/led_test.rb`):
```ruby
class LEDTest < Picotest::Test
  def test_led_on
    # Verify set_level(1) called once
    mock_any_instance_of(GPIO).set_level(1) { nil }

    led = LED.new(2)
    led.on

    # Teardown verifies call count
  end

  def test_led_blink
    # Blink 3 times = 6 calls to set_level (ON/OFF × 3)
    mock_any_instance_of(GPIO).set_level(6) { nil }

    led = LED.new(2)
    led.blink(3)

    # Teardown verifies exactly 6 calls
  end
end
```

### Example 3: I2C Communication

**Application Code** (`storage/home/i2c_manager.rb`):
```ruby
class I2CManager
  def initialize(bus, sda, scl)
    @i2c = I2C.new(bus, sda: sda, scl: scl)
  end

  def read_sensor(address)
    data = @i2c.read(address, 2)
    (data[0] << 8 | data[1]) / 10.0
  end

  def write_config(address, value)
    @i2c.write(address, [value])
  end
end
```

**Test** (`test/i2c_manager_test.rb`):
```ruby
class I2CManagerTest < Picotest::Test
  def test_read_sensor_value
    stub_any_instance_of(I2C).read do |address, length|
      case address
      when 0x50 then [0x01, 0x00]  # 256 → 25.6
      when 0x51 then [0x02, 0x00]  # 512 → 51.2
      else [0x00, 0x00]
      end
    end

    manager = I2CManager.new(0, sda: 21, scl: 22)
    assert_equal 25.6, manager.read_sensor(0x50)
    assert_equal 51.2, manager.read_sensor(0x51)
  end

  def test_write_config
    # Verify write called twice with correct data
    mock_any_instance_of(I2C).write(2) { true }

    manager = I2CManager.new(0, sda: 21, scl: 22)
    manager.write_config(0x50, 0x10)
    manager.write_config(0x51, 0x20)

    # Teardown verifies exactly 2 calls
  end
end
```

---

## Assertions Reference

### Truthiness

```ruby
assert(true)         # ✓ Pass
assert(false)        # ✗ Fail
assert_false(false)  # ✓ Pass
assert_false(true)   # ✗ Fail
```

### Equality

```ruby
assert_equal(5, 2 + 3)      # ✓ Pass
assert_equal(5, 2 + 4)      # ✗ Fail
assert_not_equal(5, 6)      # ✓ Pass
```

### Nil

```ruby
assert_nil(nil)             # ✓ Pass
assert_nil("value")         # ✗ Fail
```

### Floating Point (with Tolerance)

```ruby
delta = 0.01
assert_in_delta(1.001, 1.0, delta)    # ✓ Pass (within 0.01)
assert_in_delta(1.02, 1.0, delta)     # ✗ Fail (outside 0.01)
```

### Exceptions

```ruby
# Check exception is raised
assert_raise(ArgumentError) do
  some_method_that_raises
end

# ✗ If no exception, test fails
assert_raise(ArgumentError) do
  puts "no exception here"
end
```

---

## Best Practices

### 1. Test Organization

```
test/
├── app_test.rb              # Tests for storage/home/app.rb
├── sensor_test.rb           # Tests for storage/home/sensor.rb
├── led_test.rb              # Tests for storage/home/led.rb
└── lib/
    └── helper_test.rb       # Tests for storage/home/lib/helper.rb
```

- One test file per application file
- Class name = `{SourceClass}Test`
- Test method names describe what's being tested

### 2. Setup and Teardown

```ruby
class SensorTest < Picotest::Test
  def setup
    # Create fresh objects for each test
    @sensor = Sensor.new(27)
    @adc_mock = mock_adc
  end

  def test_example1
    # Each test gets fresh @sensor
  end

  def test_example2
    # Each test gets fresh @sensor (independent)
  end

  def teardown
    # Optional: cleanup (doubles auto-cleanup)
    @sensor = nil
  end
end
```

### 3. Hardware Abstraction

```ruby
# BAD: Testing hardware interaction directly
def test_read_temperature_bad
  # Requires real ADC hardware!
  sensor = Sensor.new(27)
  result = sensor.read_temperature
  assert result > 0  # What does this even mean?
end

# GOOD: Stub hardware, test business logic
def test_read_temperature_good
  # Stub hardware
  stub_any_instance_of(ADC).read_raw { 2500 }

  # Test calculation logic
  sensor = Sensor.new(27)
  result = sensor.read_temperature
  assert_equal 11.0, result  # Specific, predictable
end
```

### 4. Test Coverage

For each method, test:
- ✓ Happy path (normal case)
- ✓ Edge cases (min/max values)
- ✓ Error conditions (invalid input)
- ✓ Boundary conditions (0, negative, large values)

```ruby
class TemperatureCalculatorTest < Picotest::Test
  def test_normal_temperature
    calc = TemperatureCalculator.new
    assert_equal 25.0, calc.raw_to_celsius(3072)
  end

  def test_min_temperature
    calc = TemperatureCalculator.new
    assert_equal -50.0, calc.raw_to_celsius(0)
  end

  def test_max_temperature
    calc = TemperatureCalculator.new
    assert_equal 50.0, calc.raw_to_celsius(4095)
  end
end
```

---

## Workflow

### Development Workflow

1. **Write test first** (TDD)
   ```ruby
   # test/sensor_test.rb
   def test_read_temperature
     stub_any_instance_of(ADC).read_raw { 750 }
     sensor = Sensor.new(27)
     assert_equal 25.0, sensor.read_temperature
   end
   ```

2. **Write minimal code to pass test**
   ```ruby
   # storage/home/sensor.rb
   class Sensor
     def initialize(pin)
       @adc = ADC.new(pin)
     end

     def read_temperature
       (750 - 500) / 10.0  # = 25.0
     end
   end
   ```

3. **Run tests locally**
   ```bash
   ptrk device build --test
   ptrk device flash
   ptrk device monitor --test
   ```

4. **Refactor and improve** (keep tests passing)
   ```ruby
   # storage/home/sensor.rb
   class Sensor
     def initialize(pin)
       @adc = ADC.new(pin)
     end

     def read_temperature
       raw = @adc.read_raw
       (raw - 500) / 10.0  # More readable
     end
   end
   ```

5. **Commit changes**
   ```bash
   git add test/sensor_test.rb storage/home/sensor.rb
   git commit -m "feat: add Sensor#read_temperature method"
   ```

### CI/CD Workflow

```bash
# In GitHub Actions or other CI
ptrk device build --test

# Build succeeds? → Upload firmware artifact
# Later: Run on hardware or emulator
```

---

## Troubleshooting

### Issue: Tests Not Running

**Problem**: `Picotest not found` or no test output

**Solutions**:
1. Verify Mrbgemfile includes picotest:
   ```ruby
   # Mrbgemfile
   mrbgems do |conf|
     conf.gem core: "picoruby-picotest"  # ← Must be present
   end
   ```

2. Verify test files are named correctly:
   - Directory: `test/`
   - Files: `*_test.rb` (must end with `_test.rb`)
   - Classes: Must inherit from `Picotest::Test`
   - Methods: Must start with `test_`

3. Check serial port connection:
   ```bash
   ls /dev/ttyUSB*  # Or /dev/ttyACM* on some systems
   ```

### Issue: Stub Not Working

**Problem**: Test calls method but stub value not returned

**Causes**:
1. Stub called after method invocation
   ```ruby
   # WRONG: stub after use
   sensor = Sensor.new(27)
   sensor.read_temperature  # Method called
   stub_any_instance_of(ADC).read_raw { 750 }  # Too late!
   ```

2. Wrong class name or method name
   ```ruby
   # WRONG: class name typo
   stub_any_instance_of(ADC).read_raw { 750 }  # Correct
   stub_any_instance_of(Adc).read_raw { 750 }  # WRONG (typo)
   ```

**Solution**: Stub before creating objects
```ruby
# CORRECT: stub before use
stub_any_instance_of(ADC).read_raw { 750 }
sensor = Sensor.new(27)
sensor.read_temperature  # Now uses stub
```

### Issue: Serial Output Not Parsed

**Problem**: `ptrk device monitor --test` shows raw output but no summary

**Causes**:
1. Not using `--test` flag
   ```bash
   ptrk device monitor      # WRONG: won't parse Picotest output
   ptrk device monitor --test  # CORRECT
   ```

2. Serial baud rate mismatch
   - Check ESP32 configuration in R2P2-ESP32
   - Verify USB connection

3. Picotest output format changed
   - Update ptrk to latest version

**Solution**:
```bash
# Verify serial connection
ptrk device monitor  # See raw output to debug

# Check Picotest is running
# You should see: "Running ClassName..."
```

---

## Advanced Topics

### Running Specific Tests

Currently, all tests in `test/` run. To run specific tests:

1. Move unwanted tests to temporary directory
2. Or comment out in `app.rb` test runner injection

### Custom Test Runner

Modify `storage/home/app.rb` to customize test execution:

```ruby
require 'picotest'

# Load only specific test file
load '/storage/home/test/sensor_test.rb'

# Create custom runner if needed
test_class = SensorTest
runner = Picotest::Runner.new(nil, nil, '/tmp', 'app', [], nil)
runner.run
```

### Performance Testing

Use `assert_in_delta` for timing-sensitive code:

```ruby
def test_blink_timing
  # Blink should take ~200ms per cycle

  mock_any_instance_of(GPIO).set_level(2) { nil }

  led = LED.new(2)

  start_time = Time.now
  led.blink(1)
  elapsed = Time.now - start_time

  # Allow ±50ms variance
  assert_in_delta 0.2, elapsed, 0.05
end
```

---

## References

- **SPEC.md**: Device Testing specification section
- **PicoRuby Picotest**: https://github.com/picoruby/picoruby/tree/master/mrbgems/picoruby-picotest
- **Picotest Examples**: See generated `test/app_test.rb` template
- **Example Projects**: `docs/examples/sensor-test-example/`
