# PicoRuby ESP32 Multi-Version Build System Specification

## Overview

A build system for ESP32 + PicoRuby development that manages multiple versions of R2P2-ESP32 and its nested submodules (picoruby-esp32 → picoruby) in parallel, allowing easy switching and validation across versions.

---

## Design Principles

### 1. Immutable Environment Cache

- Repositories saved in `.ptrk_env/` are **never modified**
- Uniquely identified by timestamp (YYYYMMDD_HHMMSS format)
- New cache is always created when versions change
- Old environments can be removed manually when no longer needed

### 2. Build Isolation

- `.ptrk_build/{env_name}/` is a complete working directory for each environment
- Multiple environments can coexist simultaneously
- Built from `.ptrk_env/` source with patches and storage/home applied

### 3. Patch Persistence

- Git-managed changes to R2P2-ESP32 etc. in the `patch/` directory
- Changes in `build/` can be exported back to `patch/`
- Patches are automatically applied when switching environments

### 4. Task Delegation

- New build system focuses on **environment management and file operations**
- Build tasks (build/flash/monitor) are delegated to R2P2-ESP32's Rakefile
- ESP-IDF environment variable setup leverages existing Rakefile mechanisms

---

## Directory Structure

```
Project Root/
│
├── storage/home/           # 🔴 Device application code
│   │                         # Git-managed
│   ├── app.rb
│   └── ...
│
├── mrbgems/                # 🔴 Custom mrbgems
│   │                         # Git-managed
│   └── app/
│       ├── mrbgem.rake
│       └── mrblib/
│
├── patch/                  # 🔴 Patch files
│   │                         # Git-managed
│   ├── README.md
│   ├── R2P2-ESP32/
│   ├── picoruby-esp32/
│   └── picoruby/
│
├── .ptrk_env/              # 🔵 Immutable environment cache
│   │                         # Git-ignored (.gitignore)
│   └── 20251122_103000/      # YYYYMMDD_HHMMSS format
│       ├── R2P2-ESP32/       # Complete git working copy with submodules
│       │   └── components/
│       │       └── picoruby-esp32/
│       │           └── picoruby/
│       └── rubocop/          # Auto-generated RuboCop config
│           └── data/
│
├── .ptrk_build/            # 🟢 Build working directory
│   │                         # Git-ignored (.gitignore)
│   └── 20251122_103000/      # Copied from .ptrk_env with patches applied
│       └── R2P2-ESP32/       # Build execution here
│           ├── components/
│           │   └── picoruby-esp32/
│           │       └── picoruby/
│           ├── storage/home/ # Application code copied here
│           ├── mrbgems/      # Custom mrbgems copied here
│           └── Rakefile
│
├── .picoruby-env.yml       # Environment configuration file
├── .rubocop.yml            # Project RuboCop config (links to current env)
├── Mrbgemfile              # mrbgems dependencies
└── .gitignore              # Excludes .ptrk_env/, .ptrk_build/
```

---

## Naming Conventions

### Environment Name Format

```
YYYYMMDD_HHMMSS

Examples:
  20251122_103000
  20251121_143022
  20251120_120000
```

- Generated from local timestamp: `Time.now.strftime("%Y%m%d_%H%M%S")`
- Unique identifier for each environment
- Pattern validation: `/^\d+_\d+$/`

---

## Configuration File (.picoruby-env.yml)

```yaml
# PicoRuby development environment configuration file
# Each environment is immutable, uniquely identified by YYYYMMDD_HHMMSS timestamp

current: "20251122_103000"

environments:
  "20251122_103000":
    R2P2-ESP32:
      commit: f500652
      timestamp: "20251122_103000"
    picoruby-esp32:
      commit: 6a6da3a
      timestamp: "20251122_102015"
    picoruby:
      commit: e57c370
      timestamp: "20251122_101030"

  "20251121_143022":
    R2P2-ESP32:
      commit: 34a1c23
      timestamp: "20251121_143022"
    picoruby-esp32:
      commit: f331744
      timestamp: "20251121_142500"
    picoruby:
      commit: df21508
      timestamp: "20251121_142000"
```

**Field Descriptions:**

- `current` - Current working environment name (YYYYMMDD_HHMMSS format)
- `environments` - Environment definition map
- Each environment's `R2P2-ESP32/picoruby-esp32/picoruby` - Commit and timestamp

---

## CLI Commands Reference

### 🚀 Project Creation Command

#### `ptrk new [PROJECT_NAME]`

**Description**: Create a new PicoRuby project structure with all necessary directories and configuration files

**Arguments**:
- `PROJECT_NAME` - Name of the project (optional, default: current directory name or `picotorokko-app`)

**Options**:
- `--path PATH` - Create project in specified directory (optional, default: current directory)
- `--author "Name"` - Set author name (optional, auto-detected from git config if available)
- `--with-ci` - Copy GitHub Actions workflow template (optional)
- `--with-mrbgem GEM_NAME` - Initialize with pre-configured mrbgem (optional, can be used multiple times)

