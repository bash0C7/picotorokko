# CI/CD Integration Guide

This guide explains how to set up continuous integration and deployment for PicoRuby ESP32 applications using the `ptrk` gem.

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

#### Option A: Use `ptrk init --with-ci` (Recommended)

The easiest way to set up CI/CD is to include the GitHub Actions workflow when initializing your project:

```bash
ptrk init my-project --with-ci
cd my-project
```

This automatically creates `.github/workflows/esp32-build.yml` in your project with the pre-configured workflow template.

#### Option B: Copy Workflow Templates Manually

If you already have a project, you can copy workflow templates manually:

```bash
# In your existing PicoRuby application repository
mkdir -p .github/workflows

# Copy specific workflows from picotorokko gem installation
# Main build workflow (required)
cp $(bundle show picotorokko)/docs/github-actions/esp32-build.yml .github/workflows/

# Optional workflows
cp $(bundle show picotorokko)/docs/github-actions/run-tests.yml .github/workflows/
cp $(bundle show picotorokko)/docs/github-actions/code-quality.yml .github/workflows/
cp $(bundle show picotorokko)/docs/github-actions/release-firmware.yml .github/workflows/
cp $(bundle show picotorokko)/docs/github-actions/multi-target-build.yml .github/workflows/
cp $(bundle show picotorokko)/docs/github-actions/deployment.yml .github/workflows/

# Or download directly from GitHub
curl -o .github/workflows/esp32-build.yml \
  https://raw.githubusercontent.com/bash0C7/picotorokko/main/docs/github-actions/esp32-build.yml
```

**Available Workflows**:
| Workflow | Purpose | Status |
|----------|---------|--------|
| `esp32-build.yml` | Build ESP32 firmware | Essential |
| `run-tests.yml` | Run Ruby unit tests | Optional |
| `code-quality.yml` | RuboCop linting & type checking | Optional |
| `release-firmware.yml` | Auto-release on git tags | Optional |
| `multi-target-build.yml` | Build for multiple ESP32 chips | Advanced |
| `deployment.yml` | Firmware deployment patterns | Advanced |

**Note**: For new projects, **Option A** (`ptrk init --with-ci`) is simpler and handles all setup automatically.

#### Step 1: Define Your Environment

Use `ptrk env set` to create your build environment:

```bash
# Create environment with specific commit (if needed)
ptrk env set production --commit f500652

# Or use latest commits
ptrk env set development
```

This creates an entry in `ptrk_env/.picoruby-env.yml` that GitHub Actions will use.

#### Step 2: Customize the Workflow (Optional)

Edit `.github/workflows/esp32-build.yml` to customize:

```yaml
# Change ESP-IDF version
- name: Setup ESP-IDF environment
  uses: espressif/esp-idf-ci-action@v1
  with:
    esp_idf_version: v5.1  # Change to v5.2, v5.3, etc.
    target: esp32           # Or esp32s2, esp32s3, esp32c3

# Change environment name
- name: Setup build environment
  run: |
    ptrk env set production  # Change to your environment name
```

#### Step 3: Commit and Push

```bash
git add .github/workflows/esp32-build.yml ptrk_env/.picoruby-env.yml
git commit -m "Add CI/CD workflow for ESP32 firmware builds"
git push origin main
```

The workflow will automatically run on:
- Push to `main` or `develop` branches
- Pull requests
- Manual trigger via GitHub Actions UI

### Understanding the Build Process

The automated build workflow performs these steps:

1. **Checkout**: Clones your repository with submodules
2. **Ruby Setup**: Installs Ruby 3.4 and dependencies
3. **Install ptrk**: Installs the picotorokko gem
4. **ESP-IDF Setup**: Configures ESP-IDF toolchain via espressif action
5. **Environment Setup**: Runs `ptrk env set` to create build environment in `ptrk_env/`
6. **Apply Patches**: Applies any custom patches from `patch/` directory
7. **Firmware Build**: Builds ESP32 firmware using R2P2-ESP32's Rakefile
8. **Upload Artifacts**: Saves firmware binaries as downloadable artifacts

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

If you have the `ptrk` gem installed locally:

