# M5Unified Binding Coverage Analysis

**Date**: 2025-12-08
**Generated from**: M5Unified @ https://github.com/m5stack/M5Unified.git

## Executive Summary

❌ **CRITICAL**: The current m5libgen implementation has severe limitations and is **NOT PRODUCTION READY**.

**Coverage**: Only ~7% of M5Unified API methods are extracted (14 out of 200+)

**Generated Code Status**: Does not compile - contains syntax errors

## Detailed Analysis

### 1. What Works ✅

- ✅ Repository cloning and management
- ✅ Header file discovery (.h and .hpp)
- ✅ UTF-8 encoding support for Japanese comments
- ✅ Class name extraction (31 classes found)
- ✅ Directory structure generation
- ✅ CMakeLists.txt generation
- ✅ Basic type mapping infrastructure

### 2. Critical Issues ❌

#### Issue #1: Inline Method Extraction Failure

**Problem**: Parser fails to extract inline methods defined in class body

**Example** - Button_Class.hpp:
```cpp
class Button_Class {
public:
  bool wasClicked(void)  const { return _currentState == state_clicked; }
  bool wasPressed(void)  const { return !_oldPress && _press; }
  // ... 24+ methods
};
```

**Result**: 0 methods extracted from Button_Class

**Root Cause**: LibClangParser only detects CXXMethod cursors that are declarations, not inline definitions with implementation bodies.

#### Issue #2: Generated C++ Wrapper Syntax Errors

**File**: `output/mrbgem-m5unified-full/ports/esp32/m5unified_wrapper.cpp`

```cpp
// Line 13 - Duplicate "void void"
int m5unified_i2c_class_begin(void void) {
  return M5.I2C_Class.begin(void) ? 1 : 0;
}

// Line 33 - Invalid varargs syntax
void m5unified_log_class_printf(const format, ... ...) {
  M5.Log_Class.printf(format, ...);
}

// Line 37 - Void function shouldn't return
return m5unified_log_class_printf("%s" "%s", string string) {
  return M5.Log_Class.printf("%s", string);
}

// Line 41 - Invalid C syntax
constructor m5unified_m5timer_M5Timer(void void) {
  return M5.M5Timer.M5Timer(void);
}
```

**Impact**: Code does not compile

#### Issue #3: C Bindings Have No Implementation

**File**: `output/mrbgem-m5unified-full/src/m5unified.c`

```c
// All extern declarations are wrong - use void, no parameters
extern void m5unified_i2c_class_begin(void);
extern void m5unified_led_class_display(void);

// All mrubyc wrappers are TODO stubs
static void mrbc_m5_begin(mrbc_vm *vm, mrbc_value *v, int argc) {
  /* TODO: Call wrapper function */
  SET_RETURN(mrbc_nil_value());
}
```

**Impact**: Generated gem is completely non-functional

#### Issue #4: Duplicate Method Definitions

```c
// begin() defined 5 times with same function name
mrbc_define_method(vm, c_I2C_Class, "begin", mrbc_m5_begin);
mrbc_define_method(vm, c_I2C_Class, "begin", mrbc_m5_begin);  // Duplicate
mrbc_define_method(vm, c_LED_Class, "begin", mrbc_m5_begin);
mrbc_define_method(vm, c_RTC_Class, "begin", mrbc_m5_begin);
mrbc_define_method(vm, c_RTC_Class, "begin", mrbc_m5_begin);  // Duplicate
```

#### Issue #5: Missing Critical Classes

The following classes have **ZERO** methods extracted:

- **M5Unified** - Main API class (begin, update, getBoard, delay, millis, etc.)
- **Button_Class** - 24+ button methods (wasClicked, wasPressed, isHolding, etc.)
- **Display** - Should expose LovyanGFX drawing API (100+ methods)
- **Power_Class** - Power management methods
- **Speaker_Class** - Audio playback methods
- **Mic_Class** - Audio recording methods
- **Touch_Class** - Touch input methods
- **IMU_Class** - Accelerometer/gyroscope methods

### 3. Coverage Statistics

| Category | Expected | Actual | Coverage |
|----------|----------|--------|----------|
| Classes detected | 31 | 31 | 100% ✅ |
| Classes with methods | 31 | 6 | 19% ❌ |
| Total methods | 200+ | 14 | ~7% ❌ |
| Compilable code | Yes | No | 0% ❌ |

#### Classes With Extracted Methods (6/31)