**Creates Directory Structure**:
```
<project-root>/
├── storage/home/           # Application code directory (git-managed)
│   ├── main.rb             # Example application (optional template)
│   └── .gitkeep
│
├── patch/                  # Patch files directory (git-managed)
│   ├── README.md           # Patch management guide
│   ├── R2P2-ESP32/
│   ├── picoruby-esp32/
│   └── picoruby/
│
├── .ptrk_env/              # Environment cache (git-ignored)
├── .ptrk_build/            # Build working directory (git-ignored)
│
├── .picoruby-env.yml       # Environment configuration file
├── .gitignore              # Standard gitignore for ptrk projects
├── .rubocop.yml            # PicoRuby-specific linting configuration (auto-generated)
├── Gemfile                 # Ruby dependencies with picotorokko gem
├── README.md               # Project README (customizable template)
├── CLAUDE.md               # PicoRuby development guide (auto-generated)
└── Mrbgemfile              # mrbgems dependencies (auto-generated)
```

**Generated Files**:

1. **`.gitignore`** - Excludes `.ptrk_env/`, `.ptrk_build/` from version control
2. **`.picoruby-env.yml`** - Initial environment configuration (empty, ready for `ptrk env set`)
3. **`.rubocop.yml`** - PicoRuby-specific linting configuration:
   - TargetRubyVersion: 3.3 for microcontroller development
   - Stricter Metrics/MethodLength (20 max) for memory efficiency
   - Excludes .ptrk_env/, .ptrk_build/, patch/, vendor/ from linting
   - Allows Japanese comments for device documentation
4. **`Mrbgemfile`** - mrbgems dependency declarations:
   - Pre-configured with picoruby-picotest reference
   - Platform-specific mrbgem support
   - GitHub repository references
5. **`Gemfile`** - Contains `picotorokko` gem dependency (when available in gems)
6. **`.ptrk_env/.gitkeep`** - Preserves directory in git
7. **`README.md`** - Template-generated with project name and author, includes ptrk command references
8. **`CLAUDE.md`** - Comprehensive PicoRuby development guide including:
   - mrbgems dependency management
   - Peripheral APIs (I2C, GPIO, RMT) with code examples
   - Memory optimization techniques
   - RuboCop configuration guide
   - Picotest testing framework examples
9. **`storage/home/main.rb`** - Example Ruby application (optional, can be customized)
10. **`patch/README.md`** - Guide for patch management workflow

**Operation**:
1. Validate project name (alphanumeric + dashes/underscores)
2. Create all directories under `--path` (default: current directory)
3. Generate template files with ERB engine, passing variables:
   - `project_name` - From argument or directory name
   - `author` - From `--author` option or git config
   - `timestamp` - Current creation time
   - `created_at` - Human-readable creation timestamp
4. If `--with-ci` is specified, copy `docs/github-actions/esp32-build.yml` to `.github/workflows/esp32-build.yml`
5. If `--with-mrbgem` is specified, run `ptrk mrbgems generate GEM_NAME` for each gem
6. Display success message with next steps

**Example Usage**:

```bash
# Basic initialization
ptrk new my-project
# => Creating new PicoRuby project: my-project
#    Creating directories...
#    Generating configuration files...
#    Done! Next steps:
#    1. cd my-project
#    2. ptrk env set main --commit <hash>
#    3. ptrk build setup
#    4. cd build/current/R2P2-ESP32 && rake build

# With custom author and CI setup
ptrk new my-project --author "John Doe" --with-ci
# => Creating new PicoRuby project: my-project
#    Copying GitHub Actions workflow...
#    Done!

# In custom directory with mrbgem
ptrk new my-iot-app --path /projects --with-mrbgem servo --with-mrbgem pwm
# => Creating new PicoRuby project: my-iot-app
#    Initializing mrbgems: servo, pwm
#    Done!

# Inline project creation
mkdir my-app && cd my-app && ptrk new
# => Creating new PicoRuby project: my-app (from current directory)
#    Done!
```

**Success Criteria**:
- All directories created with `.gitkeep` files where needed
- All template files rendered without errors
- `.gitignore` correctly excludes `.ptrk_env/`, `.ptrk_build/`
- `.picoruby-env.yml` contains empty environments map ready for `ptrk env set`
- Project is immediately usable with `ptrk env set --latest` and `ptrk device build`

---

## Project Initialization

### `ptrk new [PROJECT_NAME]`

**Description**: Initialize a new PicoRuby project with complete directory structure, templates, and configuration files

**Arguments**:
- `PROJECT_NAME` (optional) - Name of the project. If omitted, uses current directory name

