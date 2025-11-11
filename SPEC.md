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

**Description**: Switch to specified environment

**Arguments**:
- `ENV_NAME` - Environment name defined in `.picoruby-env.yml`

**Operation**:
1. Load environment definition from `.picoruby-env.yml`
2. Check if corresponding `build/{env-hash}/` exists
3. Relink `build/current` symlink
4. Update `current` in `.picoruby-env.yml`

**Example**:
```bash
ptrk env set development
# => Switching to development
#    build/current -> build/34a1c23-20241104_120000_f331744-20241104_115500_df21508-20241104_115000/
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

## Implementation Details for Gem Developers

For architectural decisions, implementation strategies, and detailed component specifications backing this user-facing specification, see [`.claude/docs/spec/`](./.claude/docs/spec/).
