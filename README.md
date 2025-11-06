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
bundle exec pra flash
bundle exec pra monitor
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

## CI/CD Integration

### For PicoRuby Application Developers

If you're developing a PicoRuby application for ESP32, you can automate firmware builds using GitHub Actions.

**Quick Setup:**

1. Copy the example workflow to your project:
   ```bash
   mkdir -p .github/workflows
   cp docs/github-actions/esp32-build.yml .github/workflows/
   ```

2. Customize the workflow for your environment (edit `.github/workflows/esp32-build.yml`):
   - Set your target ESP-IDF version
   - Configure environment name from your `.picoruby-env.yml`
   - Adjust build steps as needed

3. Commit and push to trigger the build

**Flash Downloaded Artifacts:**

After the workflow completes, download the firmware artifacts and flash:

```bash
# Using esptool directly
esptool.py --chip esp32 --port /dev/ttyUSB0 write_flash \
  0x1000 bootloader.bin \
  0x8000 partition-table.bin \
  0x10000 app.bin

# Or using pra command (recommended)
bundle exec pra r2p2 flash --port /dev/ttyUSB0
```

For detailed CI/CD setup instructions, see [docs/CI_CD_GUIDE.md](docs/CI_CD_GUIDE.md).

### For Gem Developers

This repository uses automated CI/CD for testing and releases:

- **Continuous Testing**: Ruby 3.1, 3.2, 3.3, 3.4 matrix testing on every push/PR
- **Coverage Reports**: Automated coverage tracking with 90% threshold via Codecov
- **Manual Releases**: Workflow-based releases to RubyGems.org

See [CONTRIBUTING.md](CONTRIBUTING.md) for the release process.

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