**Options**:
- `--author "Name"` - Set project author (default: auto-detected from `git config user.name`)
- `--path /dir` - Create project in specified directory instead of current directory
- `--with-ci` - Include GitHub Actions ESP32 build workflow template in `.github/workflows/`
- `--with-mrbgem NAME` - Generate mrbgem template(s). Can be specified multiple times for multiple gems

**Output Directory Structure**:
```
PROJECT_NAME/
├── storage/home/           # Application code location
│   ├── app.rb             # Sample entry point
│   └── .gitkeep
├── patch/                  # Git-managed patch files
│   ├── README.md          # Patch documentation
│   ├── R2P2-ESP32/        # R2P2-ESP32 patches
│   ├── picoruby-esp32/    # picoruby-esp32 patches
│   └── picoruby/          # picoruby patches
├── .ptrk_env/              # Environment cache (git-ignored)
│   └── .gitkeep
├── .ptrk_build/            # Build working directory (git-ignored)
├── mrbgems/               # Custom mrbgems (if --with-mrbgem specified)
│   └── NAME/
│       ├── mrbgem.rake
│       ├── mrblib/
│       │   └── name.rb
│       ├── src/
│       │   └── name.c
│       └── README.md
├── .github/workflows/     # CI/CD workflows (if --with-ci specified)
│   └── esp32-build.yml
├── .picoruby-env.yml      # Environment configuration (initially empty)
├── .gitignore             # Git ignore patterns
├── Gemfile                # Ruby dependencies with picotorokko gem
├── README.md              # Project overview
└── CLAUDE.md              # Development guide for ptrk users
```

**Examples**:

Basic initialization:
```bash
ptrk new my-project
cd my-project
```

With GitHub Actions CI/CD:
```bash
ptrk new my-project --with-ci
```

With multiple mrbgems and author:
```bash
ptrk new my-project --with-mrbgem Sensor --with-mrbgem Motor --author "Alice"
```

Create in specific directory:
```bash
ptrk new --path ~/projects/ my-project
```

Create in current directory (uses current dir name):
```bash
mkdir my-project && cd my-project
ptrk new
```

**Operation**:
1. Validate project name (alphanumeric, dashes, underscores only)
2. Create directory structure with `.gitkeep` files
3. Render template files with project variables:
   - `.picoruby-env.yml` - Empty YAML structure ready for environments
   - `.gitignore` - Excludes `.ptrk_env/`, `.ptrk_build/`
   - `Gemfile` - References picotorokko gem from rubygems.org
   - `README.md` - Project overview and quick start instructions
   - `CLAUDE.md` - PicoRuby development guidelines
   - `storage/home/app.rb` - Sample application entry point
   - `patch/README.md` - Patch management documentation
4. If `--with-ci`: Copy `docs/github-actions/esp32-build.yml` to `.github/workflows/`
5. If `--with-mrbgem NAME`: For each NAME, generate mrbgem directory with templates:
   - `mrbgem.rake` - Build configuration
   - `mrblib/{name}.rb` - Ruby code template
   - `src/{name}.c` - C extension template
   - `README.md` - Mrbgem documentation

**Next Steps** (printed to console):
```
1. cd my-project
2. ptrk env set --latest  # Fetch latest repository versions
3. ptrk device build      # Build firmware for your device
4. ptrk device flash      # Flash firmware to ESP32
5. ptrk device monitor    # Monitor serial output
```

---

### 📦 Mrbgemfile Configuration

#### Overview

The `Mrbgemfile` is a Ruby DSL (Domain-Specific Language) for declaring mrbgem dependencies in your PicoRuby project. It allows you to specify which mrbgems to include in your build, with support for different sources (GitHub, local paths, core gems), branches, commit references, and conditional includes based on target platform.

**Location**: `<project-root>/Mrbgemfile`

**Purpose**: Automatically inject gem declarations into MRuby build configuration files during the build process

#### Syntax

The `Mrbgemfile` uses Ruby syntax with a block-based DSL:

```ruby
mrbgems do |conf|
  # Gem declarations go here
end
```

#### Gem Declaration Examples

**GitHub gems** (org/repo format):
```ruby
mrbgems do |conf|
  # With branch specification
  conf.gem github: "picoruby/picoruby-json", branch: "main"

  # With commit hash reference
  conf.gem github: "user/custom-gem", ref: "abc1234"

  # Latest main branch (implicit)
  conf.gem github: "user/simple-gem"
end
```

**Core mrbgems**:
```ruby
mrbgems do |conf|
  conf.gem core: "sprintf"
  conf.gem core: "fiber"
end
```

**Local gems** (path-based):
```ruby
mrbgems do |conf|
  conf.gem path: "./local-gems/my-sensor"
  conf.gem path: "../shared-gems/helpers"
end
```

**Git repositories** (arbitrary URLs):
```ruby
mrbgems do |conf|
  conf.gem git: "https://gitlab.com/custom/gem.git", branch: "develop"
end
```

#### Conditional Evaluation

