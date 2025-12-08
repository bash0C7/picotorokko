# M5LibGen TODO

Current status and roadmap for M5LibGen development.

## Current Status

**Phase**: ⚠️ CRITICAL ISSUES FOUND - NOT PRODUCTION READY
**Last Updated**: 2025-12-08

**See FINDINGS.md for detailed coverage analysis**

### Completed ✅

**Foundation (Cycles 1-3):**
- ✅ Project structure designed
- ✅ README.md created with architecture overview
- ✅ TODO.md created with detailed roadmap
- ✅ Gemspec and Gemfile configured
- ✅ **TDD Cycle 1**: Version & Entry Point (4 tests, 100% pass)
- ✅ **TDD Cycle 2**: RepositoryManager (7 tests, 100% pass)
- ✅ **TDD Cycle 3**: HeaderReader (7 tests, 100% pass)
- ✅ Old files deleted (m5unified.rb, m5unified.md, M5UNIFIED_HANDOFF.md, m5unified_test.rb)

**Advanced Features (Cycles 4-19):**
- ✅ **Cycle 4**: LibClangParser with fallback (7 tests, 100% pass)
- ✅ **Cycles 5-6**: Method metadata (static, const, virtual)
- ✅ **Cycle 7**: Enum extraction (top-level & class-scoped, with values)
- ✅ **Cycle 8**: Advanced fallback parsing
- ✅ **Cycle 9**: TypeMapper - Complete type mapping (8 tests, 100% pass)
- ✅ **Cycles 11-15**: MrbgemGenerator - Full mrbgem generation
- ✅ **Cycle 14**: CppWrapperGenerator - extern "C" wrappers
- ✅ **Cycle 15**: CMakeGenerator - ESP-IDF configuration
- ✅ **Cycles 17-18**: ApiPatternDetector - M5Unified patterns
- ✅ **Cycle 19**: CLI - bin/m5libgen command-line tool

**Test Coverage**: 26+ tests, 100% pass (unit tests only)
**RuboCop**: Clean

### ⚠️ CRITICAL ISSUES DISCOVERED

**CLI Execution Results** (2025-12-08):
```bash
./bin/m5libgen clone https://github.com/m5stack/M5Unified.git
./bin/m5libgen generate ../../output/mrbgem-m5unified-full
```

