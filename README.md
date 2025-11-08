# [PicoRuby](https://github.com/picoruby) Application on [R2P2-ESP32](https://github.com/picoruby/R2P2-ESP32) development kit

Packaged by pra command

**pra** (**P**ico**R**uby **A**pplication) is a multi-version build system for ESP32 + PicoRuby development that manages multiple versions of R2P2-ESP32 and its nested submodules (picoruby-esp32 → picoruby) in parallel, allowing easy switching and validation across versions.

[![Ruby](https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/actions/workflows/main.yml/badge.svg)](https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/branch/main/graph/badge.svg)](https://codecov.io/gh/bash0C7/picoruby-application-on-r2p2-esp32-development-kit)

## Features

- **Immutable Cache**: Repositories are uniquely identified by commit hash + timestamp and never modified
- **Environment Isolation**: Multiple build environments can coexist simultaneously
- **Patch Management**: Git-managed changes in the `patch/` directory with automatic application
- **Task Delegation**: Build/flash/monitor tasks delegated to R2P2-ESP32's Rakefile

## Terminology

This project uses specific terminology to distinguish between different concepts:

- **Environment Definition**: Metadata stored in `.picoruby-env.yml` that defines commit hashes and timestamps for three repositories (R2P2-ESP32, picoruby-esp32, picoruby). Managed by `pra env` commands.

- **Build Environment**: A working directory in `build/` that contains actual repository files for building firmware. Managed by `pra build` commands.

- **Cache**: Immutable repository copies stored in `.cache/` indexed by commit hash and timestamp. These are never modified after creation. Managed by `pra cache` commands.

**Workflow**: First, define an environment in `.picoruby-env.yml` → Then fetch repositories to cache → Finally setup a build environment from the cache.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pra'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install pra
```

## Quick Start

### 1. Check current environment

```bash
bundle exec pra env show
```

### 2. Fetch environment from cache

If you have a `.picoruby-env.yml` with environment definitions:

```bash
bundle exec pra cache fetch stable-2024-11
```

### 3. Setup build environment

```bash
bundle exec pra build setup stable-2024-11
```

### 4. Build, flash, and monitor

```bash
bundle exec pra device flash
bundle exec pra device monitor
```

## Commands Reference

### Environment Definition Management

- `pra env show` - Display current environment definition from .picoruby-env.yml
- `pra env set ENV_NAME` - Switch to specified environment definition (updates build/current symlink)
- `pra env latest` - Fetch latest commit versions and create environment definition

### Cache Management

- `pra cache list` - Display list of cached repository versions
- `pra cache fetch [ENV_NAME]` - Fetch specified environment from GitHub and save to cache
- `pra cache clean REPO` - Delete all caches for specified repo
- `pra cache prune` - Delete caches not referenced by any environment

### Build Environment Management

- `pra build setup [ENV_NAME]` - Setup build environment from environment definition (.picoruby-env.yml)
- `pra build clean [ENV_NAME]` - Delete specified build environment directory
- `pra build list` - Display list of constructed build environment directories

### Application-Specific mrbgem Management

- `pra mrbgems generate [NAME]` - Generate application-specific mrbgem template (default: App)
  - Creates `mrbgems/{NAME}/` with Rubyコード and C extension template
  - Automatically registers mrbgem in build_config and CMakeLists.txt during `pra build setup`
  - Use `--author` option to specify author name: `pra mrbgems generate --author "Your Name"`

### Patch Management

- `pra patch export [ENV_NAME]` - Export changes from build environment to patch directory
- `pra patch apply [ENV_NAME]` - Apply patches to build environment
- `pra patch diff [ENV_NAME]` - Display differences between working changes and stored patches

### R2P2-ESP32 Device Operations

#### Explicit Commands

- `pra device flash [ENV_NAME]` - Flash firmware to ESP32 (delegates to R2P2-ESP32's `rake flash`)
- `pra device monitor [ENV_NAME]` - Monitor ESP32 serial output (delegates to R2P2-ESP32's `rake monitor`)
- `pra device build [ENV_NAME]` - Build firmware for ESP32 (delegates to R2P2-ESP32's `rake build`)
- `pra device setup_esp32 [ENV_NAME]` - Setup ESP32 build environment (delegates to R2P2-ESP32's `rake setup_esp32`)
- `pra device help [ENV_NAME]` - Show available R2P2-ESP32 tasks for the environment

#### Dynamic Rake Task Delegation

The `pra device` command uses Ruby's `method_missing` to transparently delegate any undefined subcommand to R2P2-ESP32's Rakefile. This allows you to run any Rake task defined in R2P2-ESP32 without explicit `pra device` commands:

```bash
# Run custom Rake tasks directly
bundle exec pra device <custom_rake_task> [ENV_NAME]

# Examples (assuming these tasks exist in R2P2-ESP32):
bundle exec pra device custom_task my-env
bundle exec pra device build_app my-env
```

**Usage Pattern**:
1. Get list of available tasks: `pra device help my-env`
2. Run any task: `pra device <task_name> my-env`
3. Default environment: If `[ENV_NAME]` is omitted, uses the current environment (set via `pra env set`)

### Other

- `pra version` or `pra -v` - Show pra version

## Requirements

- Ruby 3.0 or higher
- Bundler
- Git
- ESP-IDF (for build/flash/monitor tasks)

## Configuration File

See `.picoruby-env.yml` for environment configuration examples. Each environment defines commit hashes and timestamps for R2P2-ESP32, picoruby-esp32, and picoruby repositories.

## Documentation

For detailed specifications, see [SPEC.md](SPEC.md).

## CI/CD Integration

For PicoRuby application developers using GitHub Actions for automated builds, see [docs/CI_CD_GUIDE.md](docs/CI_CD_GUIDE.md).

For gem developers releasing to RubyGems, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Development

After checking out the repo:

### 1. Install dependencies

```bash
bundle install
```

### 2. Run tests

```bash
bundle exec rake test
```

### 3. Code Quality: RuboCop

We use RuboCop for code style enforcement:

```bash
bundle exec rubocop -A
```

### 4. Build the gem

```bash
bundle exec gem build pra.gemspec
```

### 5. Test CLI locally

```bash
bundle exec exe/pra --help
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