Gem includes can be conditional based on the build target:

```ruby
mrbgems do |conf|
  # Always included
  conf.gem core: "sprintf"

  # Only included for ESP32 builds
  conf.gem github: "picoruby/picoruby-esp32-wifi" if conf.build_config_files.include?("xtensa-esp")

  # Only included for non-ESP32 builds
  conf.gem github: "picoruby/generic-wifi" unless conf.build_config_files.include?("xtensa-esp")

  # Platform-specific conditional
  if conf.build_config_files.include?("rp2040")
    conf.gem github: "picoruby/rp2040-sdk"
  end
end
```

The `conf.build_config_files` method returns an array containing the current build target name (e.g., `["xtensa-esp"]`, `["rp2040"]`), allowing conditional logic based on the target platform.

#### Supported Gem Parameters

| Parameter | Required | Type | Example | Notes |
|-----------|----------|------|---------|-------|
| `github` | * | String | `"org/repo"` | GitHub org/repo format |
| `core` | * | String | `"sprintf"` | Core mrbgem name |
| `path` | * | String | `"./local"` | Relative or absolute path |
| `git` | * | String | `"https://..."` | Full Git repository URL |
| `branch` | Optional | String | `"main"` | Git branch name (only with github/git) |
| `ref` | Optional | String | `"abc1234"` | Commit hash (overrides branch) |

*: One of these must be specified (mutually exclusive)

#### How It Works

1. **Parse**: The `Mrbgemfile` is evaluated as Ruby code with access to a special DSL context
2. **Conditional Evaluation**: Conditional statements (if/unless) are evaluated based on build target
3. **Collect Gems**: All `conf.gem` calls are collected into a list
4. **Application**: During `ptrk device build`, the gem list is applied to MRuby `build_config/*.rb` files
5. **Injection**: Gem declarations are injected between markers in the build configuration:
   - `# === BEGIN Mrbgemfile generated ===`
   - `# === END Mrbgemfile generated ===`

#### Build Configuration Integration

The Mrbgemfile is automatically applied when you run:

```bash
ptrk device build
```

This command:
1. Reads your `Mrbgemfile`
2. Evaluates it with the current build target context
3. Injects the resulting gems into `build/current/R2P2-ESP32/build_config/*.rb` files
4. Builds the firmware with the specified gems included

#### Example: Complete Mrbgemfile

```ruby
# PicoRuby application gem dependencies
mrbgems do |conf|
  # Core utilities (always included)
  conf.gem core: "sprintf"
  conf.gem core: "fiber"

  # Essential libraries
  conf.gem github: "picoruby/picoruby-json", branch: "main"
  conf.gem github: "picoruby/picoruby-yaml"

  # Platform-specific I/O
  if conf.build_config_files.include?("xtensa-esp")
    conf.gem github: "picoruby/picoruby-esp32-nvs"
    conf.gem github: "picoruby/picoruby-esp32-gpio"
    conf.gem github: "ksbmyk/picoruby-ws2812", branch: "main"
  elsif conf.build_config_files.include?("rp2040")
    conf.gem github: "picoruby/picoruby-rp2040-gpio"
    conf.gem github: "user/custom-rp2040-lib"
  end

  # Custom local gem
  conf.gem path: "./mrbgems/app"
end
```

---

### 🔍 Environment Inspection Commands

#### `ptrk env show`

**Description**: Display current environment configuration

**Output Example**:
```
Current environment: stable-2024-11
Symlink: build/current -> build/f500652-20241105_143022_6a6da3a-20241105_142015_e57c370-20241105_141030/

R2P2-ESP32:     f500652 (2024-11-05 14:30:22)
picoruby-esp32: 6a6da3a (2024-11-05 14:21:15)
picoruby:       e57c370 (2024-11-05 14:10:30)
```

---

#### `ptrk env set ENV_NAME`

**Description**: Create new environment with repository sources (org/repo, GitHub org, or local paths)

**Arguments**:
- `ENV_NAME` - Environment name to create (alphanumeric, lowercase, hyphens, underscores)

**Options** (all required if any specified, optional if all omitted):
- `--R2P2-ESP32 SOURCE` - Repository source
- `--picoruby-esp32 SOURCE` - Repository source
- `--picoruby SOURCE` - Repository source

**Source Formats**:
- `org/repo` - GitHub repository (auto-converts to `https://github.com/org/repo.git`)
- `path:/absolute/path` - Local Git repository (fetches HEAD commit automatically)
- `path:/absolute/path:commit` - Local Git repository with explicit commit hash

**Operation**:
1. If no options specified: Auto-fetches latest from default GitHub repos
2. If options specified: All three options are required
3. `org/repo` format is converted to GitHub URLs
4. `path://` sources fetch HEAD commit (or use explicit commit if provided)
5. Stores source URLs and commit hashes in `.picoruby-env.yml`

