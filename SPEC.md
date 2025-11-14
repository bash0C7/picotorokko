# PicoRuby ESP32 Multi-Version Build System Specification

## Overview

A build system for ESP32 + PicoRuby development that manages multiple versions of R2P2-ESP32 and its nested submodules (picoruby-esp32 → picoruby) in parallel, allowing easy switching and validation across versions.

---

## Design Principles

### 1. Immutable Cache

- Repositories saved in `.cache/` are **never modified**
- Uniquely identified by commit hash + timestamp
- New cache is always created when versions change
- Old caches can be removed via `ptrk cache prune` when no longer needed

### 2. Environment Isolation

- `build/{env-hash}/` is a complete working directory for each environment
- Multiple environments can coexist simultaneously
- `build/current` is a symlink pointing to the current working environment

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
│   ├── imu.rb
│   ├── led_ext.rb
│   └── ...
│
├── patch/                  # 🔴 Patch files
│   │                         # Git-managed
│   ├── README.md
│   ├── R2P2-ESP32/          # Directory hierarchy structure
│   │   └── storage/
│   │       └── home/
│   │           └── custom.rb
│   ├── picoruby-esp32/
│   │   └── (if changed)
│   └── picoruby/
│       └── (if changed)
│
├── .cache/                 # 🔵 Immutable version cache
│   │                         # Git-ignored (.gitignore)
│   ├── R2P2-ESP32/
│   │   ├── f500652-20241105_143022/    # commit-timestamp format
│   │   ├── 34a1c23-20241104_120000/
│   │   └── ...
│   ├── picoruby-esp32/
│   │   ├── 6a6da3a-20241105_142015/
│   │   └── ...
│   └── picoruby/
│       ├── e57c370-20241105_141030/
│       └── ...
│
├── build/                  # 🟢 Build working directory
│   │                         # Git-ignored (.gitignore)
│   ├── current -> f500652-20241105_143022_6a6da3a-..._e57c370-.../
│   │              🔗 symlink (switched during env change)
│   │
│   └── f500652-20241105_143022_6a6da3a-20241105_142015_e57c370-20241105_141030/
│       │
│       └── R2P2-ESP32/         # Build execution here
│           ├── components/
│           │   ├── picoruby-esp32/
│           │   │   └── picoruby/
│           │   └── main/
│           ├── storage/home/   # Application code copied here
│           ├── Rakefile
│           ├── build/
│           └── ...
│
├── SPEC.md                 # 🟡 This file (specification)
├── .picoruby-env.yml       # Environment configuration file
└── .gitignore              # Added .cache/, build/
```

---

## Naming Conventions

### commit-hash Format

```
{7-digit commit hash}-{YYYYMMDD_HHMMSS}

Examples:
  f500652-20241105_143022
  6a6da3a-20241105_142015
  e57c370-20241105_141030
```

- Commit hash: obtained via `git rev-parse --short=7 {ref}`
- Timestamp: extracted from `git show -s --format=%ci {commit}`
- Recorded in local timezone

### env-hash Format

```
{R2P2-hash}_{esp32-hash}_{picoruby-hash}

Example:
  f500652-20241105_143022_6a6da3a-20241105_142015_e57c370-20241105_141030
```

- Three commit-hashes concatenated with `_`
- Order: R2P2-ESP32 → picoruby-esp32 → picoruby

---

## Configuration File (.picoruby-env.yml)

```yaml
# PicoRuby development environment configuration file
# Each environment is immutable, uniquely identified by commit hash + timestamp

current: stable-2024-11

environments:
  stable-2024-11:
    R2P2-ESP32:
      commit: f500652
      timestamp: "20241105_143022"
    picoruby-esp32:
      commit: 6a6da3a
      timestamp: "20241105_142015"
    picoruby:
      commit: e57c370
      timestamp: "20241105_141030"
    created_at: "2024-11-05 14:30:22"
    notes: "Stable version"

  development:
    R2P2-ESP32:
      commit: 34a1c23
      timestamp: "20241104_120000"
    picoruby-esp32:
      commit: f331744
      timestamp: "20241104_115500"
    picoruby:
      commit: df21508
      timestamp: "20241104_115000"
    created_at: "2024-11-04 12:00:00"
    notes: "Under development"
