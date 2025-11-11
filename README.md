# picotorokko (ptrk)

**picotorokko** — [PicoRuby](https://github.com/picoruby) Application on [R2P2-ESP32](https://github.com/picoruby/R2P2-ESP32) Development Kit — is a modern build system CLI for ESP32 + PicoRuby development.

The name "picotorokko" draws inspiration from **torokko** (トロッコ), a simple lightweight railway system in Japan. Just as "Rails" in Ruby on Rails evokes railways, the "torokko" in picotorokko represents a simplified development framework that provides structure and conventions without heavyweight complexity. It manages multiple versions of R2P2-ESP32 and its nested submodules (picoruby-esp32 → picoruby) in parallel, enabling seamless environment switching and validation across versions.

[![Ruby](https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/actions/workflows/main.yml/badge.svg)](https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/branch/main/graph/badge.svg)](https://codecov.io/gh/bash0C7/picoruby-application-on-r2p2-esp32-development-kit)

## Features

- **Environment Management**: Define, list, and manage multiple PicoRuby build environments with version control
- **Centralized Directory Structure**: All environment data stored in `ptrk_env/` for clean project organization
- **Git Integration**: Clone and manage repositories with automatic submodule handling
- **Patch Management**: Export, apply, and diff patches across environments
- **Task Delegation**: Build/flash/monitor tasks transparently delegated to R2P2-ESP32's Rakefile
- **Executor Abstraction**: Clean dependency injection for command execution with Open3 integration ✅ Phase 0 Complete

## Development Status

### ✅ Phase 0: Infrastructure & System Mocking (COMPLETED)

- Executor abstraction with ProductionExecutor (Open3) and MockExecutor (testing)
- Pra::Env refactoring with dependency injection pattern
- 3 git error handling tests re-enabled via MockExecutor
- All 151 main tests + 14 device tests passing (165 total)
- Coverage: 85.86% line, 64.11% branch

### ✅ AST-Based Template Engine (COMPLETED)

- RubyTemplateEngine: Prism-based AST manipulation for .rb files
- YamlTemplateEngine: Psych-based recursive placeholder replacement
- CTemplateEngine: Simple string substitution for C templates
- Full test coverage for all template engines

### 🔮 Upcoming: Phase 1 Device Integration

- Apply executor pattern to device.rb and device_test.rb
- Unify test execution model for seamless development workflow

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

## For PicoRuby Application Users

### Quick Start

#### 1. Create a new environment

```bash
bundle exec ptrk env set development --commit abc1234
```

#### 2. List all environments

```bash
bundle exec ptrk env list
```

#### 3. View environment details

```bash
bundle exec ptrk env show development
```

#### 4. Build, flash, and monitor

```bash
bundle exec ptrk device flash --env development
bundle exec ptrk device monitor --env development
bundle exec ptrk device build --env development
```

### Commands Reference

#### Environment Management

- `ptrk env list` - List all environments in `ptrk_env/`
- `ptrk env set <NAME> [--commit <SHA>] [--branch <BRANCH>]` - Create or update an environment
- `ptrk env reset <NAME>` - Reset an environment by removing and recreating it
- `ptrk env show [NAME]` - Show details of a specific environment

#### Patch Management

- `ptrk env patch_export <NAME>` - Export uncommitted changes from environment to local patch directory
- `ptrk env patch_apply <NAME>` - Apply stored patches to environment
- `ptrk env patch_diff <NAME>` - Display differences between working changes and stored patches

#### Application-Specific mrbgem Management

- `ptrk mrbgems generate [NAME]` - Generate application-specific mrbgem template (default: App)
  - Creates `mrbgems/{NAME}/` with Ruby code and C extension template
  - Use `--author` option to specify author name: `ptrk mrbgems generate --author "Your Name"`

#### PicoRuby RuboCop Configuration

- `ptrk rubocop setup` - Setup RuboCop configuration for PicoRuby development
- `ptrk rubocop update` - Update PicoRuby method database from latest definitions

For detailed guide, see [docs/RUBOCOP_PICORUBY_GUIDE.md](docs/RUBOCOP_PICORUBY_GUIDE.md).

#### Device Operations

- `ptrk device flash --env <NAME>` - Flash firmware to ESP32
- `ptrk device monitor --env <NAME>` - Monitor ESP32 serial output
- `ptrk device build --env <NAME>` - Build firmware for ESP32
- `ptrk device setup_esp32 --env <NAME>` - Setup ESP32 build environment
- `ptrk device help --env <NAME>` - Show available R2P2-ESP32 tasks

The `ptrk device` command transparently delegates tasks to R2P2-ESP32's Rakefile:

```bash
# Run any Rake task defined in R2P2-ESP32
bundle exec ptrk device <task_name> --env <NAME>

# Examples (assuming these tasks exist in R2P2-ESP32):
bundle exec ptrk device custom_task --env development
bundle exec ptrk device build_app --env development
```

#### Other

- `ptrk version` or `ptrk -v` - Show ptrk version

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

## For picotorokko Gem Developers

### Development

After checking out the repo:

#### 1. Install dependencies

```bash
bundle install
```

#### 2. Run tests

```bash
bundle exec rake test
```

#### 3. Code Quality: RuboCop

We use RuboCop for code style enforcement:

```bash
bundle exec rubocop -A
```

#### 4. Run full quality suite (tests + RuboCop + coverage validation)

```bash
bundle exec rake ci
```

#### 5. Build the gem

```bash
bundle exec gem build picotorokko.gemspec
```

#### 6. Test CLI locally

```bash
bundle exec exe/ptrk --help
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