**Examples**:
```bash
# Auto-fetch latest from GitHub
ptrk env set latest

# Create with GitHub org/repo
ptrk env set prod \
  --R2P2-ESP32 picoruby/R2P2-ESP32 \
  --picoruby-esp32 picoruby/picoruby-esp32 \
  --picoruby picoruby/picoruby

# Use fork from different organization
ptrk env set my-fork \
  --R2P2-ESP32 myorg/R2P2-ESP32 \
  --picoruby-esp32 myorg/picoruby-esp32 \
  --picoruby myorg/picoruby

# Local repositories (auto-fetches HEAD)
ptrk env set local \
  --R2P2-ESP32 path:/home/user/R2P2-ESP32 \
  --picoruby-esp32 path:/home/user/picoruby-esp32 \
  --picoruby path:/home/user/picoruby

# Local repositories with explicit commits
ptrk env set specific \
  --R2P2-ESP32 path:/home/user/R2P2-ESP32:abc1234 \
  --picoruby-esp32 path:/home/user/esp32:def5678 \
  --picoruby path:/home/user/picoruby:ghi9012
```

**Output**:
```
✓ Environment 'prod' created
```

---

#### `ptrk env set --latest`

**Description**: Fetch latest versions and save environment definition with timestamp name

**Operation**:
1. Fetch HEAD commits from each repo via GitHub API or `git ls-remote`
2. Generate environment name from current timestamp (YYYYMMDD_HHMMSS)
3. Create environment definition in `.picoruby-env.yml`
4. Store commit hashes and timestamps for later build setup

**Note**: Actual build environment (`.ptrk_build/`) is created by `ptrk device build`

---

### 🔀 Patch Management Commands

#### `ptrk patch export [ENV_NAME]`

**Description**: Export changes from `build/{env}/` to `patch/`

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Operation**:
1. Execute `git diff --name-only` in `build/{env}/R2P2-ESP32/`
2. For each file:
   - Recreate directory structure in `patch/R2P2-ESP32/`
   - Save diff between `git show HEAD:{file}` and `build/{env}/{file}` to `patch/`
3. Same process for `components/picoruby-esp32/` and `picoruby/`

**Example**:
```bash
# After editing build/current/R2P2-ESP32/storage/home/custom.rb

ptrk patch export
# => Exporting changes from build/current/
#    patch/R2P2-ESP32/storage/home/custom.rb (created)
#    patch/picoruby-esp32/ (no changes)
#    patch/picoruby/ (no changes)
#    Done!
```

---

#### `ptrk patch diff [ENV_NAME]`

**Description**: Display diff between current changes in `build/{env}/` and existing patches

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Output Example**:
```
=== R2P2-ESP32 ===
diff --git a/storage/home/custom.rb (working) vs (patch/)
+ (new addition)
- (planned deletion)
  (changes displayed)

=== picoruby-esp32 ===
(no changes)
```

---

### 🏗️ Build and Device Commands

#### `ptrk device build [--env ENV_NAME]`

**Description**: Setup build environment in `.ptrk_build/` from environment cache and build firmware

**Arguments**:
- `--env ENV_NAME` - Environment name (default: current environment)

**Operation**:
1. Load environment definition from `.picoruby-env.yml`
2. Verify `.ptrk_env/{ENV_NAME}/` exists (readonly cache)
3. Copy `.ptrk_env/{ENV_NAME}/` to `.ptrk_build/{ENV_NAME}/`
4. Copy `storage/home/` to `.ptrk_build/{ENV_NAME}/R2P2-ESP32/storage/home/`
5. Copy `mrbgems/` to `.ptrk_build/{ENV_NAME}/R2P2-ESP32/mrbgems/`
6. Apply patches from `patch/` directory automatically
7. Execute `rake build` in `.ptrk_build/{ENV_NAME}/R2P2-ESP32/`

**Note**: Patches are applied automatically during build. Use `ptrk env patch_export` to save changes.

**Example**:
```bash
ptrk device build              # Uses current environment
ptrk device build --env 20251122_103000 # Use specific environment
# => Building: 20251122_103000
#    Copying environment to build directory...
#    ✓ Environment copied to .ptrk_build/20251122_103000
#    Copying storage/home/...
#    Applying patches...
#    ✓ Build completed
```

---

### 🚀 R2P2-ESP32 Task Delegation Commands

**Note**: The `ptrk build` command has been removed to avoid conflict with Build Environment Management commands. Use `rake build` directly in the R2P2-ESP32 directory instead.

#### `ptrk flash [ENV_NAME]`

**Description**: Flash built firmware to ESP32

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Operation**:
1. cd into `build/{env}/R2P2-ESP32/`
2. Setup ESP-IDF environment variables
3. Execute `rake flash` in R2P2-ESP32's `Rakefile`

---

#### `ptrk monitor [ENV_NAME]`