```

**Field Descriptions:**

- `current` - Current working environment name (symlink `build/current` points to)
- `environments` - Environment definition map
- Each environment's `R2P2-ESP32/picoruby-esp32/picoruby` - Commit and timestamp
- `created_at` - Environment creation timestamp (reference)
- `notes` - Environment description (free text)

---

## CLI Commands Reference

### 🚀 Project Initialization Command

#### `ptrk init [PROJECT_NAME]`

**Description**: Initialize a new PicoRuby project structure with all necessary directories and configuration files

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
├── .cache/                 # Version cache (git-ignored)
├── build/                  # Build working directory (git-ignored)
├── ptrk_env/               # Environment metadata (git-ignored)
│
├── .picoruby-env.yml       # Environment configuration file
├── .gitignore              # Standard gitignore for ptrk projects
├── Gemfile                 # Ruby dependencies with picotorokko gem
├── README.md               # Project README (customizable template)
└── CLAUDE.md               # ptrk user development guide (auto-generated)
```

**Generated Files**:

1. **`.gitignore`** - Excludes `.cache/`, `build/`, `ptrk_env/*/` from version control
2. **`.picoruby-env.yml`** - Initial environment configuration (empty, ready for `ptrk env set`)
3. **`ptrk_env/.gitkeep`** - Preserves directory in git
4. **`Gemfile`** - Contains `picotorokko` gem dependency (when available in gems)
5. **`README.md`** - Template-generated with project name and author
6. **`CLAUDE.md`** - Auto-generated development guide for ptrk users
7. **`storage/home/main.rb`** - Example Ruby application (optional, can be customized)
8. **`patch/README.md`** - Guide for patch management workflow

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
ptrk init my-project
# => Creating new PicoRuby project: my-project
#    Creating directories...
#    Generating configuration files...
#    Done! Next steps:
#    1. cd my-project
#    2. ptrk env set main --commit <hash>
#    3. ptrk build setup
#    4. cd build/current/R2P2-ESP32 && rake build

# With custom author and CI setup
ptrk init my-project --author "John Doe" --with-ci
# => Creating new PicoRuby project: my-project
#    Copying GitHub Actions workflow...
#    Done!

# In custom directory with mrbgem
ptrk init my-iot-app --path /projects --with-mrbgem servo --with-mrbgem pwm
# => Creating new PicoRuby project: my-iot-app
#    Initializing mrbgems: servo, pwm
#    Done!

# Inline project creation
mkdir my-app && cd my-app && ptrk init
# => Creating new PicoRuby project: my-app (from current directory)
#    Done!
```

**Success Criteria**:
- All directories created with `.gitkeep` files where needed
- All template files rendered without errors
- `.gitignore` correctly excludes `.cache/`, `build/`, `ptrk_env/*/`
- `.picoruby-env.yml` contains empty environments map ready for `ptrk env set`
- Project is immediately usable with `ptrk env set` and `ptrk build setup`

---

## Project Initialization

### `ptrk init [PROJECT_NAME]`

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
├── ptrk_env/              # Environment metadata (git-ignored)
│   └── .gitkeep
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
ptrk init my-project
cd my-project
```

With GitHub Actions CI/CD:
```bash
ptrk init my-project --with-ci
```

With multiple mrbgems and author:
```bash
ptrk init my-project --with-mrbgem Sensor --with-mrbgem Motor --author "Alice"
```

Create in specific directory:
```bash
ptrk init --path ~/projects/ my-project
```

Create in current directory (uses current dir name):
```bash
mkdir my-project && cd my-project
ptrk init
```

**Operation**:
1. Validate project name (alphanumeric, dashes, underscores only)
2. Create directory structure with `.gitkeep` files
3. Render template files with project variables:
   - `.picoruby-env.yml` - Empty YAML structure ready for environments
   - `.gitignore` - Excludes `.cache/`, `build/`, `ptrk_env/*/`
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
2. ptrk env set main --commit <hash>
3. ptrk build setup
4. cd build/current/R2P2-ESP32 && rake build
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

#### `ptrk env latest`

**Description**: Fetch latest versions and switch to them

**Operation**:
1. Fetch HEAD commits from each repo via GitHub API or `git ls-remote`
2. Generate new environment name (e.g., `latest-20241105-143500`)
3. Save to `.cache` via `ptrk cache fetch`
4. Setup environment via `ptrk build setup`
5. Switch via `ptrk env set`

---

### 📦 Cache Management Commands

#### `ptrk cache list`

**Description**: Display list of cached repository versions

**Output Example**:
```
=== R2P2-ESP32 ===
  f500652 - 2024-11-05 14:30:22
  34a1c23 - 2024-11-04 12:00:00

