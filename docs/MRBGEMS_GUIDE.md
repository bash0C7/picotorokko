# Application-Specific mrbgem Development Guide

This guide explains how to develop application-specific PicoRuby mrbgems using the `ptrk` tool on ESP32.

## Overview

**mrbgem** is a PicoRuby/mruby extension mechanism that allows you to:
- Write C language extensions for performance-critical code
- Expose C functions as Ruby class methods
- Integrate low-level hardware operations with high-level Ruby code

The `ptrk` tool automates mrbgem scaffolding and integration with the ESP32 build system.

## Quick Start

### 1. Generate mrbgem Template

```bash
ptrk mrbgems generate App
```

This creates:
```
mrbgems/App/
├── mrbgem.rake          # mrbgem metadata
├── mrblib/
│   └── app.rb           # Ruby class definition
├── src/
│   └── app.c            # C implementation
└── README.md            # Documentation
```

### 2. Edit C Implementation

Open `mrbgems/App/src/app.c` and add your class methods:

```c
static void
c_app_my_method(mrbc_vm *vm, mrbc_value *v, int argc)
{
  // Your implementation here
  mrbc_value ret = mrbc_integer_value(42);
  SET_RETURN(ret);
}

void
mrbc_app_init(mrbc_vm *vm)
{
  mrbc_class *app_class = mrbc_define_class(vm, "App", mrbc_class_object);
  mrbc_define_method(vm, app_class, "my_method", c_app_my_method);
}
```

### 3. Build and Test

```bash
# Create/update environment with your application
ptrk env set development

# Build firmware with your mrbgem
ptrk device build

# Flash to ESP32
ptrk device flash

# Check output
ptrk device monitor
```

The mrbgem is automatically registered in:
- `patch/picoruby/build_config/xtensa-esp.rb`
- `patch/picoruby-esp32/CMakeLists.txt`

## Directory Structure

### mrbgem.rake

Gem metadata file:
```ruby
MRuby::Gem::Specification.new('App') do |spec|
  spec.license = 'MIT'
  spec.author  = 'Your Name'
  spec.summary = 'Application-specific mrbgem'
end
```

### mrblib/app.rb

Ruby class definition (optional, can add Ruby helper methods):
```ruby
class App
  # Class methods are defined in C extension
  # Optional: Add Ruby-level helper methods here
end
```

### src/app.c

C implementation with:
- `#elif defined(PICORB_VM_MRUBYC)` - mrubyc (MicroRuby) code for ESP32
- Method implementations using `mrbc_*` API
- `mrbc_app_init()` initialization function

## C Extension API Basics

### Defining a Class Method

```c
static void
c_app_version(mrbc_vm *vm, mrbc_value *v, int argc)
{
  // v[0] is the receiver (self) - the App class
  // v[1], v[2], ... are arguments
  // argc is the argument count

  // Return an integer
  SET_RETURN(mrbc_integer_value(100));
}

void
mrbc_app_init(mrbc_vm *vm)
{
  mrbc_class *app_class = mrbc_define_class(vm, "App", mrbc_class_object);

  // Register as class method (singleton method)
  mrbc_define_method(vm, app_class, "version", c_app_version);
}
```

### Common Return Types

```c
// Integer
SET_RETURN(mrbc_integer_value(42));

// String
mrbc_value str = mrbc_string_new_cstr(vm, "hello");
SET_RETURN(str);

// Boolean
SET_RETURN(mrbc_true_value());    // true
SET_RETURN(mrbc_false_value());   // false

// Nil
SET_RETURN(mrbc_nil_value());

// Array
mrbc_value array = mrbc_array_new(vm, 3);
mrbc_array_set(&array, 0, &mrbc_integer_value(1));
SET_RETURN(array);
```

### Accessing Arguments

```c
static void
c_app_add(mrbc_vm *vm, mrbc_value *v, int argc)
{
  if (argc != 2) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "wrong number of arguments");
    return;
  }

  if (v[1].tt != MRBC_TT_INTEGER || v[2].tt != MRBC_TT_INTEGER) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "arguments must be integers");
    return;
  }

  int result = v[1].i + v[2].i;
  SET_RETURN(mrbc_integer_value(result));
}
```

### Error Handling

```c
mrbc_raise(vm, MRBC_CLASS(ArgumentError), "wrong number of arguments");
mrbc_raise(vm, MRBC_CLASS(TypeError), "expected integer");
mrbc_raise(vm, MRBC_CLASS(RuntimeError), "operation failed");
```

## Integration with Build System

### Patch Files

When you run `ptrk env set`, the tool automatically creates:

**`patch/picoruby/build_config/xtensa-esp.rb`**
```ruby
conf.gem local: '../../../../mrbgems/App'
```

**`patch/picoruby-esp32/CMakeLists.txt`**
```cmake
${COMPONENT_DIR}/../../mrbgems/App/src/app.c
```

You can customize these patches in the `patch/` directory and manage them with:
```bash
ptrk env patch_export development
ptrk env patch_diff development
```

### Relative Paths

The paths use relative notation:
- `../../mrbgems/App` from `picoruby-esp32/` = project root's `mrbgems/App`
- `../../../../mrbgems/App` from `picoruby/build_config/` = project root's `mrbgems/App`

## Usage Example