**Description**: Monitor ESP32 serial output

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Operation**:
1. cd into `build/{env}/R2P2-ESP32/`
2. Setup ESP-IDF environment variables
3. Execute `rake monitor` in R2P2-ESP32's `Rakefile`

---

## Workflow Examples

### Scenario 1: Initial Setup and Build

```bash
# 1. Fetch latest repository versions
ptrk env set --latest
# => Fetching latest from GitHub...
#    Created environment: 20251122_103000

# 2. Set as current environment
ptrk env current 20251122_103000

# 3. Build firmware
ptrk device build

# 4. Flash to device
ptrk device flash

# 5. Monitor serial output
ptrk device monitor

# Ctrl+C to exit
```

### Scenario 2: Validate Latest Version

```bash
# 1. Fetch latest version
ptrk env set --latest
# => Fetching latest from GitHub...
#    Created environment: 20251122_143500

# 2. Set as current and build
ptrk env current 20251122_143500
ptrk device build

# 3. If issues found, revert to previous environment
ptrk env current 20251121_103000
ptrk device build
```

### Scenario 3: Patch Management

```bash
# 1. Make changes in .ptrk_build/{env}/R2P2-ESP32/
# (edit files)

# 2. Export changes to patch
ptrk env patch_export

# 3. Git commit
git add patch/ storage/home/
git commit -m "Update patches and storage"

# 4. Test application in another environment
ptrk env current 20251121_103000
ptrk device build  # patches auto-applied
```

---

## Troubleshooting

### Cannot Fetch Environment

```bash
# Check GitHub connectivity
git ls-remote https://github.com/picoruby/R2P2-ESP32.git HEAD

# Re-fetch latest
ptrk env set --latest
```

### Build Environment Missing

```bash
# List available environments
ptrk env list

# Verify environment exists
ptrk env show 20251122_103000

# Rebuild
ptrk device build --env 20251122_103000
```

### Patches Not Applied

```bash
# Check diff
ptrk env patch_diff

# Rebuild (patches auto-applied)
ptrk device build
```

---

## Future Enhancements

- [ ] Automatic cache compression (tar.gz)
- [ ] Backup to S3/Cloud storage
- [ ] Automatic cache fetching in CI/CD
- [ ] GUI environment management tool
- [ ] Version comparison tool

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2024-11-05 | 1.0 | Initial specification |

---

## Type System & Type Annotations

The picotorokko gem leverages **rbs-inline** type annotations for comprehensive static type analysis and runtime safety.

### Type Coverage

**93.2% of methods are fully annotated** (165 of 177 methods):
- Template engines: 19 methods with complete signatures
- Core modules: 16 methods (Executor, PatchApplier, MrbgemsDSL, BuildConfigApplier)
- Command classes: 42 methods (Device, Env, Mrbgems, Rubocop, Init)

### Type Annotation Format

All public and private methods include `@rbs` inline comments following the rbs syntax:

```ruby
# Example: Device command with type-annotated private method
module Picotorokko
  module Commands
    class Device < Thor
      # @rbs (String) -> String
      private def resolve_env_name(env_name)
        # Resolves "current" to actual environment name
      end

      # @rbs (String, String) -> void
      private def delegate_to_r2p2(command, env_name)
        # Delegates task to R2P2-ESP32 Rakefile
      end
    end
  end
end
```

### Type Checking Tools

**Steep** (optional development tool) validates type safety:

```bash
bundle exec steep check
```

Expected output: Type definitions for external libraries (Thor, Prism) are unavailable, but all picotorokko gem code passes type validation.

### Benefits

1. **Static Analysis**: Catch type errors before runtime
2. **IDE Support**: Enable autocomplete and error detection in modern editors
3. **Documentation**: Type signatures serve as executable documentation
4. **Refactoring Safety**: Type checker validates changes across the codebase

---

## Device Testing with Picotest

### Overview

PicoRuby applications can be tested on actual devices (ESP32) using the Picotest framework. The `ptrk device --test` command enables:

- Test code compilation and deployment to devices
- Test execution on ESP32 with Picotest doubles for mocking
- Result parsing from serial output
- Integration with CI/CD pipelines

### Workflow

```
Development
├─ 1. ptrk new my-app          # Generate project with test template
├─ 2. Edit test/app_test.rb     # Write tests using Picotest
├─ 3. ptrk device build --test  # Build with test code
├─ 4. ptrk device flash         # Flash to ESP32
└─ 5. ptrk device monitor --test # Run & parse results

CI/CD
├─ 1. ptrk device build --test  # Verify build succeeds
├─ 2. Upload firmware artifact  # For later testing on hardware
└─ (Later) Physical hardware runs tests
```

### Directory Structure

