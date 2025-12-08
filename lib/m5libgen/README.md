# M5LibGen

M5Unified C++ Library → PicoRuby mrbgem Generator

A RubyGem that automatically generates PicoRuby mrbgems for wrapping the [M5Unified](https://github.com/m5stack/M5Unified) C++ library.

## Overview

M5LibGen analyzes M5Unified C++ header files using libclang, extracts class definitions, methods, and types, then generates complete mrbgem packages with:

- C bindings for mrubyc
- C++ extern "C" wrappers
- CMakeLists.txt for ESP-IDF
- Ruby documentation
- Type mapping (C++ ↔ mruby)

## Features

- **libclang-based C++ Parser**: Accurate AST parsing for complex C++ code
- **Automatic Type Mapping**: C++ types → mruby types
- **Complete mrbgem Generation**: Directory structure, binding code, build files
- **M5Unified API Pattern Detection**: Button singletons, Display classes, predicate methods
- **ESP-IDF Integration**: CMake configuration for ESP32 builds

## Architecture

```
M5LibGen
├── RepositoryManager    - Clone/update M5Unified repository
├── HeaderReader         - List and read .h files
├── LibClangParser       - Parse C++ with libclang AST
├── TypeMapper           - Map C++ types to mruby types
├── MrbgemGenerator      - Generate mrbgem structure and files
├── CppWrapperGenerator  - Generate extern "C" wrappers
├── CMakeGenerator       - Generate CMakeLists.txt
└── ApiPatternDetector   - Detect M5Unified-specific patterns
```

## Installation

Add to your `Gemfile`:

```ruby
gem 'm5libgen', path: 'lib/m5libgen'
```

Or install locally:

```bash
cd lib/m5libgen
bundle install
```

## Usage

### CLI (Recommended)

```bash
# Clone M5Unified repository
m5libgen clone https://github.com/m5stack/M5Unified.git

# Generate mrbgem
m5libgen generate output/mrbgem-picoruby-m5unified
```

### Ruby API

```ruby
require 'm5libgen'

# Clone repository
repo = M5LibGen::RepositoryManager.new('vendor/m5unified')
repo.clone(url: 'https://github.com/m5stack/M5Unified.git')

# Generate mrbgem
generator = M5LibGen::MrbgemGenerator.new('output/mrbgem-picoruby-m5unified')
generator.generate_from_repository('vendor/m5unified')
```

## Generated mrbgem Structure

```
mrbgem-picoruby-m5unified/
├── mrbgem.rake                      # Gem specification
├── mrblib/
│   └── m5unified.rb                 # Ruby documentation
├── src/
│   └── m5unified.c                  # C bindings
├── ports/
│   └── esp32/
│       └── m5unified_wrapper.cpp    # extern "C" wrapper
├── CMakeLists.txt                   # ESP-IDF build config
└── README.md                         # Generated documentation
```

## Type Mapping

| C++ Type                  | mruby Type       |
|---------------------------|------------------|
| int, int8_t, ..., size_t  | MRBC_TT_INTEGER  |
| float, double             | MRBC_TT_FLOAT    |
| const char*, char*        | MRBC_TT_STRING   |
| bool                      | MRBC_TT_TRUE     |
| void                      | nil              |
| Type* (pointer)           | MRBC_TT_OBJECT   |

## Development Status

See [TODO.md](TODO.md) for current progress and roadmap.

## Requirements

- Ruby 3.4+
- libclang (via ffi-clang gem)
- git

## Dependencies

```ruby
gem 'ffi-clang', '~> 0.10.0'
gem 'test-unit'
gem 'rubocop'
```

## Testing

```bash
cd lib/m5libgen
bundle exec ruby -Ilib:test test/all_tests.rb
```

## Project Context

This gem is part of the [picotorokko](https://github.com/bash0C7/picotorokko) project, a CLI tool for PicoRuby application development on ESP32.

## License

MIT

## References

- [M5Unified](https://github.com/m5stack/M5Unified) - M5Stack unified library
- [PicoRuby](https://github.com/picoruby/picoruby) - Ruby for microcontrollers
- [mrubyc](https://github.com/mrubyc/mrubyc) - mruby VM for embedded systems
- [ffi-clang](https://github.com/ioquatix/ffi-clang) - Ruby FFI bindings to libclang