=== picoruby-esp32 ===
  6a6da3a - 2024-11-05 14:21:15
  f331744 - 2024-11-04 11:55:00

=== picoruby ===
  e57c370 - 2024-11-05 14:10:30
  df21508 - 2024-11-04 11:50:00

Total cache size: 1.2GB
```

---

#### `ptrk cache fetch [ENV_NAME]`

**Description**: Fetch specified environment from GitHub and save to `.cache`

**Arguments**:
- `ENV_NAME` - Environment name (`latest`, `feature-xyz`, etc.)
- Default: `latest`

**Operation**:
1. Load corresponding environment definition from `.picoruby-env.yml`
2. Clone R2P2-ESP32 (to `.cache/R2P2-ESP32/{commit-hash}/`)
3. **3-level submodule traversal**:
   - Level 1: Update `components/picoruby-esp32`
   - Level 2: Update `components/picoruby-esp32/picoruby`
   - Level 3+: Output warning, do not process
4. Save picoruby-esp32 and picoruby to `.cache/` respectively
5. Extract timestamp from `git show -s --format=%ci`
6. Append to `.picoruby-env.yml`

**3-Level Submodule Traversal**:

- Level 1 (R2P2-ESP32):
  ```ruby
  Dir.chdir('.cache/R2P2-ESP32/{commit-hash}') do
    system('git submodule update --init --recursive')
  end
  ```
- Level 2 (picoruby-esp32):
  ```ruby
  Dir.chdir('.cache/R2P2-ESP32/{commit-hash}/components/picoruby-esp32') do
    system('git submodule update --init --recursive')
  end
  ```
- Level 3 (picoruby):
  ```ruby
  Dir.chdir('.cache/R2P2-ESP32/{commit-hash}/components/picoruby-esp32/picoruby') do
    # Check for 4th-level submodules
    if system('git config --file .gitmodules --get-regexp path')
      puts "WARNING: Found 4th-level submodule(s) - not handled"
    end
  end
  ```

**Example**:
```bash
ptrk cache fetch latest
# => Fetching R2P2-ESP32 HEAD...
#    Cloning to .cache/R2P2-ESP32/34a1c23-20241104_120000/
#    Updating submodule: components/picoruby-esp32
#    Updating submodule: components/picoruby-esp32/picoruby
#    Updating .picoruby-env.yml...
#    Done!
```

---

#### `ptrk cache clean REPO`

**Description**: Delete all caches for specified repo

**Arguments**:
- `REPO` - One of: `R2P2-ESP32`, `picoruby-esp32`, `picoruby`

**Operation**:
1. Delete all directories under `.cache/{repo}/`
2. Remove corresponding commits from `.picoruby-env.yml`

**Example**:
```bash
ptrk cache clean picoruby-esp32
# => Removing .cache/picoruby-esp32/...
```

---

#### `ptrk cache prune`

**Description**: Delete caches not referenced by any environment

**Operation**:
1. Collect all commits in use from all environments in `.picoruby-env.yml`
2. Compare against all commits in `.cache/`
3. Delete unused commits

**Example**:
```bash
ptrk cache prune
# => Unused .cache/R2P2-ESP32/old-hash-20240101_000000/ - removing
#    Freed: 500MB
```

---

### 🔨 Build Environment Management Commands

#### `ptrk build setup [ENV_NAME]`

**Description**: Setup `build/{env-hash}/` for specified environment

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Operation**:
1. Load environment definition from `.picoruby-env.yml`
2. Check if corresponding cache exists in `.cache/` (error if not)
3. Create `build/{env-hash}/` directory
4. Copy from `.cache/R2P2-ESP32/{commit-hash}/` to `build/{env-hash}/R2P2-ESP32/`
5. Remove `build/{env-hash}/R2P2-ESP32/components/picoruby-esp32/`
6. Copy from `.cache/picoruby-esp32/{commit-hash}/` to `build/{env-hash}/R2P2-ESP32/components/picoruby-esp32/`
7. Similarly copy `picoruby/`
8. Apply `patch/` (same process as `patch:apply`)
9. Copy `storage/home/` to `build/{env-hash}/R2P2-ESP32/storage/home/`
10. Relink `build/current` symlink to `build/{env-hash}/`

**Example**:
```bash
ptrk build setup stable-2024-11
# => Setting up build environment: stable-2024-11
#    Creating build/f500652-20241105_143022_6a6da3a-20241105_142015_e57c370-20241105_141030/
#    Copying .cache/R2P2-ESP32/f500652-20241105_143022/
#    Copying .cache/picoruby-esp32/6a6da3a-20241105_142015/
#    Copying .cache/picoruby/e57c370-20241105_141030/
#    Applying patches...
#    Copying storage/home/
#    Updating symlink: build/current
#    Done! (Ready to build)
```

---

#### `ptrk build clean [ENV_NAME]`

**Description**: Delete specified build environment

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Operation**:
1. If `build/current` is a symlink, read its target
2. If env_name is `current`, delete symlink target and clear `build/current`
3. Otherwise, delete specified environment

**Example**:
```bash
ptrk build clean development
# => Removing build/34a1c23-20241104_120000_f331744-20241104_115500_df21508-20241104_115000/
```

---

#### `ptrk build list`

**Description**: Display list of constructed environments under `build/`

**Output Example**:
```
=== Build Environments ===