```
project-root/
├── storage/home/
│   ├── app.rb              # Application entry point
│   ├── sensor.rb           # Application code
│   └── lib/
│       └── helper.rb       # Optional libraries
│
├── test/
│   ├── app_test.rb         # Tests for app.rb
│   ├── sensor_test.rb      # Tests for sensor.rb
│   └── lib/
│       └── helper_test.rb  # Tests for lib/helper.rb
│
└── Mrbgemfile              # Must include: conf.gem core: "picoruby-picotest"
```

### Test File Structure

```ruby
# test/sensor_test.rb
class SensorTest < Picotest::Test
  def setup
    # Runs before each test (optional)
  end

  def test_read_temperature
    # Stub C extension method (ADC hardware)
    stub_any_instance_of(ADC).read_raw { 750 }

    # Create object and test logic
    sensor = Sensor.new(27)
    result = sensor.read_temperature

    # Assertion
    assert_equal 25.0, result
  end

  def teardown
    # Runs after each test (optional)
    # Picotest doubles automatically cleaned up
  end
end
```

### Picotest Doubles (Mocking)

#### Stub (Replace Return Value)

```ruby
# Stub single instance
adc = ADC.new(27)
stub(adc).read_raw { 750 }
assert_equal 750, adc.read_raw

# Stub all instances of a class
stub_any_instance_of(GPIO).read { 1 }
gpio1 = GPIO.new(5, GPIO::IN)
gpio2 = GPIO.new(10, GPIO::IN)
assert_equal 1, gpio1.read
assert_equal 1, gpio2.read
```

#### Mock (Replace Return Value + Verify Call Count)

```ruby
# Mock with exact call count
mock_any_instance_of(I2C).write(2) { true }

i2c = I2C.new(0, sda: 21, scl: 22)
i2c.write(0x50, [0x01])  # 1st call
i2c.write(0x51, [0x02])  # 2nd call

# Teardown verifies: write was called exactly 2 times
# If not, test fails
```

#### Conditional Stubs

```ruby
stub_any_instance_of(I2C).read do |address, length|
  case address
  when 0x50 then [0x12, 0x34]
  when 0x51 then [0xAA, 0xBB]
  else [0x00]
  end
end

i2c = I2C.new(0, sda: 21, scl: 22)
assert_equal [0x12, 0x34], i2c.read(0x50, 2)
assert_equal [0xAA, 0xBB], i2c.read(0x51, 2)
```

### Command Reference

#### Build with Test Code

```bash
ptrk device build --test [--env ENV_NAME]
```

**What it does**:
1. Copy `test/` to `build/.../storage/home/test/`
2. Inject Picotest runner into `storage/home/app.rb`
3. Verify `picoruby-picotest` in Mrbgemfile
4. Build firmware normally (delegate to R2P2-ESP32 Rake)

#### Flash Test Firmware

```bash
ptrk device flash [--env ENV_NAME]
```

Standard flash (same as without `--test`).

#### Monitor with Test Result Parsing

```bash
ptrk device monitor --test [--env ENV_NAME]
```

**What it does**:
1. Monitor serial output from ESP32
2. Parse Picotest results (detect PASS/FAIL)
3. Display formatted summary with pass rate
4. Exit with code 0 (pass) or 1 (fail) for CI/CD

### Serial Output Format

```
Running SensorTest...
  test_read_temperature . PASS

Running MotorTest...
  test_forward FF FAIL
  test_backward . PASS

Summary
SensorTest:
  success: 1, failure: 0, exception: 0, crash: 0

MotorTest:
  success: 1, failure: 1, exception: 0, crash: 0

Total: success: 2, failure: 1, exception: 0, crash: 0

=== Picotest completed (exit code: 1) ===
```

**Output Symbols**:
- `.` = Test passed (PASS)
- `F` = Test failed (assertion failed)
- `E` = Test exception (unhandled error)
- `C` = Test crashed (process exit code != 0)

### Requirements

#### Mrbgemfile

Must include Picotest framework:

```ruby
# Mrbgemfile
mrbgems do |conf|
  conf.gem core: "picoruby-picotest"
  # ... other gems
end
```

#### Test File Naming

- Directory: `test/`
- Files: `*_test.rb` (suffix required)
- Classes: Inherit from `Picotest::Test`
- Methods: Start with `test_` (prefix required)

#### Available Assertions

```ruby
assert(condition)                              # Check truthiness
assert_equal(expected, actual)                 # Check equality
assert_nil(obj)                                # Check nil
assert_false(condition)                        # Check falsiness
assert_raise(ExceptionClass) { block }         # Check exception
assert_in_delta(expected, actual, delta)       # Float tolerance
```

### Implementation Details: ptrkコマンド側

#### ptrk device build --test

1. **prepare_test_build(r2p2_path)**
   - `copy_test_files(r2p2_path)` - Copy test/ to storage/home/test/
   - `inject_test_runner(r2p2_path)` - Add runner code to app.rb
   - `verify_picotest_in_mrbgemfile` - Check dependency exists

