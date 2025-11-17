# picotorokko (ptrk)

**picotorokko** — [PicoRuby](https://github.com/picoruby) Application on [R2P2-ESP32](https://github.com/picoruby/R2P2-ESP32) Development Kit — is a modern build system CLI for ESP32 + PicoRuby development.

The name "picotorokko" draws inspiration from **torokko** (トロッコ), a simple lightweight railway system in Japan. Just as "Rails" in Ruby on Rails evokes railways, the "torokko" in picotorokko represents a simplified development framework that provides structure and conventions without heavyweight complexity. It manages multiple versions of R2P2-ESP32 and its nested submodules (picoruby-esp32 → picoruby) in parallel, enabling seamless environment switching and validation across versions.

[![Ruby](https://github.com/bash0C7/picotorokko/actions/workflows/main.yml/badge.svg)](https://github.com/bash0C7/picotorokko/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/bash0C7/picotorokko/branch/main/graph/badge.svg)](https://codecov.io/gh/bash0C7/picotorokko)

## For PicoRuby Application Users

### Quick Start

#### 1. Initialize a new project

```bash
ptrk init my-project
cd my-project
```

**Options**:
- `--author "Your Name"` — Set project author (default: auto-detected from git config)
- `--path /path/to/dir` — Create project in specified directory
- `--with-ci` — Include GitHub Actions workflow

#### 2. Setup environment and build

```bash
# Fetch latest repository versions
ptrk env latest

# Build firmware
ptrk device build

# Flash to device
ptrk device flash

# Monitor serial output
ptrk device monitor
```

#### 3. Create additional mrbgems (optional)

```bash
ptrk mrbgems generate MySensor
ptrk mrbgems generate MyMotor
```

### Commands Reference

#### Project Initialization

```bash
ptrk init [PROJECT_NAME]
```

Options:
- `--author "Name"` — Set project author
- `--path /dir` — Create project in specified directory
- `--with-ci` — Include GitHub Actions workflow

Creates a new PicoRuby project with:
- Complete directory structure and default `app` mrbgem
- `.rubocop.yml` — PicoRuby-specific linting configuration (stricter method length limits for memory efficiency)
- `CLAUDE.md` — Comprehensive development guide including:
  - mrbgems dependency management
  - Peripheral APIs (I2C, GPIO, RMT) with code examples
  - Memory optimization techniques
  - RuboCop configuration
  - Picotest testing framework
- `Mrbgemfile` — mrbgems dependency declarations with picoruby-picotest reference
- `README.md` — Quick start guide with implemented ptrk commands
- Optional GitHub Actions workflow (with `--with-ci` flag)

#### Environment Management

```bash
ptrk env latest                 # Fetch latest versions and create 'latest' environment
ptrk env list                   # List all environments
ptrk env set <NAME>             # Create/update environment
ptrk env show <NAME>            # Display environment details
ptrk env reset <NAME>           # Reset environment
```

#### Patch Management

```bash
ptrk env patch_apply <NAME>     # Apply patches to environment
ptrk env patch_export <NAME>    # Export changes to patches
ptrk env patch_diff <NAME>      # Show diff between working changes and patches
```

#### Device Operations

```bash
ptrk device build               # Build firmware
ptrk device flash               # Flash to device
ptrk device monitor             # Monitor serial output
ptrk device setup_esp32         # Setup ESP32 environment
ptrk device tasks               # Show R2P2-ESP32 available tasks
```

#### mrbgem Management

```bash
ptrk mrbgems generate [NAME]    # Generate application-specific mrbgem
```

### Mrbgemfile Configuration

Create `Mrbgemfile` in your project root to declare mrbgem dependencies:

```ruby
mrbgems do |conf|
  # Core mrbgems
  conf.gem core: "sprintf"
  conf.gem core: "fiber"

  # GitHub repositories
  conf.gem github: "picoruby/picoruby-json", branch: "main"
  conf.gem github: "picoruby/picoruby-yaml"

  # Platform-specific (ESP32)
  if conf.build_config_files.include?("xtensa-esp")
    conf.gem github: "picoruby/picoruby-esp32-gpio"
  end

  # Local gems
  conf.gem path: "./mrbgems/app"
end
```

Supported gem sources:
- `github: "org/repo"` — GitHub repository
- `core: "name"` — Core mrbgem
- `path: "./local"` — Local path
- `git: "https://..."` — Custom Git URL

See [docs/MRBGEMS_GUIDE.md](docs/MRBGEMS_GUIDE.md) for complete documentation.

### Requirements

- Ruby 3.0 or higher
- Bundler
- Git
- ESP-IDF (for build/flash/monitor tasks)

### Configuration

Environment metadata is stored in `ptrk_env/.picoruby-env.yml`. Each environment definition includes:
- Environment name (lowercase alphanumeric, hyphens, underscores: `/^[a-z0-9_-]+$/`)
- Repository paths for R2P2-ESP32, picoruby-esp32, and picoruby
- Optional: Commit SHA and branch information

### Documentation

For detailed specifications, see [SPEC.md](SPEC.md).

### CI/CD Integration

For PicoRuby application developers using GitHub Actions for automated builds, see [docs/CI_CD_GUIDE.md](docs/CI_CD_GUIDE.md).

For picotorokko gem developers releasing to RubyGems, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Features

- **Project Templates**: Auto-generate `.rubocop.yml` and enhanced `CLAUDE.md` with PicoRuby development guides
- **Environment Management**: Define, list, and manage multiple PicoRuby build environments with version control
- **Automatic Repository Setup**: `ptrk env latest` auto-clones and checks out repositories to `ptrk_env/`
- **Smart Build Detection**: Detects `Gemfile` and uses appropriate Rake invocation (bundle exec vs rake)
- **Centralized Directory Structure**: All environment data stored in `ptrk_env/` for clean project organization
- **Git Integration**: Clone and manage repositories with automatic submodule handling
- **Patch Management**: Export, apply, and diff patches across environments
- **Task Delegation**: Build/flash/monitor tasks transparently delegated to R2P2-ESP32's Rakefile
- **Executor Abstraction**: Clean dependency injection for testable command execution with Open3 integration
- **Template Engines**: AST-based template generation for Ruby, YAML, and C code

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'picotorokko'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install picotorokko
```

## For picotorokko Gem Developers

### Documentation

#### API Documentation

- [**RubyDoc.info**](https://rubydoc.info/gems/picotorokko/) - Generated from RBS type definitions
- [Type System & Annotations](docs/type-annotation-guide.md) - How we use rbs-inline annotations and Steep type checking

#### Architecture & Design

- [Executor Abstraction](docs/architecture/executor-abstraction-design.md) - Dependency injection pattern for system command testing with ProductionExecutor and MockExecutor
- [Prism Rakefile Parser](docs/architecture/prism-rakefile-parser-design.md) - AST-based static analysis for dynamic Rake task extraction and whitelist validation

See [docs/architecture/](docs/architecture/) for complete architecture documentation index.

#### User & Developer Guides

- [SPEC.md](SPEC.md) - Complete specification of ptrk commands and behavior
- [CI/CD Integration Guide](docs/CI_CD_GUIDE.md) - GitHub Actions workflows for PicoRuby application users
- [mrbgems Development Guide](docs/MRBGEMS_GUIDE.md) - Creating application-specific mrbgems
- [RuboCop Integration Guide](docs/RUBOCOP_PICORUBY_GUIDE.md) - RuboCop setup for PicoRuby development

### Development

After checking out the repo:

#### 1. Install dependencies

```bash
bundle install
```

#### 2. Run tests

```bash
# Run all tests
bundle exec rake

# Or run specific test suites
bundle exec rake test          # Main test suite
```

#### 3. Development workflow: RuboCop auto-fix + tests + coverage

```bash
bundle exec rake dev
```

This runs RuboCop auto-correction, all tests, and validates coverage in one command.

#### 4. CI validation (RuboCop check + tests + coverage, no auto-fix)

```bash
bundle exec rake ci
```

This runs the complete CI checks without auto-correction (for CI/CD pipelines).

#### 5. Build the gem

```bash
bundle exec gem build picotorokko.gemspec
```

#### 6. Test CLI locally

```bash
bundle exec exe/ptrk --help
```

#### 7. Type checking with Steep (optional)

The gem includes rbs-inline type annotations for all public and private methods, enabling static type checking:

```bash
# Run Steep type checker (requires steep gem)
bundle exec steep check

# Generate RBS signatures from rbs-inline annotations
bundle exec rake rbs:generate
```

**Type Annotation Coverage**: 93.2% (165 of 177 methods)

All command classes and core modules include complete type signatures using rbs-inline format:
- **Template Engines** (19 methods): Engine, RubyTemplateEngine, StringTemplateEngine, YamlTemplateEngine, CTemplateEngine
- **Core Modules** (16 methods): Executor, PatchApplier, MrbgemsDSL, BuildConfigApplier
- **Commands** (42 methods): Device, Env, Mrbgems, Rubocop, Init

Example type annotation:

```ruby
# lib/picotorokko/commands/device.rb
class Device < Thor
  # @rbs (String) -> String
  private def resolve_env_name(env_name)
    # implementation
  end
end
```

Refer to `.claude/docs/testing-guidelines.md` for TDD + RuboCop integration workflow details.

### Testing with Reality Marble

[Reality Marble](lib/reality_marble) is a powerful mocking gem integrated into picotorokko's test suite. It uses native Ruby syntax for elegant method mocking with automatic cleanup:

#### Basic Usage

Reality Marble uses native Ruby `define_singleton_method` to define mocks:

```ruby
require "reality_marble"

class MyTest < Test::Unit::TestCase
  test "mocks File operations" do
    marble = RealityMarble.chant do
      File.define_singleton_method(:exist?) do |path|
        path == "/expected/path"
      end
    end

    marble.activate do
      assert File.exist?("/expected/path")
      assert_false File.exist?("/other/path")
    end
  end

  teardown do
    RealityMarble::Context.reset_current
  end
end
```

#### Method Lifecycle

Methods defined during `chant` are automatically:
- **Stored** during chant block execution
- **Removed** after chant block (before activation)
- **Reapplied** during activation block
- **Cleaned up** after activation block

```ruby
test "methods are safely scoped to activation block" do
  test_class = Class.new

  marble = RealityMarble.chant do
    test_class.define_singleton_method(:value) { 42 }
  end

  # Before activation: method does not exist
  assert_raises(NoMethodError) { test_class.value }

  # During activation: method is available
  marble.activate do
    assert_equal 42, test_class.value
  end

  # After activation: method is removed again
  assert_raises(NoMethodError) { test_class.value }
end
```

#### Capturing State

Use the `capture` option to share state with mock methods:

```ruby
test "captures and modifies state during mock execution" do
  call_log = { count: 0 }

  marble = RealityMarble.chant(capture: { log: call_log }) do |cap|
    Dir.define_singleton_method(:glob) do |pattern|
      cap[:log][:count] += 1
      ["/mock/file#{cap[:log][:count]}.txt"]
    end
  end

  marble.activate do
    Dir.glob("*.txt")
    Dir.glob("*.txt")
    assert_equal 2, call_log[:count]
  end
end
```

For complete documentation, examples, and design rationale, see:
- [Reality Marble README](lib/reality_marble/README.md)
- [API Documentation](lib/reality_marble/docs/API.md)
- [Examples](lib/reality_marble/examples/)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