build/current -> f500652-20241105_143022_6a6da3a-20241105_142015_e57c370-20241105_141030/

Available:
  f500652-20241105_143022_6a6da3a-20241105_142015_e57c370-20241105_141030/    (2.5GB)  stable-2024-11
  34a1c23-20241104_120000_f331744-20241104_115500_df21508-20241104_115000/    (2.3GB)  development

Total build storage: 4.8GB
```

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

#### `ptrk patch apply [ENV_NAME]`

**Description**: Apply `patch/` to `build/{env}/`

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Operation**:
1. Read all files under `patch/R2P2-ESP32/`
2. Copy to corresponding paths in `build/{env}/R2P2-ESP32/`
3. Create directory structure if different
4. Same process for `components/picoruby-esp32/` and `picoruby/`

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

### Scenario 1: Build and Run with Stable Version

```bash
# 1. Check environment
ptrk env show

# 2. Build (via R2P2-ESP32's Rakefile directly)
cd build/current/R2P2-ESP32
rake build
cd ../../..

# 3. Flash and monitor
ptrk flash
ptrk monitor

# Ctrl+C to exit
```

### Scenario 2: Validate Latest Version

```bash
# 1. Fetch latest version
ptrk env latest
# => Fetching latest from GitHub...
#    Created environment: latest-20241105-143500
#    Setting up environment...
#    Switched to: latest-20241105-143500

# 2. Build
cd build/current/R2P2-ESP32
rake build
cd ../../..

# 3. If issues found, revert to stable
ptrk env set stable-2024-11
cd build/current/R2P2-ESP32
rake build
cd ../../..
```

### Scenario 3: Patch Management

```bash
# 1. Make changes in build/current/
# (edit files)

# 2. Export changes to patch
ptrk patch export

# 3. Git commit
git add patch/ storage/home/
git commit -m "Update patches and storage"

# 4. Test application in another environment
ptrk env set development
ptrk build setup  # patches auto-applied
cd build/current/R2P2-ESP32
rake build
cd ../../..
```

---

## Troubleshooting

### Cannot Fetch Cache

```bash
# Check GitHub connectivity
git ls-remote https://github.com/picoruby/R2P2-ESP32.git HEAD

# Clean cache and re-fetch
ptrk cache clean R2P2-ESP32
ptrk cache fetch latest
```

### Build Environment Missing

```bash
# Check cache
ptrk cache list

# Setup environment
ptrk build setup ENV_NAME
```

### Patches Not Applied

```bash
# Check diff
ptrk patch diff

# Re-apply
ptrk build clean
ptrk build setup ENV_NAME
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

## Implementation Details for Gem Developers

For architectural decisions, implementation strategies, and detailed component specifications backing this user-facing specification, see [`.claude/docs/spec/`](./.claude/docs/spec/).