1. **I2C_Class**: setPort, begin (2 methods extracted)
2. **LED_Class**: begin, display, getBuffer, setBrightness (4 methods)
3. **Log_Class**: printf (1 method, with duplicates)
4. **M5Timer**: M5Timer, run, setTimer (3 methods)
5. **timer_info_t**: set, run, clear (3 methods)
6. **RTC_Class**: begin (1 method, with duplicates)

### 4. Type System Limitations

The current implementation cannot handle:

- ❌ Inline method definitions (the most common pattern in M5Unified)
- ❌ Varargs methods (`void printf(const char* format, ...)`)
- ❌ Constructors (marked as "constructor" instead of proper wrapping)
- ❌ Method overloading (generates duplicate symbols)
- ❌ Default parameters (`void begin(config_t cfg = config_t())`)
- ❌ Complex return types (pointers to structs)
- ❌ Template methods
- ❌ Operator overloading

### 5. Test Coverage vs Real-World Usage

**Unit Tests**: All passing ✅

**Integration Test**: Fails completely ❌

The unit tests only verify that the code runs without crashing. They do NOT verify:
- Generated code compiles
- Generated code produces correct bindings
- Coverage completeness
- API usability

## Recommended Actions

### Phase 1: Fix Critical Bugs (Required)

1. **Fix inline method extraction**
   - Enhance LibClangParser to handle inline method definitions
   - Add cursor kind detection for inline methods
   - Test with Button_Class.hpp

2. **Fix code generation**
   - Fix parameter handling in CppWrapperGenerator
   - Fix duplicate method name generation
   - Fix void parameter handling
   - Fix varargs syntax
   - Fix constructor handling

3. **Implement actual C bindings**
   - Generate proper extern declarations with types
   - Implement mrubyc wrapper function bodies
   - Add parameter marshalling (mruby → C++)
   - Add return value marshalling (C++ → mruby)

4. **Add compilation test**
   - Test that generated wrapper.cpp compiles with g++/clang++
   - Test that generated m5unified.c compiles with mrubyc

### Phase 2: Complete Coverage (Required)

5. **Extract M5Unified main class methods**
   - begin(), update(), getBoard(), delay(), millis(), etc.

6. **Extract Button_Class methods**
   - All 24+ button state methods

7. **Handle M5.Display properly**
   - Should expose LovyanGFX API
   - 100+ drawing methods

8. **Extract remaining peripheral classes**
   - Power, Speaker, Mic, Touch, IMU

### Phase 3: Advanced Features (Optional)

9. **Handle method overloading**
   - Generate unique C function names for each overload
   - Use parameter count or types in wrapper names

10. **Handle default parameters**
    - Generate multiple wrapper functions

11. **Add enum constant bindings**
    - Generate Ruby constants for C++ enums

12. **Add Button singleton mapping**
    - Generate M5.BtnA, M5.BtnB, M5.BtnC, M5.BtnPWR

## Conclusion

The current implementation successfully demonstrates:
- TDD methodology
- Project structure
- Basic parsing infrastructure

However, it does NOT achieve the stated goal of "complete M5Unified coverage". The generated mrbgem is non-functional and requires major fixes before it can be used in production.

**Estimated Work Remaining**:
- Critical bug fixes: 2-3 TDD cycles
- Coverage completion: 5-8 TDD cycles
- Advanced features: 3-5 TDD cycles

**Total**: 10-16 additional TDD cycles needed

## Files Generated

```
output/mrbgem-m5unified-full/
├── CMakeLists.txt          ✅ Valid
├── mrbgem.rake             ✅ Valid
├── mrblib/
│   └── m5unified.rb        ⚠️  Empty (only comments)
├── ports/
│   └── esp32/
│       └── m5unified_wrapper.cpp  ❌ Syntax errors, won't compile
└── src/
    └── m5unified.c         ❌ Stub implementations, non-functional
```

## Verification Commands

```bash
# Clone M5Unified
cd lib/m5libgen
./bin/m5libgen clone https://github.com/m5stack/M5Unified.git

# Generate mrbgem
./bin/m5libgen generate ../../output/mrbgem-m5unified-full

# Verify compilation (FAILS)
cd ../../output/mrbgem-m5unified-full
g++ -c ports/esp32/m5unified_wrapper.cpp -I vendor/m5unified/src
# Error: expected ',' or '...' before 'void'
```

## References

- M5Unified Repository: https://github.com/m5stack/M5Unified
- Button_Class Source: `vendor/m5unified/src/utility/Button_Class.hpp`
- M5Unified Main Class: `vendor/m5unified/src/M5Unified.hpp`
- Generated Output: `output/mrbgem-m5unified-full/`
