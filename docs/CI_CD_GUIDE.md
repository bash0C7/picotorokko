# CI/CD Integration Guide

This guide explains how to set up continuous integration and deployment for PicoRuby ESP32 applications using the `pra` gem.

## Terminology

Before proceeding, understand these key terms used throughout this guide:

- **Environment Definition**: Metadata in `.picoruby-env.yml` that specifies commit hashes and timestamps for R2P2-ESP32, picoruby-esp32, and picoruby repositories.
- **Build Environment**: A working directory (`build/`) containing actual repository files used for building firmware.
- **Cache**: Immutable repository copies stored in `.cache/` directory.

**Typical Workflow**: Define environment → Fetch to cache → Setup build environment → Build firmware

For more details, see the [Terminology section in README.md](../README.md#terminology).

## Table of Contents

- [For PicoRuby Application Developers](#for-picoruby-application-developers)
  - [GitHub Actions Setup](#github-actions-setup)
  - [Understanding the Build Process](#understanding-the-build-process)
  - [Downloading and Flashing Artifacts](#downloading-and-flashing-artifacts)
  - [Customization Options](#customization-options)
- [For Gem Developers](#for-gem-developers)
  - [Testing Workflow](#testing-workflow)
  - [Release Workflow](#release-workflow)
- [Troubleshooting](#troubleshooting)

---

## For PicoRuby Application Developers

### GitHub Actions Setup

If you're building a PicoRuby application for ESP32, you can automate the firmware build process using GitHub Actions.

**Recommended**: If you have the `pra` gem installed, use the `ptrk ci setup` command to automatically copy the workflow template:

```bash
ptrk ci setup
```

This will create `.github/workflows/esp32-build.yml` from the latest template.

#### Step 1: Copy the Example Workflow (Manual Method)

```bash
# In your PicoRuby application repository
mkdir -p .github/workflows
cp node_modules/pra/docs/github-actions/esp32-build.yml .github/workflows/

# Or download directly from GitHub
curl -o .github/workflows/esp32-build.yml \
  https://raw.githubusercontent.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/main/docs/github-actions/esp32-build.yml
```

#### Step 2: Define Your Environment

Edit `.picoruby-env.yml` in your project root to define your R2P2-ESP32 environment definition:

```yaml
environments:
  stable-2024-11:
    R2P2-ESP32:
      commit: "f500652"
      timestamp: "20241105_143022"
    picoruby-esp32:
      commit: "def456..."
      timestamp: "20241105_143022"
    picoruby:
      commit: "ghi789..."
      timestamp: "20241105_143022"
```

#### Step 3: Customize the Workflow (Optional)

Edit `.github/workflows/esp32-build.yml` to customize:

```yaml
# Change ESP-IDF version
- name: Setup ESP-IDF environment
  uses: espressif/esp-idf-ci-action@v1
  with:
    esp_idf_version: v5.1  # Change to v5.2, v5.3, etc.
    target: esp32           # Or esp32s2, esp32s3, esp32c3

# Change environment definition name
- name: Fetch PicoRuby repositories to cache
  run: |
    ptrk cache fetch stable-2024-11  # Change to your environment definition name
```

#### Step 4: Commit and Push

```bash
git add .github/workflows/esp32-build.yml .picoruby-env.yml
git commit -m "Add CI/CD workflow for ESP32 firmware builds"
git push origin main
```

The workflow will automatically run on:
- Push to `main` or `develop` branches
- Pull requests
- Manual trigger via GitHub Actions UI

#### Updating Workflow Template

When `pra` gem is updated with workflow improvements:

```bash
gem update pra
ptrk ci setup --force  # Overwrite with latest template
git diff .github/workflows/esp32-build.yml  # Review changes
# Salvage any custom changes you need
```

**Note**: The `--force` option will be available in a future version of `pra`. It allows you to refresh the workflow template while preserving your ability to review and restore custom changes via `git diff`.

### Understanding the Build Process

The automated build workflow performs these steps:

1. **Checkout**: Clones your repository with submodules
2. **Ruby Setup**: Installs Ruby 3.4 and dependencies
3. **Install pra**: Installs the ptrk gem globally
4. **ESP-IDF Setup**: Configures ESP-IDF toolchain via espressif action
5. **Cache Fetch**: Downloads R2P2-ESP32 repositories to cache using `ptrk cache fetch`
6. **Build Environment Setup**: Runs `ptrk build setup` to create build environment from cache
7. **Apply Patches**: Applies any custom patches from `patch/` directory
8. **Firmware Build**: Builds ESP32 firmware using `idf.py build`
9. **Upload Artifacts**: Saves firmware binaries as downloadable artifacts

### Downloading and Flashing Artifacts

#### Download from GitHub Actions

1. Go to **Actions** tab in your repository
2. Click on the completed workflow run
3. Scroll down to **Artifacts** section
4. Download `esp32-firmware.zip`
5. Extract the archive

#### Flash to ESP32

**Option 1: Using esptool (Manual)**

```bash
# Unzip the artifacts
unzip esp32-firmware.zip

# Flash to ESP32
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 460800 write_flash \
  0x1000 bootloader/bootloader.bin \
  0x8000 partition_table/partition-table.bin \
  0x10000 your-app-name.bin
```

**Option 2: Using ptrk (Recommended)**

If you have the `pra` gem installed locally:

```bash
# Ensure you're using the same environment definition
bundle exec ptrk cache fetch stable-2024-11
bundle exec ptrk build setup

# Copy downloaded artifacts to build directory
cp downloaded-artifacts/*.bin .cache/*/r2p2-esp32/build/

# Flash using pra
bundle exec ptrk device flash
```

### Customization Options

#### Add Custom Build Steps

Edit your workflow to add custom build commands:

```yaml
- name: Build firmware
  run: |
    cd .cache/*/r2p2-esp32

    # Set custom build options
    idf.py menuconfig  # Configure interactively (won't work in CI)

    # Or set via sdkconfig
    echo "CONFIG_MY_OPTION=y" >> sdkconfig

    # Build with custom target
    idf.py build
```

#### Enable Ruby Unit Tests

Uncomment the `test` job in the workflow:

```yaml
test:
  runs-on: ubuntu-latest
  if: true  # Change from 'false' to 'true'
```

#### Add Release Automation

Extend the workflow to create releases on tags:

```yaml
on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      # ... build steps ...

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            .cache/*/r2p2-esp32/build/bootloader/bootloader.bin
            .cache/*/r2p2-esp32/build/partition_table/partition-table.bin
            .cache/*/r2p2-esp32/build/*.bin
```

---

## For Gem Developers

### Testing Workflow

The `pra` gem uses GitHub Actions for continuous testing across multiple Ruby versions.

**Workflow**: `.github/workflows/main.yml`

**Features**:
- Matrix testing: Ruby 3.1, 3.2, 3.3, 3.4
- SimpleCov coverage tracking (90% threshold)
- Codecov integration for coverage reports
- Fails if any Ruby version breaks or coverage drops

**Running locally**:
```bash
bundle exec rake test
open coverage/index.html  # View coverage report
```

### Release Workflow

Releases are managed through a manual GitHub Actions workflow.

**Workflow**: `.github/workflows/release.yml`

#### Prerequisites

1. **Maintainer Access**: You must have write access to the repository
2. **RubyGems API Key**:
   - Generate from https://rubygems.org/profile/api_keys
   - Add as `RUBYGEMS_API_KEY` in repository secrets

#### Creating a Release

1. Navigate to **Actions** → **Release** in GitHub
2. Click **Run workflow**
3. Enter version number (e.g., `0.2.0`)
4. Check **dry_run** for testing (recommended)
5. Click **Run workflow**

**Dry Run Output**:
```
✓ Version validation passed
✓ Tests passed
✓ Gem built successfully
ℹ Dry run - no changes were published
```

If everything looks good, run again without dry run.

**What the workflow does**:
1. Validates version format (X.Y.Z)
2. Updates `lib/pra/version.rb`
3. Runs full test suite
4. Builds gem (`pra-X.Y.Z.gem`)
5. Commits version bump to `main`
6. Creates Git tag `vX.Y.Z`
7. Publishes to RubyGems.org
8. Creates GitHub Release with auto-generated notes

#### Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (0.2.0): New features (backwards compatible)
- **PATCH** (0.1.1): Bug fixes (backwards compatible)

---

## Troubleshooting

### Common Issues

#### "Environment definition not found"

**Problem**: Workflow fails at `ptrk cache fetch` step with "Environment definition not found in .picoruby-env.yml"

**Solution**:
1. Verify `.picoruby-env.yml` exists and is valid
2. Check environment definition name matches in workflow
3. Ensure commit hashes are correct

```bash
# Locally test cache fetch
bundle exec ptrk cache fetch your-environment-definition-name
```

#### "ESP-IDF not found"

**Problem**: `idf.py` command not found

**Solution**:
- Ensure `espressif/esp-idf-ci-action@v1` step is present
- Check ESP-IDF version is supported (v5.1+)

#### "Artifacts not uploaded"

**Problem**: No artifacts appear after successful build

**Solution**:
- Check artifact paths in workflow match your build output
- Use wildcard patterns: `.cache/*/r2p2-esp32/build/*.bin`

#### "Flash fails with downloaded artifacts"

**Problem**: `esptool.py` errors when flashing

**Solution**:
1. Verify correct COM port: `/dev/ttyUSB0`, `/dev/ttyACM0`, or `COM3` (Windows)
2. Check chip type matches: `--chip esp32`
3. Ensure proper file offsets:
   - `0x1000` → bootloader.bin
   - `0x8000` → partition-table.bin
   - `0x10000` → app.bin

#### "Coverage reports not appearing"

**Problem**: Codecov badge shows "unknown"

**Solution**:
1. Add `CODECOV_TOKEN` to GitHub repository secrets
2. Ensure SimpleCov runs during tests
3. Check `coverage/coverage.xml` is generated

### Getting Help

- **Gem Issues**: https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/issues
- **PicoRuby**: https://github.com/picoruby/picoruby
- **R2P2-ESP32**: https://github.com/picoruby/r2p2-esp32

---

## Best Practices

### For Application Developers

1. **Pin Environment Definition Versions**: Use specific commit hashes in `.picoruby-env.yml`
2. **Test Locally First**: Run `ptrk build setup && rake build` before pushing
3. **Use Artifacts Expiry**: Set reasonable retention days (30-90)
4. **Enable Branch Protection**: Require status checks and prevent force pushes
5. **Document Flash Process**: Add flash instructions to your README

### For Gem Developers

1. **Keep Coverage High**: Maintain 90%+ coverage
2. **Test All Ruby Versions**: Don't skip matrix testing
3. **Use Dry Run**: Always test releases with dry run first
4. **Write Changelog**: Update CHANGELOG.md before releasing
5. **Semantic Versioning**: Follow semver strictly

---

## Advanced Topics

### Caching Dependencies

Speed up builds by caching Ruby gems and ESP-IDF tools:

```yaml
- name: Cache ESP-IDF
  uses: actions/cache@v4
  with:
    path: ~/.espressif
    key: esp-idf-${{ hashFiles('**/sdkconfig') }}
    restore-keys: |
      esp-idf-
```

### Matrix Testing for Multiple ESP32 Targets

```yaml
strategy:
  matrix:
    target: [esp32, esp32s2, esp32s3, esp32c3]

steps:
  - name: Setup ESP-IDF
    uses: espressif/esp-idf-ci-action@v1
    with:
      target: ${{ matrix.target }}
```

### Automated Firmware Releases

Create releases automatically on version tags:

```yaml
on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  release:
    steps:
      # ... build steps ...
      - uses: softprops/action-gh-release@v1
        with:
          files: build/*.bin
          generate_release_notes: true
```