2. **Testランナーコード注入**
   - Picotestライブラリロード
   - test/*_test.rb ファイルロード
   - Picotest::Runner.run() 実行
   - 結果をシリアル出力

#### ptrk device monitor --test

1. **PicotestResultParser**
   - Parse "Running ClassName..." (test class start)
   - Parse "test_method . PASS" (test result)
   - Parse "Total: success: N, failure: M, ..." (summary)
   - Calculate exit code (0 if all pass, 1 if any fail)

2. **Output Formatting**
   - Color code: GREEN for pass, RED for fail
   - Display per-class summary
   - Show overall pass rate
   - Exit with code for CI/CD

### Best Practices

1. **Test Organization**
   - One test file per application file
   - Group related tests in same class
   - Descriptive test method names

2. **Test Isolation**
   - Use `setup` to create fresh objects
   - Use `teardown` to cleanup (if needed)
   - Avoid test interdependencies

3. **Hardware Abstraction**
   - Stub all hardware methods (GPIO, I2C, ADC, SPI)
   - Test business logic separately from hardware
   - Use mocks to verify hardware interaction

4. **Coverage**
   - Test happy paths and edge cases
   - Test error handling
   - Test boundary conditions

---

## Gem Developer Testing Guide

### Test Classification System

The picotorokko gem uses a **three-layer test classification** to ensure both development velocity and quality:

#### Unit Tests: Fast Development Feedback
**Location**: `test/unit/**/*_test.rb`
**Characteristics**:
- Mocked external dependencies (network, git, file I/O, system commands)
- Tests single class/module behavior in isolation
- No real git clone or network operations
- Fast feedback loop for TDD development

**Examples**:
- `test/unit/commands/init_test.rb` — Project initialization logic
- `test/unit/template/yaml_engine_test.rb` — YAML template engine
- `test/unit/picotorokko/executor_test.rb` — Command execution abstraction

**Usage**:
```bash
# Run unit tests only (fastest)
bundle exec rake test:unit

# Development mode (RuboCop auto-fix + unit tests)
bundle exec rake dev

# Default task (unit tests)
bundle exec rake
```

#### Integration Tests: Real Operations Verification
**Location**: `test/integration/**/*_test.rb`
**Characteristics**:
- Real git operations (clone, checkout, show, rev-parse)
- Real network calls to GitHub API
- Tests interactions between components
- Verifies actual system behavior

**Examples**:
- `test/integration/env_test.rb` — Env module with real git repos
- `test/integration/commands/env_test.rb` — Env command with git workflows
- `test/integration/commands/init_integration_test.rb` — Init with real environment setup

**Usage**:
```bash
# Run integration tests
bundle exec rake test:integration

# Skip network tests in CI
SKIP_NETWORK_TESTS=1 bundle exec rake test:integration
```

#### Scenario Tests: Complete User Workflows
**Location**: `test/scenario/**/*_test.rb`
**Characteristics**:
- End-to-end user workflow verification
- Tests main use cases and features
- Template rendering and variable substitution
- Project creation and device command flows

**Examples**:
- `test/scenario/init_scenario_test.rb` — Complete project creation workflows
- `test/scenario/commands/device_test.rb` — Device command execution flows

**Usage**:
```bash
# Run scenario tests
bundle exec rake test:scenario

# All scenario tests
bundle exec rake test
```

### Running Tests

#### Development Workflow
```bash
# 1. Unit tests for rapid feedback (fastest)
bundle exec rake test:unit

# 2. All tests for full verification before commit
bundle exec rake test

# 3. CI suite with RuboCop and coverage
bundle exec rake ci
```

#### Test Output Handling
**Important**: Always capture test output to temporary files:

```bash
# ❌ DON'T: Rely on stdout parsing directly
bundle exec rake ci | grep "passed"

# ✅ DO: Capture output and analyze with grep/tail
bundle exec rake ci > /tmp/test_output.txt 2>&1
grep "passed" /tmp/test_output.txt
tail -20 /tmp/test_output.txt
```

#### Test Result Verification
**Use shell exit codes** (0 = success, non-zero = failure):

```bash
# Verify test success
bundle exec rake test > /tmp/test.txt 2>&1
if [ $? -eq 0 ]; then
  echo "✓ All tests passed"
else
  echo "✗ Tests failed - check /tmp/test.txt"
fi
```

### Test Architecture Benefits

1. **Development Speed**: Unit tests provide rapid feedback for TDD cycles
2. **Quality Assurance**: Integration tests verify real git/network behavior
3. **User Confidence**: Scenario tests validate complete workflows
4. **CI/CD Integration**: Clear separation enables parallel execution and failure analysis
5. **Maintainability**: Each test layer has clear responsibility and dependencies

---

## Implementation Details for Gem Developers

For architectural decisions, implementation strategies, and detailed component specifications backing this user-facing specification, see [`.claude/docs/spec/`](./.claude/docs/spec/).
