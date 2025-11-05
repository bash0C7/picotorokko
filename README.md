# pap - PicoRuby Application Platform

**pap** is a multi-version build system for ESP32 + PicoRuby development that manages multiple versions of R2P2-ESP32 and its nested submodules (picoruby-esp32 → picoruby) in parallel, allowing easy switching and validation across versions.

## Features

- **Immutable Cache**: Repositories are uniquely identified by commit hash + timestamp and never modified
- **Environment Isolation**: Multiple build environments can coexist simultaneously
- **Patch Management**: Git-managed changes in the `patch/` directory with automatic application
- **Task Delegation**: Build/flash/monitor tasks delegated to R2P2-ESP32's Rakefile

## Installation

### Configure Bundler for vendor/bundle isolation

```bash
bundle config set --local path 'vendor/bundle'
```

### Install dependencies

```bash
bundle install
```

### Build the gem (optional)

```bash
bundle exec gem build pap.gemspec
```

## Quick Start

### 1. Check current environment

```bash
bundle exec exe/pap env show
```

### 2. Fetch environment from cache

If you have a `.picoruby-env.yml` with environment definitions:

```bash
bundle exec exe/pap cache fetch stable-2024-11
```

### 3. Setup build environment

```bash
bundle exec exe/pap build setup stable-2024-11
```

### 4. Build, flash, and monitor

```bash
bundle exec exe/pap flash
bundle exec exe/pap monitor
```

## Commands Reference

### Environment Management

- `pap env show` - Display current environment configuration
- `pap env set ENV_NAME` - Switch to specified environment
- `pap env latest` - Fetch latest versions and switch to them

### Cache Management

- `pap cache list` - Display list of cached repository versions
- `pap cache fetch [ENV_NAME]` - Fetch specified environment from GitHub and save to cache
- `pap cache clean REPO` - Delete all caches for specified repo
- `pap cache prune` - Delete caches not referenced by any environment

### Build Environment Management

- `pap build setup [ENV_NAME]` - Setup build environment for specified environment
- `pap build clean [ENV_NAME]` - Delete specified build environment
- `pap build list` - Display list of constructed build environments

### Patch Management

- `pap patch export [ENV_NAME]` - Export changes from build environment to patch directory
- `pap patch apply [ENV_NAME]` - Apply patches to build environment
- `pap patch diff [ENV_NAME]` - Display differences between working changes and stored patches

### R2P2-ESP32 Task Delegation

- `pap flash [ENV_NAME]` - Flash firmware to ESP32 (delegates to R2P2-ESP32)
- `pap monitor [ENV_NAME]` - Monitor ESP32 serial output (delegates to R2P2-ESP32)

### Other

- `pap version` or `pap -v` - Show pap version

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

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake test` to run the tests.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).