```bash
# Ensure you're using the same environment
bundle exec ptrk env set production

# Build locally (or copy downloaded artifacts)
bundle exec ptrk device build

# Flash using ptrk
bundle exec ptrk device flash
```

### Customization Options

#### Add Custom Build Steps

Edit your workflow to add custom build commands:

```yaml
- name: Build firmware
  run: |
    cd ptrk_env/production/R2P2-ESP32

    # Set custom build options
    echo "CONFIG_MY_OPTION=y" >> sdkconfig

    # Build with R2P2-ESP32 Rakefile
    bundle exec rake build
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
            ptrk_env/*/R2P2-ESP32/build/bootloader/bootloader.bin
            ptrk_env/*/R2P2-ESP32/build/partition_table/partition-table.bin
            ptrk_env/*/R2P2-ESP32/build/*.bin
```

---

## For Gem Developers

### Testing Workflow

The `picotorokko` gem uses GitHub Actions for continuous testing across multiple Ruby versions.

**Workflow**: `.github/workflows/main.yml`

**Features**:
- Matrix testing: Ruby 3.1, 3.2, 3.3, 3.4
- SimpleCov coverage tracking (≥85% line, ≥60% branch)
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
2. Updates `lib/picotorokko/version.rb`
3. Runs full test suite
4. Builds gem (`picotorokko-X.Y.Z.gem`)
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

#### "Environment not found"

**Problem**: Workflow fails at `ptrk env set` step

**Solution**:
1. Verify `ptrk_env/.picoruby-env.yml` exists in your repository
2. Check environment name matches in workflow
3. Ensure you've committed the file:

```bash
git add ptrk_env/.picoruby-env.yml
git commit -m "Add environment configuration"
git push
```

#### "ESP-IDF not found"

**Problem**: `idf.py` command not found

**Solution**:
- Ensure `espressif/esp-idf-ci-action@v1` step is present in workflow
- Check ESP-IDF version is supported (v5.1+)

#### "Artifacts not uploaded"

**Problem**: No artifacts appear after successful build

**Solution**:
- Check artifact paths in workflow match your build output
- Use correct paths: `ptrk_env/*/R2P2-ESP32/build/*.bin`
- Verify build actually succeeded

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

- **Gem Issues**: https://github.com/bash0C7/picotorokko/issues
- **PicoRuby**: https://github.com/picoruby/picoruby
- **R2P2-ESP32**: https://github.com/picoruby/R2P2-ESP32

---

## Best Practices

### For Application Developers

1. **Use Explicit Environment Names**: Always specify environment names in workflows
2. **Test Locally First**: Run `ptrk env set && ptrk device build` before pushing
3. **Use Artifacts Expiry**: Set reasonable retention days (30-90)
4. **Enable Branch Protection**: Require status checks and prevent force pushes
5. **Document Flash Process**: Add flash instructions to your README

### For Gem Developers

1. **Keep Coverage High**: Maintain ≥85% line coverage
2. **Test All Ruby Versions**: Don't skip matrix testing
3. **Use Dry Run**: Always test releases with dry run first
4. **Write Changelog**: Update CHANGELOG.md before releasing
5. **Semantic Versioning**: Follow semver strictly

---

## Workflow Templates Guide

### Overview of All Available Workflows

The `picotorokko` gem provides 6 pre-configured GitHub Actions workflow templates for PicoRuby applications:

#### 1. ESP32 Firmware Build (`esp32-build.yml`) - Essential

**Purpose**: Core workflow that builds ESP32 firmware for your PicoRuby application.

**Triggers**:
- Push to `main` or `develop` branches
- Pull requests
- Manual trigger via GitHub Actions UI

**What it does**:
1. Checks out repository with submodules
2. Sets up Ruby 3.4 environment
3. Installs picotorokko gem
4. Configures ESP-IDF toolchain
5. Creates PicoRuby environment via `ptrk env set`
6. Builds firmware using `ptrk device build`
7. Uploads firmware artifacts for 30 days
8. Generates flash instructions

**Artifacts**: `esp32-firmware/` containing `.bin` and `.elf` files

---

#### 2. Run Tests (`run-tests.yml`) - Optional

**Purpose**: Automatically run Ruby unit tests on every push and pull request.

