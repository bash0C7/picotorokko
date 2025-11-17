# PicoRuby Project Initialization Guide

This guide walks you through initializing a new PicoRuby ESP32 project using the `ptrk init` command.

## Table of Contents

- [Quick Start](#quick-start)
- [Basic Initialization](#basic-initialization)
- [Option: Add GitHub Actions CI/CD](#option-add-github-actions-cicd)
- [Combining Options](#combining-options)
- [Project Structure](#project-structure)
- [Next Steps](#next-steps)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

The fastest way to get started:

```bash
ptrk init my-picoruby-app
cd my-picoruby-app
```

This creates a complete project structure ready for development.

---

## Basic Initialization

### Create a New Project

```bash
ptrk init my-project
cd my-project
```

This initializes a PicoRuby project with:
- **Directory structure**: `storage/home/`, `patch/`, `ptrk_env/`
- **Configuration files**: `.picoruby-env.yml`, `.gitignore`, `Gemfile`, `.rubocop.yml`, `Mrbgemfile`
- **Documentation**: `README.md`, `CLAUDE.md` (comprehensive PicoRuby development guide)
- **Sample code**: `storage/home/app.rb`

### Create in Current Directory

If you've already created a directory:

```bash
mkdir my-project
cd my-project
ptrk init
```

The project name will be detected from the directory name.

### Create in a Custom Location

```bash
ptrk init my-project --path ~/my-projects/
```

Creates the project in `~/my-projects/my-project/`.

### Set Author Name

```bash
ptrk init my-project --author "Alice Developer"
```

The author name will be embedded in generated files. If not specified, it's auto-detected from `git config user.name`.

---

## Option: Add GitHub Actions CI/CD

Include a GitHub Actions workflow for automated firmware builds:

```bash
ptrk init my-project --with-ci
cd my-project
```

This creates:
- `.github/workflows/esp32-build.yml` — Automated build workflow
- Ready to push to GitHub and enable CI/CD

**What the workflow does**:
1. Runs on: push to main/develop, pull requests, manual trigger
2. Sets up ESP-IDF toolchain
3. Installs PicoRuby dependencies
4. Builds firmware
5. Saves firmware binaries as downloadable artifacts

**Next: Configure your environment**

After initialization, set your build environment:

```bash
ptrk env set production --commit abc1234
git add ptrk_env/
git commit -m "Add build environment configuration"
git push origin main
```

---

## Combining Options

You can combine multiple options:

```bash
ptrk init my-project \
  --author "Alice" \
  --with-ci \
  --path ~/projects/
```

This creates a complete, ready-to-deploy project with:
- CI/CD workflow configured
- Author name set
- Located in `~/projects/my-project/`

---

## Project Structure

After initialization, your project will look like:

```
my-project/
│
├── storage/home/                      # Your application code
│   ├── app.rb                        # Entry point (auto-included)
│   └── .gitkeep
│
├── patch/                             # Git-managed customizations
│   ├── README.md                     # Patch documentation
│   ├── R2P2-ESP32/                  # Changes to R2P2-ESP32
│   ├── picoruby-esp32/              # Changes to picoruby-esp32
│   └── picoruby/                    # Changes to picoruby
│
├── .github/workflows/                # CI/CD (if --with-ci)
│   └── esp32-build.yml
│
├── ptrk_env/                         # Environment metadata (git-ignored)
│   └── .gitkeep
│
├── .cache/                           # Repository snapshots (git-ignored)
├── build/                            # Build artifacts (git-ignored)
│
├── .picoruby-env.yml                 # Environment definitions (initially empty)
├── .gitignore                        # Excludes .cache/, build/, ptrk_env/*/
├── .rubocop.yml                      # PicoRuby-specific linting configuration
├── Gemfile                           # Includes picotorokko gem
├── Mrbgemfile                        # mrbgems dependencies and configuration
├── README.md                         # Project overview with ptrk commands
└── CLAUDE.md                         # Comprehensive PicoRuby development guide
```

### Key Directories

**`storage/home/`** — Your application code
- Where you write Ruby code for your ESP32 application
- Auto-included by R2P2-ESP32 build system
- Git-managed for version control

**`patch/`** — Customizations to R2P2-ESP32 and dependencies
- Contains diffs of changes you make to framework code
- Git-managed for reproducible builds
- Applied automatically during `ptrk env latest`

**`.github/workflows/`** — CI/CD configuration (optional, with `--with-ci`)
- GitHub Actions workflow for automated builds
- Runs on push, pull requests, and manual trigger
- Produces downloadable firmware artifacts

**`ptrk_env/`** — Environment metadata (git-ignored)
- Created by `ptrk env set` and `ptrk env latest` commands
- Contains version information, repository paths, timestamps
- Never manually edited

### Key Files

**`.rubocop.yml`** — PicoRuby-specific linting configuration
- Stricter Metrics/MethodLength (max 20) for memory efficiency
- Excludes build directories from linting
- Allows Japanese comments for device development
- Enforces double-quoted strings

**`Mrbgemfile`** — mrbgems dependency declarations
- Declare mrbgems your project depends on
- Supports `core:`, `github:`, `path:`, and `git:` sources
- Pre-configured with picoruby-picotest reference for testing
- Platform-specific conditional gem loading

**`CLAUDE.md`** — Comprehensive PicoRuby development guide
- mrbgems dependency management
- Peripheral APIs (I2C, GPIO, RMT) with code examples
- Memory optimization techniques for microcontroller development
- RuboCop configuration and best practices
- Picotest testing framework with examples

---

## Next Steps

### 1. Fetch Latest Repositories

```bash
# Automatically clone and checkout latest repositories
ptrk env latest
```

This creates a complete build environment in `ptrk_env/latest/` with all necessary repositories.

Alternatively, define a specific version:

```bash
ptrk env set main --commit abc1234
```

See [SPEC.md](../SPEC.md) for detailed environment management.

### 2. Write Your Application Code

```bash
# Edit your application
vim storage/home/app.rb
```

Review the auto-generated `CLAUDE.md` for PicoRuby development guides:
```bash
cat CLAUDE.md  # Contains mrbgems, API, memory optimization guides
```

### 3. Build Firmware

```bash
ptrk device build
```

This delegates to R2P2-ESP32's Rakefile to compile your firmware.

### 4. Flash to Device

```bash
ptrk device flash
```

Flashes the compiled firmware to your ESP32 device.

### 5. Monitor Serial Output

```bash
ptrk device monitor
```

View real-time output from your device. Press `Ctrl+C` to exit.

### 6. Commit and Push

```bash
git add .
git commit -m "Initial PicoRuby project setup"
git push origin main
```

---

## Troubleshooting

### Project name validation fails

**Error**: `Invalid project name: my-project! Use alphanumeric characters, dashes, and underscores.`

**Solution**: Use only alphanumeric characters, dashes, and underscores:
```bash
ptrk init my-project         # ✓ OK
ptrk init my_project         # ✓ OK
ptrk init MyProject          # ✓ OK
ptrk init my-project-v1      # ✓ OK
ptrk init my-project!        # ✗ Invalid
ptrk init my.project         # ✗ Invalid
```

### Author name not auto-detected

**Issue**: You didn't specify `--author` and git config is not set.

**Solution**: Either set git config or specify author explicitly:
```bash
# Option 1: Set git config
git config user.name "Your Name"
ptrk init my-project

# Option 2: Specify author directly
ptrk init my-project --author "Your Name"
```

### Path doesn't exist

**Error**: `No such file or directory @ dir_initialize`

**Solution**: Create the parent directory first:
```bash
mkdir -p ~/my-projects/
ptrk init my-project --path ~/my-projects/
```

### GitHub Actions workflow fails

**Issue**: Build fails in CI/CD.

**Troubleshooting steps**:
1. Check the Actions tab in your GitHub repository
2. Click the failed workflow run for detailed logs
3. Common causes:
   - Environment not defined: Run `ptrk env set main --commit <hash>` and commit `ptrk_env/`
   - Latest environment not set: Run `ptrk env latest` and commit `ptrk_env/`
   - Patches not applying: Check `patch/` directory has correct structure

---

## More Information

- **SPEC.md** — Complete command reference and configuration details
- **README.md** — picotorokko gem overview
- **CI_CD_GUIDE.md** — GitHub Actions integration guide
- **R2P2-ESP32** — https://github.com/picoruby/R2P2-ESP32
- **PicoRuby** — https://github.com/picoruby/picoruby
