# picotorokko (ptrk)

**picotorokko** — [PicoRuby](https://github.com/picoruby) Application on [R2P2-ESP32](https://github.com/picoruby/R2P2-ESP32) Development Kit — is a modern build system CLI for ESP32 + PicoRuby development.

The name "picotorokko" draws inspiration from **torokko** (トロッコ), a simple lightweight railway system in Japan. Just as "Rails" in Ruby on Rails evokes railways, the "torokko" in picotorokko represents a simplified development framework that provides structure and conventions without heavyweight complexity. It manages multiple versions of R2P2-ESP32 and its nested submodules (picoruby-esp32 → picoruby) in parallel, enabling seamless environment switching and validation across versions.

[![Ruby](https://github.com/bash0C7/picotorokko/actions/workflows/main.yml/badge.svg)](https://github.com/bash0C7/picotorokko/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/bash0C7/picotorokko/branch/main/graph/badge.svg)](https://codecov.io/gh/bash0C7/picotorokko)

## For PicoRuby Application Users

### Quick Start

#### 1. Create a new project

```bash
ptrk new my-project
cd my-project
```

**Options**:
- `--author "Your Name"` — Set project author (default: auto-detected from git config)
- `--path /path/to/dir` — Create project in specified directory
- `--with-ci` — Include GitHub Actions workflow

#### 2. Setup environment and build

```bash
# Fetch latest repository versions
ptrk env set --latest

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

#### Project Creation

```bash
ptrk new [PROJECT_NAME]
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
ptrk env set --latest           # Fetch latest versions with timestamp name
ptrk env current [NAME]         # Get or set current environment
ptrk env list                   # List all environments
ptrk env set <NAME>             # Create/update environment
ptrk env show [NAME]            # Display environment details (default: current)
ptrk env reset [NAME]           # Reset environment (default: current)
```

**Note**: Commands that accept `[NAME]` use the current environment when omitted.

**`ptrk env set --latest` workflow**:

This command fetches the latest commits from all PicoRuby repositories and clones them to `.ptrk_env/{YYYYMMDD_HHMMSS}/`:

1. Fetches latest commit SHAs from R2P2-ESP32, picoruby-esp32, and picoruby
2. Creates environment definition in `.picoruby-env.yml`
3. Clones R2P2-ESP32 with `--filter=blob:none` for faster download
4. Checks out to specified commit
5. Initializes submodules recursively (`git submodule update --init --recursive`)
6. Checks out picoruby-esp32 and picoruby to specified commits
7. Stages and amends commit with environment name
8. Disables push on all repositories to prevent accidental pushes

#### Patch Management

```bash
ptrk patch list                 # List available patches in current environment
ptrk patch diff                 # Show diff between build workspace and patches
ptrk patch export               # Export build workspace changes to patches
```

**Workflow**:
1. Use `ptrk device prepare` to create/prepare the build workspace
2. Make changes directly in `.ptrk_build/{env}/R2P2-ESP32/`
3. Use `ptrk patch diff` to review your changes
4. Use `ptrk patch export` to save changes as patches
5. Patches are automatically applied from both `.ptrk_env/patch/` and `project-root/patch/` during device prepare

#### Device Operations

```bash
ptrk device prepare             # Prepare build workspace with patches applied
ptrk device build               # Build firmware (auto-prepares if needed)
ptrk device flash               # Flash to device
ptrk device monitor             # Monitor serial output
ptrk device setup_esp32         # Setup ESP32 environment
ptrk device tasks               # Show R2P2-ESP32 available tasks
```

All device commands use the current environment by default. Use `--env NAME` to specify a different environment.

**Note**: `ptrk device build` automatically runs `prepare` if the build workspace doesn't exist, but preserves existing workspaces to avoid losing your changes.

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

- Ruby 3.3 or higher
- Bundler
- Git
- ESP-IDF (for build/flash/monitor tasks)

### Configuration

Environment metadata is stored in `.picoruby-env.yml`. The system uses two directories:
- `.ptrk_env/{YYYYMMDD_HHMMSS}/` — Readonly environment cache (git working copies)
- `.ptrk_build/{YYYYMMDD_HHMMSS}/` — Build working directory (patches applied)

Environment names follow the format `YYYYMMDD_HHMMSS` (e.g., `20251122_103000`).

Each environment definition includes:
- Repository commit SHAs for R2P2-ESP32, picoruby-esp32, and picoruby
- Timestamps for each repository
- Current environment tracking

### Documentation

For detailed specifications, see [docs/SPECIFICATION.md](docs/SPECIFICATION.md).

### CI/CD Integration

For PicoRuby application developers using GitHub Actions for automated builds, see [docs/CI_CD_GUIDE.md](docs/CI_CD_GUIDE.md).

For picotorokko gem developers releasing to RubyGems, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Features

- **Project Templates**: Auto-generate `.rubocop.yml` and enhanced `CLAUDE.md` with PicoRuby development guides
- **Environment Management**: Define, list, and manage multiple PicoRuby build environments with version control
- **Current Environment Tracking**: `ptrk env current` sets the active environment for all device commands
- **Environment Metadata Capture**: `ptrk env set --latest` records the newest repository commits in `.picoruby-env.yml`
- **RuboCop Configuration Generation**: Auto-generates PicoRuby-specific RuboCop config from RBS files
- **Smart Build Detection**: Detects `Gemfile` and uses appropriate Rake invocation (bundle exec vs rake)
- **Centralized Directory Structure**: Readonly `.ptrk_env/` cache and mutable `.ptrk_build/` working directory
- **Git Integration**: Clone and manage repositories with automatic submodule handling
- **Automatic Patch Application**: Patches applied automatically during `ptrk device build`
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

- [docs/SPECIFICATION.md](docs/SPECIFICATION.md) - Complete specification of ptrk commands and behavior
- [docs/CI_CD_GUIDE.md](docs/CI_CD_GUIDE.md) - GitHub Actions workflows for PicoRuby application users
- [docs/MRBGEMS_GUIDE.md](docs/MRBGEMS_GUIDE.md) - Creating application-specific mrbgems
- [docs/RUBOCOP_PICORUBY_GUIDE.md](docs/RUBOCOP_PICORUBY_GUIDE.md) - RuboCop setup for PicoRuby development

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

### Test Architecture

The picotorokko gem uses a **three-layer test classification system** to balance speed, isolation, and real-world verification:

#### Layer 1: Unit Tests (Fast, Mocked)
**Location**: `test/unit/**/*_test.rb`
- Fast execution with mocked dependencies
- Mocked external dependencies (network, file I/O, system commands)
- Focused on single class/module behavior
- Examples: `test/unit/commands/init_test.rb`, `test/unit/template/yaml_engine_test.rb`

```bash
# Run unit tests only (fastest feedback)
bundle exec rake test:unit
```

#### Layer 2: Integration Tests (Real Operations)
**Location**: `test/integration/**/*_test.rb`
- Real git operations (git clone, checkout, show)
- Real network calls to GitHub API
- Tests interactions between components
- Examples: `test/integration/env_test.rb`, `test/integration/commands/env_test.rb`

```bash
# Run integration tests
bundle exec rake test:integration
```

#### Layer 3: Scenario Tests (User Workflows)
**Location**: `test/scenario/**/*_test.rb`
- Complete user workflow verification
- Project creation scenarios, device commands
- Template rendering and variable substitution
- Examples: `test/scenario/init_scenario_test.rb`, `test/scenario/commands/device_test.rb`

```bash
# Run scenario tests
bundle exec rake test:scenario
```

#### Test Execution

**Quick Reference**:
```bash
# Development (unit tests only - fastest)
bundle exec rake

# All tests (unit → integration → scenario)
bundle exec rake test

# CI suite (all tests + RuboCop + coverage validation)
bundle exec rake ci

# Development mode with RuboCop auto-fix
bundle exec rake dev
```

#### Test Result Verification

Tests must be verified using **shell exit codes**:
- **Exit code 0** = All tests passed
- **Non-zero exit code** = Tests failed

```bash
# Example: Verify test success
bundle exec rake ci > /tmp/test_output.txt 2>&1
if [ $? -eq 0 ]; then
  echo "✓ All tests passed"
else
  echo "✗ Tests failed"
  tail /tmp/test_output.txt  # View detailed output
fi
```

**Important**: Always capture test output to temporary files and use `grep`/`tail` for analysis, not relying on stdout directly.

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
