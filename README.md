# pra - PicoRuby Application Platform

[![Ruby](https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/actions/workflows/main.yml/badge.svg)](https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/branch/main/graph/badge.svg)](https://codecov.io/gh/bash0C7/picoruby-application-on-r2p2-esp32-development-kit)

**pra** is a multi-version build system for ESP32 + PicoRuby development that manages multiple versions of R2P2-ESP32 and its nested submodules (picoruby-esp32 → picoruby) in parallel, allowing easy switching and validation across versions.

## Features

- **Immutable Cache**: Repositories are uniquely identified by commit hash + timestamp and never modified
- **Environment Isolation**: Multiple build environments can coexist simultaneously
- **Patch Management**: Git-managed changes in the `patch/` directory with automatic application
- **Task Delegation**: Build/flash/monitor tasks delegated to R2P2-ESP32's Rakefile

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
bundle exec pra flash
bundle exec pra monitor
```

## Commands Reference

### Environment Management

- `pra env show` - Display current environment configuration
- `pra env set ENV_NAME` - Switch to specified environment
- `pra env latest` - Fetch latest versions and switch to them

### Cache Management

- `pra cache list` - Display list of cached repository versions
- `pra cache fetch [ENV_NAME]` - Fetch specified environment from GitHub and save to cache
- `pra cache clean REPO` - Delete all caches for specified repo
- `pra cache prune` - Delete caches not referenced by any environment

### Build Environment Management

- `pra build setup [ENV_NAME]` - Setup build environment for specified environment
- `pra build clean [ENV_NAME]` - Delete specified build environment
- `pra build list` - Display list of constructed build environments

### Patch Management

- `pra patch export [ENV_NAME]` - Export changes from build environment to patch directory
- `pra patch apply [ENV_NAME]` - Apply patches to build environment
- `pra patch diff [ENV_NAME]` - Display differences between working changes and stored patches

### R2P2-ESP32 Task Delegation

- `pra flash [ENV_NAME]` - Flash firmware to ESP32 (delegates to R2P2-ESP32)
- `pra monitor [ENV_NAME]` - Monitor ESP32 serial output (delegates to R2P2-ESP32)

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

## Development

After checking out the repo:

### 1. Configure Bundler for vendor/bundle isolation

```bash
bundle config set --local path 'vendor/bundle'
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Run tests

```bash
bundle exec rake test
```

### 4. Run linter

```bash
bundle exec rubocop
```

### 5. Build the gem

```bash
bundle exec gem build pra.gemspec
```

### 6. Test CLI locally

```bash
bundle exec exe/pra --help
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).