**Findings**:
- ❌ Only 14 methods extracted (expected 200+) - **~7% coverage**
- ❌ Generated C++ wrapper has syntax errors (won't compile)
- ❌ Generated C bindings are stub implementations (non-functional)
- ❌ **Button_Class**: 0 methods extracted (expected 24+)
- ❌ **M5Unified main class**: 0 methods extracted
- ❌ 25 out of 31 classes have ZERO methods extracted

**Root Causes**:
1. **Inline method extraction failure** - Parser doesn't handle inline definitions:
   ```cpp
   bool wasClicked(void) const { return _state == clicked; }  // NOT extracted
   ```
2. **Code generation bugs** - Produces invalid C++ syntax:
   ```cpp
   int begin(void void) { ... }  // Duplicate "void void"
   const format, ... ...         // Invalid varargs
   ```
3. **Method overloading** - Generates duplicate symbol names
4. **Missing implementation** - All mrubyc wrappers are TODO stubs

**Impact**: Generated mrbgem is completely non-functional

### Complete Feature Set 🎯

**C++ Feature Extraction:**
- ✅ Classes & structs
- ✅ Public methods with metadata (static, const, virtual)
- ✅ Parameters & return types
- ✅ Enums (top-level & class-scoped) with values
- ✅ Scoped enums (enum class)

**M5Unified Patterns:**
- ✅ Button singleton mapping (→ BtnA/BtnB/BtnC/BtnPWR)
- ✅ Predicate methods (bool → ? suffix)
- ✅ Ruby idiom conversion

**Type Mapping:**
- ✅ 13+ integer types
- ✅ Float/double, bool, string, void
- ✅ Pointer/object types
- ✅ Const qualifiers

**Required Fixes (CRITICAL):**
- ❌ **Cycle 21**: Fix inline method extraction (LibClangParser)
- ❌ **Cycle 22**: Fix C++ wrapper code generation (CppWrapperGenerator)
- ❌ **Cycle 23**: Implement actual mrubyc wrapper functions
- ❌ **Cycle 24**: Fix method overloading (unique symbol names)
- ❌ **Cycle 25**: Extract M5Unified main class methods
- ❌ **Cycle 26**: Extract Button_Class methods
- ❌ **Cycle 27**: Add compilation test (verify generated code compiles)
- ❌ **Cycle 28**: Complete coverage test (all classes have methods)

**Future Work:**
- ❌ Phase 8: ESP32 compilation validation
- ❌ Phase 9: Device testing

---

## Roadmap

### Phase 1: Foundation (TDD Cycle 1-3) ✅ COMPLETE

**Goal**: Basic gem structure and core components

#### Cycle 1: Version & Entry Point ✅
- [x] Create `lib/m5libgen/version.rb`
- [x] Create `lib/m5libgen.rb` (entry point)
- [x] Test: require 'm5libgen' works
- [x] Test: M5LibGen::VERSION defined
- [x] RuboCop pass

#### Cycle 2: RepositoryManager ✅
- [x] Implement `lib/m5libgen/repository_manager.rb`
- [x] Test: clone repository
- [x] Test: update repository
- [x] Test: get repository info
- [x] Custom error classes (CloneError, UpdateError, InfoError)
- [x] RuboCop pass

#### Cycle 3: HeaderReader ✅
- [x] Implement `lib/m5libgen/header_reader.rb`
- [x] Test: list header files from src/ and include/
- [x] Test: read header content
- [x] Test: sorted file paths
- [x] Custom error class (FileNotFoundError)
- [x] RuboCop pass

---

### Phase 2: libclang Parser (TDD Cycle 4-8)

**Goal**: Accurate C++ parsing with libclang

**Critical Decision**: Use libclang instead of regex-based parsing

**Why libclang?**
- Regex-based parser achieved only 5-10% extraction rate
- Cannot handle nested braces, inline methods, const qualifiers
- libclang provides complete AST with all metadata

#### Cycle 4: LibClangParser Foundation
- [ ] Add `ffi-clang` to dependencies
- [ ] Implement `lib/m5libgen/libclang_parser.rb`
- [ ] Test: parse simple C++ header
- [ ] Test: extract class names
- [ ] RuboCop pass

#### Cycle 5: Method Extraction
- [ ] Test: extract public methods
- [ ] Test: extract method parameters
- [ ] Test: extract return types
- [ ] Test: handle const qualifiers
- [ ] RuboCop pass

#### Cycle 6: Advanced Features
- [ ] Test: extract inline methods
- [ ] Test: detect static methods
- [ ] Test: detect virtual methods
- [ ] Test: handle nested classes
- [ ] RuboCop pass

#### Cycle 7: Enum Support
- [ ] Test: extract enum definitions
- [ ] Test: extract enum values
- [ ] Test: handle enum class
- [ ] RuboCop pass

#### Cycle 8: Namespace Handling
- [ ] Test: preserve namespace information
- [ ] Test: resolve namespace-qualified types (std::, m5gfx::)
- [ ] Test: canonical type names
- [ ] RuboCop pass

---

### Phase 3: Type Mapping (TDD Cycle 9-10)

**Goal**: Complete C++ ↔ mruby type conversion

#### Cycle 9: Basic Types
- [ ] Implement `lib/m5libgen/type_mapper.rb`
- [ ] Test: map integer types (int, int8_t, ..., uint64_t, size_t)
- [ ] Test: map float/double
- [ ] Test: map bool
- [ ] Test: map string (char*)
- [ ] Test: map void
- [ ] RuboCop pass

#### Cycle 10: Complex Types
- [ ] Test: map pointer types
- [ ] Test: map reference types
- [ ] Test: normalize const qualifiers
- [ ] Test: handle namespace-qualified types
- [ ] RuboCop pass

---

### Phase 4: Code Generation (TDD Cycle 11-16)

**Goal**: Generate complete mrbgem files

#### Cycle 11: MrbgemGenerator Structure
- [ ] Implement `lib/m5libgen/mrbgem_generator.rb`
- [ ] Test: create directory structure
- [ ] Test: generate mrbgem.rake
- [ ] RuboCop pass

#### Cycle 12: C Bindings
- [ ] Test: generate forward declarations
- [ ] Test: generate extern declarations
- [ ] Test: generate method wrappers
- [ ] Test: generate parameter conversions
- [ ] Test: generate return value marshalling
- [ ] RuboCop pass

#### Cycle 13: gem_init Function
- [ ] Test: generate mrbc_define_class calls
- [ ] Test: generate mrbc_define_method calls
- [ ] Test: handle multiple classes
- [ ] RuboCop pass

#### Cycle 14: C++ Wrapper
- [ ] Implement `lib/m5libgen/cpp_wrapper_generator.rb`
- [ ] Test: generate extern "C" blocks
- [ ] Test: flatten namespace (M5.BtnA.wasPressed → m5unified_btna_wasPressed)
- [ ] Test: convert bool → int
- [ ] Test: generate API calls
- [ ] RuboCop pass

#### Cycle 15: CMake Generation
- [ ] Implement `lib/m5libgen/cmake_generator.rb`
- [ ] Test: generate idf_component_register
- [ ] Test: add source files
- [ ] Test: add include directories
- [ ] Test: add dependencies
- [ ] RuboCop pass

#### Cycle 16: Ruby Documentation
- [ ] Test: generate mrblib/m5unified.rb
- [ ] Test: generate README.md
- [ ] Test: include class documentation
- [ ] RuboCop pass

---

### Phase 5: M5Unified Patterns (TDD Cycle 17-18)

**Goal**: Handle M5Unified-specific API patterns

#### Cycle 17: ApiPatternDetector
- [ ] Implement `lib/m5libgen/api_pattern_detector.rb`
- [ ] Test: detect Button classes
- [ ] Test: generate singleton mapping (BtnA, BtnB, BtnC)
- [ ] Test: detect Display classes
- [ ] RuboCop pass

#### Cycle 18: Ruby Idioms
- [ ] Test: detect predicate methods (bool return)
- [ ] Test: add ? suffix to predicates (wasPressed → wasPressed?)
- [ ] Test: rubify method names
- [ ] RuboCop pass

---

### Phase 6: CLI & Integration (TDD Cycle 19-20)

**Goal**: Thin CLI and end-to-end testing

#### Cycle 19: CLI
- [ ] Create `bin/m5libgen`
- [ ] Test: `m5libgen clone <url>` command
- [ ] Test: `m5libgen generate <path>` command
- [ ] Test: `m5libgen --version`
- [ ] Test: `m5libgen --help`
- [ ] Make executable (chmod +x)
- [ ] RuboCop pass

#### Cycle 20: Integration Test
- [ ] Test: clone real M5Unified repository
- [ ] Test: parse all M5Unified headers
- [ ] Test: extract all 29+ classes
- [ ] Test: generate complete mrbgem
- [ ] Test: verify generated C code syntax
- [ ] Test: verify CMakeLists.txt validity
- [ ] RuboCop pass

---

### Phase 7: Cleanup & Documentation

**Goal**: Remove old files, polish documentation

- [ ] Delete `m5unified.rb` (experimental implementation)
- [ ] Delete `m5unified_test.rb` (old tests)
- [ ] Delete `m5unified.md` (old spec)
- [ ] Delete `M5UNIFIED_HANDOFF.md` (old handoff doc)
- [ ] Update root `README.md` to mention m5libgen
- [ ] Create migration guide (old → new)
- [ ] RuboCop all files
- [ ] Run all tests (100% pass)

---

### Phase 8: ESP32 Validation (Future)

**Goal**: Verify generated mrbgem works on ESP32

- [ ] Compile generated mrbgem with ESP-IDF
- [ ] Flash to ESP32 device
- [ ] Test basic M5.begin() call
- [ ] Test Button APIs (BtnA.wasPressed)
- [ ] Test Display APIs
- [ ] Document any compilation issues
- [ ] Fix edge cases

---

## Success Criteria

### Minimum Viable Product (MVP)

- ✅ Can clone M5Unified repository
- ✅ Can parse C++ headers with libclang
- ⚠️ Can extract classes, methods, parameters, return types (partial - only 7% coverage)
- ✅ Can generate complete mrbgem directory structure
- ❌ Generated C code has valid syntax (has syntax errors)
- ✅ Generated CMakeLists.txt is valid
- ⚠️ All tests pass (100% of unit tests, but no integration tests)
- ✅ RuboCop clean (0 offenses)
- ✅ CLI works (`m5libgen clone`, `m5libgen generate`)

**MVP STATUS**: ❌ NOT ACHIEVED - Critical issues prevent production use

### Stretch Goals

- Extract 100% of M5Unified classes (29+ classes)
- Handle all const qualifiers correctly
- Support static/virtual methods
- Extract default parameter values
- Generate comprehensive documentation
- ESP32 compilation successful
- Real device testing complete

---

## Known Issues

### Current Blockers

1. **Inline Method Extraction** (CRITICAL)
   - LibClangParser fails to extract inline methods defined in class body
   - Affects Button_Class (24+ methods), and many other classes
   - Estimated coverage loss: 90%+

2. **Generated Code Syntax Errors** (CRITICAL)
   - CppWrapperGenerator produces invalid C++ syntax
   - Examples: `void void`, `const format, ... ...`, `constructor`
   - Generated mrbgem does not compile

3. **Method Overloading** (HIGH)
   - Multiple methods with same name generate duplicate symbols
   - Example: I2C_Class::begin() has multiple overloads
   - Causes linker errors

4. **Stub Implementations** (CRITICAL)
   - All mrubyc wrapper functions are TODO stubs
   - No actual parameter marshalling or function calls
   - Generated gem is non-functional

### Technical Debt

1. Unit tests don't verify generated code compiles
2. No integration test with real M5Unified extraction
3. Type system doesn't handle:
   - Varargs methods
   - Constructors
   - Default parameters
   - Template methods
   - Operator overloading

---

## Development Workflow

### t-wada Style TDD Micro-Cycle

For each feature:

1. **Red**: Write failing test
2. **Green**: Implement minimal code to pass
3. **RuboCop**: Fix style issues
4. **Refactor**: Improve code quality
5. **Commit**: Commit with clear message

### Commit Message Format

```
<verb> <subject>

<detailed explanation>
```

Example:
```
Add RepositoryManager with clone support

Implement M5LibGen::RepositoryManager to clone git repositories
using Open3 for shell command execution. Includes error handling
for failed clones and directory cleanup.
```

---

## Testing Strategy

### Unit Tests

- Test each class in isolation
- Mock external dependencies (git, filesystem)
- Fast execution (<1 second total)

### Integration Tests

- Test with real M5Unified repository
- Verify generated file contents
- Slower execution (5-10 seconds)

### Test Coverage Target

- 100% line coverage
- 100% branch coverage
- All edge cases covered

---

## References

- Original implementation: `/home/user/picotorokko/m5unified.rb`
- Original spec: `/home/user/picotorokko/m5unified.md`
- M5Unified: https://github.com/m5stack/M5Unified
- libclang: https://clang.llvm.org/doxygen/group__CINDEX.html
- ffi-clang: https://github.com/ioquatix/ffi-clang
