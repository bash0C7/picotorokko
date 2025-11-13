# PicoRuby Project Initialization Guide

This guide walks you through initializing a new PicoRuby ESP32 project using the `ptrk init` command.

## Table of Contents

- [Quick Start](#quick-start)
- [Basic Initialization](#basic-initialization)
- [Option: Add GitHub Actions CI/CD](#option-add-github-actions-cicd)
- [Option: Generate mrbgems](#option-generate-mrbgems)
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
- **Configuration files**: `.picoruby-env.yml`, `.gitignore`, `Gemfile`
- **Documentation**: `README.md`, `CLAUDE.md`
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

## Option: Generate mrbgems

Include custom mrbgem templates for C extensions:

```bash
ptrk init my-project --with-mrbgem Motor
cd my-project
```

This creates:
```
mrbgems/Motor/
├── mrbgem.rake       # Build configuration
├── mrblib/motor.rb   # Ruby interface
├── src/motor.c       # C extension
└── README.md         # Documentation
```

**Generate multiple mrbgems**:

```bash
ptrk init my-project --with-mrbgem Motor --with-mrbgem Sensor --with-mrbgem LED
```

Creates three mrbgems ready for customization.

**What's in each mrbgem**:
- `mrbgem.rake` — Defines how to compile and link the gem
- `mrblib/{name}.rb` — Ruby interface code
- `src/{name}.c` — C extension implementing native functionality
- `README.md` — Documentation template

**Next: Edit the C extension**

```bash
# Edit Motor's C code
vim mrbgems/Motor/src/motor.c

# Edit Motor's Ruby interface
vim mrbgems/Motor/mrblib/motor.rb

# The mrbgem will be compiled with your firmware
ptrk build setup
cd build/current/R2P2-ESP32
rake build
```

---

## Combining Options

You can combine multiple options:

```bash
ptrk init my-project \
  --author "Alice" \
  --with-ci \
  --with-mrbgem Motor \
  --with-mrbgem Sensor \
  --path ~/projects/
```

This creates a complete, ready-to-deploy project with:
- CI/CD workflow configured
- Multiple mrbgems scaffolded
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
├── mrbgems/                          # Custom C extensions (if --with-mrbgem)
│   └── Motor/
│       ├── mrbgem.rake
│       ├── mrblib/motor.rb
│       ├── src/motor.c
│       └── README.md
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
├── Gemfile                           # Includes picotorokko gem
├── README.md                         # Project overview
└── CLAUDE.md                         # Development guide
```

### Key Directories

**`storage/home/`** — Your application code
- Where you write Ruby code for your ESP32 application
- Auto-included by R2P2-ESP32 build system
- Git-managed for version control

**`patch/`** — Customizations to R2P2-ESP32 and dependencies
- Contains diffs of changes you make to framework code
- Git-managed for reproducible builds
- Applied automatically during `ptrk build setup`

**`mrbgems/`** — Custom C extensions (optional, with `--with-mrbgem`)
- Each gem is a complete module with Ruby and C code
- Compiled and linked into your firmware
- Enables hardware-specific functionality

**`.github/workflows/`** — CI/CD configuration (optional, with `--with-ci`)
- GitHub Actions workflow for automated builds
- Runs on push, pull requests, and manual trigger
- Produces downloadable firmware artifacts

**`ptrk_env/`** — Environment metadata (git-ignored)
- Created by `ptrk env set` commands
- Contains version information, timestamps
- Never manually edited

---

## Next Steps

### 1. Set Up Your Build Environment

```bash
# Define which versions of R2P2-ESP32, picoruby-esp32, picoruby to use
ptrk env set main --commit abc1234
```

See [SPEC.md](../SPEC.md) for detailed environment management.

### 2. Initialize Build Directory

```bash
ptrk build setup main
```

This creates a working copy of all repositories in `build/current/R2P2-ESP32/`.

### 3. Write Your Application Code

```bash
# Edit your application
vim storage/home/app.rb
```

### 4. Build Firmware

```bash
cd build/current/R2P2-ESP32
rake build
cd ../../..
```

### 5. Flash to Device

```bash
# You'll need esptool.py installed
# The R2P2-ESP32 Rakefile handles this
cd build/current/R2P2-ESP32
rake flash
cd ../../..
```

### 6. Monitor Serial Output

```bash
cd build/current/R2P2-ESP32
rake monitor
cd ../../..

# Press Ctrl+C to exit
```

### 7. Commit and Push

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
   - Patches not applying: Check `patch/` directory has correct structure
   - mrbgem compilation error: Check `mrbgems/{name}/src/{name}.c` syntax

### mrbgem doesn't compile

**Issue**: C code won't compile when building firmware.

**Solution**:
1. Check for syntax errors in `src/{name}.c`
2. Verify `mrbgem.rake` paths are correct
3. Check R2P2-ESP32 documentation for API usage
4. Run build locally first to see errors:
   ```bash
   cd build/current/R2P2-ESP32
   rake build 2>&1 | grep -A5 "error:"
   ```

---

## More Information

- **SPEC.md** — Complete command reference and configuration details
- **README.md** — picotorokko gem overview
- **CI_CD_GUIDE.md** — GitHub Actions integration guide
- **R2P2-ESP32** — https://github.com/picoruby/R2P2-ESP32
- **PicoRuby** — https://github.com/picoruby/picoruby