**Triggers**:
- Push to `main` or `develop`
- Pull requests
- Manual trigger

**What it does**:
1. Runs tests against multiple Ruby versions (3.3, 3.4)
2. Uploads coverage reports to Codecov
3. Comments on PRs if tests fail
4. Generates coverage reports

**Prerequisites**:
- `test/` directory with `.rb` test files
- Rakefile with `rake test` task
- (Optional) `CODECOV_TOKEN` in repository secrets

**Use this if**: You have Ruby code or tests in your project

---

#### 3. Code Quality (`code-quality.yml`) - Optional

**Purpose**: Validates code style, runs RuboCop linting, and optional type checking with Steep.

**Triggers**:
- Push to `main` or `develop`
- Pull requests
- Manual trigger

**What it does**:
1. Runs RuboCop in parallel for code style
2. (Optional) Runs Steep for static type checking
3. Checks for common style issues (trailing whitespace, etc.)
4. Comments on PRs with violations
5. Suggests automatic fixes

**Prerequisites**:
- `.rubocop.yml` (generated by `ptrk init`)
- (Optional) `Gemfile` with `steep` gem for type checking

**Use this if**: You want to enforce code style standards

---

#### 4. Release Firmware (`release-firmware.yml`) - Optional

**Purpose**: Automatically build and release firmware when you create a semantic version tag.

**Triggers**:
- Push of git tags matching `v*.*.*` (e.g., `v1.0.0`)
- Manual trigger with tag name

**What it does**:
1. Builds firmware for the released version
2. Creates GitHub Release with auto-generated notes
3. Uploads firmware artifacts as release assets
4. Preserves release for downloading

**Usage**:
```bash
git tag v1.0.0
git push origin v1.0.0
```

**Artifacts**: Available in GitHub Releases page

**Use this if**: You want to automate firmware releases for your users

---

#### 5. Multi-Target Build (`multi-target-build.yml`) - Advanced

**Purpose**: Build firmware for multiple ESP32 chip variants in parallel.

**Triggers**:
- Push to `main`
- Manual trigger

**What it does**:
1. Matrix build for multiple targets (esp32, esp32s3, esp32c3, esp32s2)
2. Builds in parallel for speed
3. Creates separate artifacts per target
4. Combines all artifacts for download

**Configuration**: Uncomment targets in the `strategy.matrix.target` section

**Prerequisites**:
- Firmware compatible with multiple ESP32 variants
- (Optional) Separate environment per target

**Use this if**: Your firmware supports multiple ESP32 chips

---

#### 6. Firmware Deployment (`deployment.yml`) - Advanced

**Purpose**: Demonstrates firmware deployment patterns and artifact handling.

**Triggers**:
- When another workflow completes
- Manual trigger with deployment inputs
- Environment selection (staging/production)

**What it does**:
1. Downloads firmware artifacts
2. Verifies firmware integrity
3. Creates deployment manifest
4. Demonstrates staging and production deployment patterns
5. Supports approval gates for production

**Prerequisites**:
- Completed build from another workflow
- (Optional) Environment-based approvals

**Use this if**: You need deployment automation or have multiple deployment targets

---

### Workflow Selection Guide

**Minimal Setup** (Just build firmware):
```
✓ esp32-build.yml
```

**With Testing** (Build + test Ruby code):
```
✓ esp32-build.yml
✓ run-tests.yml
```

**Full Development** (Build + test + quality checks):
```
✓ esp32-build.yml
✓ run-tests.yml
✓ code-quality.yml
```

**With Releases** (Add automatic releases):
```
✓ esp32-build.yml
✓ run-tests.yml
✓ code-quality.yml
✓ release-firmware.yml
```

**Multi-Chip Support** (Build for multiple targets):
```
✓ esp32-build.yml
✓ multi-target-build.yml  (instead of esp32-build for multi-target)
✓ release-firmware.yml
```

**Production Deployment**:
```
✓ esp32-build.yml
✓ run-tests.yml
✓ code-quality.yml
✓ release-firmware.yml
✓ deployment.yml
```

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
          files: ptrk_env/*/R2P2-ESP32/build/*.bin
          generate_release_notes: true
```