After building and flashing:

```ruby
# In your application code (on ESP32)
puts App.version          #=> 100
result = App.add(2, 3)    #=> 5
```

## Advanced Topics

### Multiple Mrbgems

You can create multiple mrbgems for different functionalities:

```bash
ptrk mrbgems generate Sensor
ptrk mrbgems generate Motor
```

Each one will be automatically registered during `ptrk env set`.

### Customizing Author Name

```bash
ptrk mrbgems generate MyGem --author "Your Name"
```

### Version Numbers

Use a version number (integer) to track mrbgem versions:

```c
#define APP_VERSION 100  // v1.0.0

SET_RETURN(mrbc_integer_value(APP_VERSION));
```

Increment for each release and use `App.version` in Ruby to validate compatibility.

## Troubleshooting

### "mrbgem not found" Error

Ensure you ran `ptrk env set`. The mrbgem template must exist before environment setup:

```bash
ptrk mrbgems generate App
ptrk env set development  # This auto-generates patches
```

### Build Fails with Undefined Symbols

Check that:
1. Function name in `mrbc_app_init` matches the C function name
2. `mrbc_define_method` has correct method name
3. All #include statements reference correct headers

### Changes Not Reflected

Export your patches after editing:

```bash
ptrk env patch_export development  # Saves changes to patch/ directory
ptrk env set development           # Clean rebuild with patches
```

## Declaring Gems in Mrbgemfile

After creating your custom mrbgems and installing external dependencies, declare them in your project's `Mrbgemfile` to include them in the build.

### Adding Custom Gems to Mrbgemfile

```ruby
# Mrbgemfile - Declare mrbgem dependencies
mrbgems do |conf|
  # Your custom application-specific gems (created with ptrk mrbgems generate)
  conf.gem path: "./mrbgems/app"
  conf.gem path: "./mrbgems/Sensor"
  conf.gem path: "./mrbgems/Motor"

  # External mrbgems from GitHub
  conf.gem github: "picoruby/picoruby-json", branch: "main"
  conf.gem github: "picoruby/picoruby-yaml"

  # Core mrbgems
  conf.gem core: "sprintf"
end
```

### Complete Example with Custom and External Gems

```ruby
# Mrbgemfile - Application with both custom and external gems
mrbgems do |conf|
  # ========== Core Utilities ==========
  conf.gem core: "sprintf"
  conf.gem core: "fiber"

  # ========== Data Format Support ==========
  conf.gem github: "picoruby/picoruby-json", branch: "main"
  conf.gem github: "picoruby/picoruby-yaml"

  # ========== Hardware Abstraction (Platform-Specific) ==========
  if conf.build_config_files.include?("xtensa-esp")
    # ESP32-specific hardware gems
    conf.gem github: "picoruby/picoruby-esp32-gpio"
    conf.gem github: "picoruby/picoruby-esp32-nvs"
    conf.gem github: "picoruby/picoruby-esp32-wifi"
    conf.gem github: "picoruby/picoruby-esp32-i2c"
  elsif conf.build_config_files.include?("rp2040")
    # RP2040-specific hardware gems
    conf.gem github: "picoruby/picoruby-rp2040-gpio"
    conf.gem github: "picoruby/picoruby-rp2040-spi"
  end

  # ========== Custom Application Gems ==========
  # These are created with: ptrk mrbgems generate NAME
  conf.gem path: "./mrbgems/app"
  conf.gem path: "./mrbgems/Sensor"
  conf.gem path: "./mrbgems/Motor"
end
```

### Workflow

1. **Generate custom gems** (as shown in this guide):
   ```bash
   ptrk mrbgems generate Sensor
   ptrk mrbgems generate Motor
   ```

2. **Declare in Mrbgemfile**:
   ```ruby
   mrbgems do |conf|
     conf.gem path: "./mrbgems/Sensor"
     conf.gem path: "./mrbgems/Motor"
   end
   ```

3. **Build and test**:
   ```bash
   ptrk device build
   ptrk device flash
   ```

## Integration: From Development to Build

The complete workflow combines custom mrbgem development with Mrbgemfile declaration:

```
1. ptrk mrbgems generate Sensor  → Create custom mrbgem template
   ↓
2. Edit mrbgems/Sensor/src/sensor.c  → Implement functionality
   ↓
3. Add to Mrbgemfile  → Declare in build
   conf.gem path: "./mrbgems/Sensor"
   ↓
4. ptrk device build  → Compile with all gems
   ↓
5. ptrk device flash  → Deploy to ESP32
   ↓
6. Use in Ruby code   → App.sensor_read() etc.
```

## Reference

- [PicoRuby mrbgems](https://github.com/picoruby/picoruby/tree/master/mrbgems)
- [mrubyc API](https://github.com/picoruby/picoruby/tree/master/mrbgems/picoruby-mrubyc/lib/mrubyc)
- [picoruby-irq Example](https://github.com/picoruby/picoruby/tree/master/mrbgems/picoruby-irq)
- [Mrbgemfile Configuration Guide](../docs/MRBGEMS_GUIDE.md) — Comprehensive Mrbgemfile documentation
- [SPEC.md#-mrbgemfile-configuration](../SPEC.md#-mrbgemfile-configuration) — Complete Mrbgemfile reference
