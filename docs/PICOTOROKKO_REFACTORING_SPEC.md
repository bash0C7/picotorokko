# picotorokko (ptrk) Major Refactoring Specification

**Last Updated**: November 9, 2024
**Status**: Planning Phase (Not Yet Implemented)
**Scope**: Gem rename, command simplification, directory structure consolidation

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Naming Decision](#naming-decision)
3. [Current Problems Analysis](#current-problems-analysis)
4. [Design Principles](#design-principles)
5. [New Command Structure](#new-command-structure)
6. [Directory Structure Changes](#directory-structure-changes)
7. [Git Management Policy](#git-management-policy)
8. [Environment Name Validation](#environment-name-validation)
9. [Deleted Features](#deleted-features)
10. [Path Constants Mapping](#path-constants-mapping)
11. [File Creation Matrix](#file-creation-matrix)
12. [Template Inventory](#template-inventory)
13. [Test Strategy](#test-strategy)
14. [Implementation Checklist](#implementation-checklist)
15. [Migration Guide](#migration-guide-future-reference)

---

## Executive Summary

This refactoring transforms the `pra` gem into `picotorokko` with execution command `ptrk`. The changes include:

- **Gem rename**: `pra` → `picotorokko`
- **Command rename**: `pra` → `ptrk`
- **Command simplification**: 8 commands → 4 commands
- **Directory consolidation**: Unified `ptrk_env/` directory
- **Breaking changes**: Yes, but no users affected (gem unreleased)

### Key Metrics

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Top-level commands | 8 | 4 | -50% |
| Command files | 8 | 4 | -50% |
| Tests affected | ~76 | ~76 | restructured |
| RuboCop compliance | 0 violations | 0 violations | maintained |

### Timeline & Effort

- **Estimated effort**: Large (2-3 weeks)
- **Phases**: 6 (naming, structure, commands, tests, docs, QA)
- **Risk level**: Medium (complete restructuring)
- **User impact**: None (pre-release)

---

## Naming Decision

### Why Rename from `pra` to `picotorokko`?

#### The Rails Metaphor

Ruby on Rails uses the "Rails" metaphor: developers follow railway tracks at high speed for rapid development. This is a powerful and memorable metaphor rooted in Ruby culture.

**PicoRuby needs an equally fitting metaphor**: Instead of full-size railways, we use **トロッコ (torokko)** - small mining/construction track vehicles.

#### Metaphor Alignment

| Aspect | Rails | picotorokko |
|--------|-------|------------|
| Scale | Full railway system | Small track vehicle |
| Speed | High-speed rail | Controlled pace |
| Concept | Large framework | Lightweight, embedded |
| Complexity | Enterprise-grade | Simple, practical |
| PicoRuby fit | ✅ Historical | ✅ **Ideal** |

### Why `ptrk` as the Command?

#### Typability vs Branding

- **Gem name**: `picotorokko` - Full, memorable, represents the project
- **Command**: `ptrk` - 4 characters, fast to type

This follows precedent in the industry:

| Project | Full Name | Short Command |
|---------|-----------|---------------|
| Kubernetes | kubectl | k |
| docker-compose | docker-compose | dc |
| **picotorokko** | **picotorokko** | **ptrk** |

**Why split?**
1. ✅ Branding: READMEs and docs use "picotorokko"
2. ✅ Usability: CLI supplement completes `ptrk<TAB>`
3. ✅ Clarity: `gem install picotorokko` then `ptrk env set development`

### Naming Candidates Evaluated

Investigation considered three strong candidates:

| Name | Score | Pros | Cons |
|------|-------|------|------|
| **picotorokko** | 22/25 | Japanese heritage, perfect metaphor, memorable | 11 chars (long) |
| **picogauge** | 23/25 | N-gauge model trains, technical ring | Less intuitive for non-enthusiasts |
| **pra** | 15/25 | Current, simple | No metaphor, not memorable |

**Decision**: `picotorokko` chosen for identity and metaphor strength.

---

## Current Problems Analysis

This refactoring addresses fundamental design inconsistencies in the current `pra` gem.

### Problem 1: Command Naming Inconsistency

**Pattern Analysis**:

All commands follow `<subject> <action>` pattern:
- `pra env show/set/latest` ✅ (subject: env, actions: show/set/latest)
- `pra cache list/fetch/clean` ✅ (subject: cache, actions: list/fetch/clean)
- `pra patch export/apply/diff` ✅ (subject: patch, actions: export/apply/diff)
- `pra device flash/monitor/build` ✅ (subject: device, actions: flash/monitor/build)

**The Exception**:
- `pra build setup/clean/list` ❌ (setup/clean/list are actions, but build is ambiguous)

**Why it's confusing**: "build" could mean:
1. The action of compiling firmware (`pra device build`)
2. A working environment (`pra build setup`)

Two different concepts share the same word.

### Problem 2: Responsibility Overlap

| Command | Responsibility | Issue |
|---------|----------------|-------|
| `pra env` | Environment definitions (metadata) | Clean separation |
| `pra cache` | Immutable repository cache | Auxiliary to `build` |
| `pra build` | Build environment (working directory) | **Depends on cache** |
| `pra patch` | Patch management | **Auto-applied by build** |

**The issue**: `pra build setup` internally:
1. Reads from `pra env` (environment definition)
2. Copies from `.cache/` (created by `pra cache fetch`)
3. Applies patches from `pra patch`
4. Generates new patches automatically

This tight coupling makes each command hard to understand in isolation.

### Problem 3: Side Effect Matrix

Current implementation has complex side effect dependencies:

```
pra env set/latest
    ↓ (updates)
.picoruby-env.yml
    ↓ (read by)
pra cache fetch → .cache/
    ↓ (copied by)
pra build setup → build/{env-hash}/
    ↓ (patches applied to)
pra patch (export/apply)
    ↓ (auto-generated)
patch/ directory
```

**Why it's problematic**:
- Implicit dependencies make errors hard to diagnose
- `pra build setup` does too many things
- `current` symlink creates additional state

### Problem 4: User Mental Model Mismatch

New users expect:
- `pra env` to manage environments ✅
- `pra build` to build firmware ❌ (Actually it sets up working directory)
- `pra device build` to build firmware ✅ (But then why two "build"s?)

**Result**: Confusion about command purpose and usage order.

---

## Design Principles

### Principle 1: Two Distinct Project Roots

**Critical Insight**: The refactoring must clearly separate:

#### A. picotorokko gem root (gem developer)
```
/path/to/picotorokko/
├── lib/ptrk/
├── test/
├── ptrk.gemspec
├── Rakefile
└── docs/
```

**Purpose**: Gem source code and development
**Path**: `File.expand_path("../../", __dir__)` from within code
**Requirement**: Tests must NOT pollute this directory

#### B. ptrk user's project root (ptrk user)
```
/path/to/my-picoruby-app/
├── ptrk_env/
│   ├── .picoruby-env.yml
│   ├── .cache/
│   ├── development/
│   └── production/
├── patch/
├── mrbgems/
└── storage/
```

**Purpose**: PicoRuby application development
**Path**: `Dir.pwd` when ptrk commands execute
**Requirement**: All ptrk file generation happens here

**Why Separate?**

1. **Test isolation**: Prevent accidental gem root pollution
2. **Clarity**: Each file goes to the right place
3. **Debugging**: Easy to identify which root caused a problem
4. **Automation**: CI/CD can verify gem root cleanliness

### Principle 2: Simplicity Over Features

**Trade-off**: Prefer fewer commands with clear purposes over many commands with overlapping responsibilities.

**Example**:
- ❌ Current: `pra build setup`, `pra build clean`, `pra build list`
- ✅ New: Part of `ptrk env` (environment operations)

### Principle 3: Environment Names Over Implicit State

**Trade-off**: Prefer explicit environment names over symbolic links and implicit "current" state.

**Example**:
- ❌ Current: `pra build setup` then `pra device flash` (implicitly uses `build/current`)
- ✅ New: `ptrk device flash development` (explicitly names environment)

**Benefits**:
- No hidden state
- Easier scripting and automation
- Clear in error messages
- Supports multiple workflows

### Principle 4: Validation as First-Class Concern

**New approach**: All environment names are validated early and consistently.

**Validation rule**: `/^[a-z0-9_-]+$/`
- ✅ Allows: `development`, `production`, `feature-wifi`, `test_123`
- ❌ Rejects: `Development`, `PROD`, `feature wifi`, `feature/wifi`

**Why lowercase only?**
- Filesystem portability (case-insensitive systems)
- Prevents accidental duplication (`dev`, `Dev`, `DEV`)
- Clearer in shell scripts and error messages

---

## New Command Structure

### Overview: 4 Commands (Down from 8)

```bash
ptrk env       # Environment management (replaces: env, cache, build, patch)
ptrk device    # ESP32 hardware operations (unchanged)
ptrk mrbgem    # mrbgem generation (unchanged)
ptrk rubocop   # RuboCop configuration (unchanged)
```

### 1. `ptrk env` - Environment Management

**Subcommands**:

#### `ptrk env` (list)
```bash
$ ptrk env
Available environments:
  development (R2P2: f500652, ESP32: 6a6da3a, PicoRuby: e57c370)
  production  (R2P2: abc1234, ESP32: def5678, PicoRuby: ghi9012)

Available commands:
  ptrk env set ENV_NAME                Create/update environment
  ptrk env show ENV_NAME               Display environment versions
  ptrk env reset ENV_NAME              Rebuild environment from cache
  ptrk env patch_export ENV_NAME       Export environment changes
  ptrk env patch_apply ENV_NAME        Apply saved patches
  ptrk env patch_diff ENV_NAME         Show patch differences
```

#### `ptrk env set ENV_NAME [OPTIONS]`

Create or update an environment.

**Arguments**:
- `ENV_NAME` (required): Name for this environment (lowercase, numbers, `-`, `_` only)

**Options**:
- `--r2p2 COMMIT_OR_BRANCH` (optional): R2P2-ESP32 commit hash or branch (default: `main`)
- `--esp32 COMMIT_OR_BRANCH` (optional): picoruby-esp32 commit hash or branch (default: `main`)
- `--picoruby COMMIT_OR_BRANCH` (optional): picoruby commit hash or branch (default: `main`)

**Examples**:
```bash
# Create 'development' using latest main branches
ptrk env set development

# Create 'stable' with specific commits
ptrk env set stable \
  --r2p2=f500652 \
  --esp32=6a6da3a \
  --picoruby=e57c370

# Create 'feature-wifi' mixing latest and pinned commits
ptrk env set feature-wifi \
  --r2p2=main \
  --esp32=6a6da3a \
  --picoruby=main
```

**Behavior**:
1. Validate environment name (regex: `/^[a-z0-9_-]+$/`)
2. Fetch latest commits if branch names provided (GitHub API)
3. Check if cache exists, clone to cache if needed
4. Create `ptrk_env/{env_name}/` directory
5. Copy cached repositories to `ptrk_env/{env_name}/`
6. Apply patches from `patch/` directory
7. Auto-generate `mrbgems/App/` if not exists
8. Update `.picoruby-env.yml`

#### `ptrk env show ENV_NAME`

Display version information for an environment.

**Output**:
```
Environment: development

Repository Versions:
  R2P2-ESP32:
    Commit: f500652
    Date: 2024-11-05 14:30:22
    Message: Fix WiFi connection timeout

  picoruby-esp32:
    Commit: 6a6da3a
    Date: 2024-11-05 14:20:15
    Message: Add GPIO support

  picoruby:
    Commit: e57c370
    Date: 2024-11-05 14:10:30
    Message: Improve memory allocation

Build Status:
  Directory: ptrk_env/development/
  Status: Ready
  Size: 542 MB
```

#### `ptrk env reset ENV_NAME`

Rebuild an environment from cache (or clone if cache missing).

**Behavior**:
1. Check if `ptrk_env/{env_name}/` exists
2. If cache exists: Copy from cache
3. If cache missing: Clone from GitHub and cache
4. Apply patches
5. Report success or error

**Use cases**:
- After modifying patches
- Resolving corruption or conflicts
- Testing patch application

#### `ptrk env patch_export ENV_NAME`

Export changes from environment to `patch/` directory.

**Behavior**:
1. Find all modified files in `ptrk_env/{env_name}/` (git diff by repo)
2. Create directory structure in `patch/{repo_name}/`
3. Copy modified files to patch directory
4. Ready for git commit

**Example output**:
```
Exporting patches from 'development'...
  R2P2-ESP32:
    Exported 3 files to patch/R2P2-ESP32/
  picoruby-esp32:
    Exported 1 file to patch/picoruby-esp32/
    Exported 1 file to patch/picoruby-esp32/CMakeLists.txt
  picoruby:
    Exported 2 files to patch/picoruby/

Ready for: git add patch/ && git commit
```

#### `ptrk env patch_apply ENV_NAME`

Apply saved patches from `patch/` to environment.

**Behavior**:
1. Check for patches in `patch/` directory
2. Copy patch files to corresponding locations in `ptrk_env/{env_name}/`
3. Report applied patches

**Use cases**:
- After switching environments
- After git pull (patches from team)
- Preparing new environment with known modifications

#### `ptrk env patch_diff ENV_NAME`

Show differences between environment and saved patches.

**Output**:
- Files in environment but not in patches
- Files in patches but not in environment
- File changes between the two

### 2. `ptrk device` - Hardware Operations

**Subcommands** (all take optional `ENV_NAME`, defaults to `development`):

```bash
ptrk device build [ENV_NAME]           # Compile firmware
ptrk device flash [ENV_NAME]           # Write to ESP32
ptrk device monitor [ENV_NAME]         # Serial output
```

**Implementation**:
- Delegates to `ptrk_env/{env_name}/R2P2-ESP32/Rakefile`
- Supports dynamic task discovery via `method_missing`

### 3. `ptrk mrbgem` - mrbgem Generation

**Subcommand**:

```bash
ptrk mrbgem generate [NAME] [OPTIONS]
```

(Unchanged from current)

### 4. `ptrk rubocop` - RuboCop Configuration

**Subcommands**:

```bash
ptrk rubocop setup                     # Install configuration
ptrk rubocop update                    # Update method database
```

(Unchanged from current)

---

## Directory Structure Changes

### Current Structure

```
picoruby-application-on-r2p2-esp32-development-kit/
├── .cache/                          # Immutable caches
│   ├── R2P2-ESP32/{commit-timestamp}/
│   ├── picoruby-esp32/{commit-timestamp}/
│   └── picoruby/{commit-timestamp}/
├── .picoruby-env.yml                # Environment metadata
├── build/                           # Working directories
│   ├── current -> {env-hash}/
│   └── {env-hash}/
│       └── R2P2-ESP32/
├── patch/                           # User patches (Git-tracked)
├── mrbgems/                         # App-specific mrbgem
├── storage/home/                    # Device code (Git-tracked)
└── ...
```

### New Structure

```
picoruby-application-on-r2p2-esp32-development-kit/
├── ptrk_env/                        # Consolidated environment directory
│   ├── .picoruby-env.yml            # Environment definitions (Git-tracked)
│   ├── .cache/                      # Immutable caches (Git-ignored)
│   │   ├── R2P2-ESP32/{commit-timestamp}/
│   │   ├── picoruby-esp32/{commit-timestamp}/
│   │   └── picoruby/{commit-timestamp}/
│   ├── development/                 # Development environment (Git-ignored)
│   │   └── R2P2-ESP32/
│   ├── production/                  # Production environment (Git-ignored)
│   │   └── R2P2-ESP32/
│   └── [other-env-names]/          # Other user-defined environments
├── patch/                           # User patches (Git-tracked)
├── mrbgems/                         # App-specific mrbgem (Git-tracked)
├── storage/home/                    # Device code (Git-tracked)
└── ...
```

### Why This Change?

1. **Consolidation**: All environment-related files under one roof
2. **Clarity**: No confusion between `.cache/`, `build/`, `.picoruby-env.yml`
3. **Scalability**: Multiple environments easily managed
4. **Git management**: Single `.gitignore` pattern covers all ignored content

### Migration Logic

During `ptrk env set ENV_NAME`:

```
.cache/                    → ptrk_env/.cache/
build/current/R2P2-ESP32/  → ptrk_env/ENV_NAME/R2P2-ESP32/
.picoruby-env.yml          → ptrk_env/.picoruby-env.yml
```

---

## Git Management Policy

### Files to Track (✅ Commit to git)

```yaml
ptrk_env/.picoruby-env.yml        # Environment definitions
                                   # Enables: reproducible builds, version history

patch/                             # User modifications to repositories
                                   # Enables: patch management, team collaboration

mrbgems/                           # Application-specific mrbgems
                                   # Enables: source control for app code

storage/home/                      # ESP32 application code
                                   # Enables: version control for device code
```

**Why track these?**
- Definitions are metadata (small, text)
- Patches are user creations (intentional, valuable)
- App code is source code (must be tracked)
- Storage is device code (must be tracked)

### Files to Ignore (❌ Don't commit)

```yaml
ptrk_env/{env_name}/               # Working directories
                                   # Why: Large, temporary, derived from cache

ptrk_env/.cache/                   # Immutable caches from GitHub
                                   # Why: Large, reproducible, can be regenerated
```

### `.gitignore` Changes

```diff
- build/
+ ptrk_env/*/

- .cache/
+ ptrk_env/.cache/

- .picoruby-env.yml
+ !ptrk_env/.picoruby-env.yml
```

**Key pattern**:
- Ignore everything under `ptrk_env/`
- **Except** `.picoruby-env.yml` (force-track it)

```gitignore
ptrk_env/
!ptrk_env/.picoruby-env.yml
```

---

## Environment Name Validation

### Rules

**Regex**: `/^[a-z0-9_-]+$/`

**Allowed characters**:
- ✅ Lowercase letters: `a-z`
- ✅ Numbers: `0-9`
- ✅ Hyphen: `-`
- ✅ Underscore: `_`

**Not allowed**:
- ❌ Uppercase letters: `A-Z`
- ❌ Spaces or special chars
- ❌ Relative paths: `../`, `./`

**Valid examples**:
- `development`
- `production`
- `feature-wifi`
- `test_env`
- `v2_3_stable`

**Invalid examples**:
- `Development` (uppercase)
- `PROD` (uppercase)
- `feature wifi` (space)
- `feature/wifi` (slash)
- `../evil` (path traversal)

### Implementation

All commands accepting environment names must validate:

```ruby
# lib/ptrk/validator.rb
module Ptrk
  class Validator
    ENV_NAME_PATTERN = /\A[a-z0-9_-]+\z/

    def self.validate_env_name!(name)
      unless name&.match?(ENV_NAME_PATTERN)
        raise ArgumentError,
          "Invalid environment name: '#{name}'. " \
          "Must contain only lowercase letters, numbers, hyphens, and underscores."
      end
    end
  end
end
```

**Validation points**:
- `Ptrk::Env.set_environment(env_name, ...)`
- `Ptrk::Commands::Env#set`
- `Ptrk::Commands::Device` (all methods)
- `Ptrk::Commands::Cache#fetch` (if used internally)

### Default Environment

**Default**: `development`

This follows Rails convention and makes commands simpler:

```bash
# Explicit (always works)
ptrk device build development

# Implicit (uses default)
ptrk device build
```

---

## Deleted Features

### 1. `pra cache` Command

**Current functionality**:
- `pra cache list` - List cached repositories
- `pra cache fetch` - Clone repositories to cache
- `pra cache clean` - Delete cache for a repository
- `pra cache prune` - Remove unused caches

**Why delete?**

Cache operations are now automatic:
- `ptrk env set` automatically fetches to cache if needed
- Cache is transparent to users (hidden in `ptrk_env/.cache/`)
- Manual cache management is rarely needed
- Simplifies CLI from 8 to 4 commands

**Replacement workflow**:
```bash
# Old
pra cache fetch latest
pra build setup latest

# New
ptrk env set development
```

### 2. `pra build` Command

**Current functionality**:
- `pra build setup` - Create build environment
- `pra build clean` - Delete build environment
- `pra build list` - List environments

**Why delete?**

These operations belong in `ptrk env`:
- `ptrk env set` replaces `pra build setup`
- `ptrk env` list replaces `pra build list`
- Build environment is now managed as environment state

**Replacement workflow**:
```bash
# Old
pra build setup current
pra build list

# New
ptrk env set development
ptrk env
```

### 3. `pra patch` Command

**Current functionality**:
- `pra patch export` - Export changes to patch files
- `pra patch apply` - Apply patch files to environment
- `pra patch diff` - Show differences

**Why delete?**

These operations are now `ptrk env` subcommands:
- `ptrk env patch_export` (was: `pra patch export`)
- `ptrk env patch_apply` (was: `pra patch apply`)
- `ptrk env patch_diff` (was: `pra patch diff`)

This makes patches clearly part of environment management.

**Replacement workflow**:
```bash
# Old
pra patch export current
pra patch apply current

# New
ptrk env patch_export development
ptrk env patch_apply development
```

### 4. `pra env latest` Subcommand

**Current functionality**: Create environment definition from latest GitHub commits

**Why delete?**

It's now implicit in `ptrk env set`:

```bash
# Old: Two steps
pra env latest
pra build setup latest

# New: One step
ptrk env set development
# (automatically uses main/master if not specified)
```

### 5. `current` Symlink Concept

**Current behavior**: `build/current` symlink maintains implicit state

**Why delete?**

Explicit environment names are clearer:
- No hidden state
- Easier scripting: `ptrk device flash production`
- Clear in error messages
- No "which environment am I in?" confusion

**Replacement approach**:
```bash
# Old
ptrk device flash          # Which environment? Depends on build/current

# New
ptrk device flash development   # Explicit
ptrk device flash production    # Explicit
```

**Note**: Users can still name an environment `current` if they want, but it's not special.

---

## Path Constants Mapping

### Current Constants

| Constant | Current Definition | Use Locations |
|----------|-------------------|---------------|
| `PROJECT_ROOT` | `Dir.pwd` | All path operations |
| `CACHE_DIR` | `File.join(PROJECT_ROOT, '.cache')` | Cache operations |
| `BUILD_DIR` | `File.join(PROJECT_ROOT, 'build')` | Build environment |
| `PATCH_DIR` | `File.join(PROJECT_ROOT, 'patch')` | Patch operations |
| `STORAGE_HOME` | `File.join(PROJECT_ROOT, 'storage', 'home')` | Device code |
| `ENV_FILE` | `File.join(PROJECT_ROOT, '.picoruby-env.yml')` | Metadata |

### New Constants (picotorokko)

```ruby
# lib/ptrk/env.rb - NEW CONSTANTS

# User's project root (where ptrk commands execute)
PTRK_USER_ROOT = Dir.pwd

# Gem development root (for template loading, etc.)
# NOTE: Update this if picotorokko repo name changes
PTRK_GEM_ROOT = File.expand_path("../../", __dir__)

# ptrk_env/ subdirectories
PTRK_ENV_DIR = File.join(PTRK_USER_ROOT, 'ptrk_env')
PTRK_ENV_CACHE_DIR = File.join(PTRK_ENV_DIR, '.cache')
PTRK_ENV_FILE = File.join(PTRK_ENV_DIR, '.picoruby-env.yml')

# Unchanged (project-level)
PATCH_DIR = File.join(PTRK_USER_ROOT, 'patch')
STORAGE_HOME = File.join(PTRK_USER_ROOT, 'storage', 'home')
MRBGEMS_DIR = File.join(PTRK_USER_ROOT, 'mrbgems')

# Helper method
def ptrk_env_path(env_name)
  File.join(PTRK_ENV_DIR, env_name)
end

def get_cache_path(repo_name, commit_hash)
  File.join(PTRK_ENV_CACHE_DIR, repo_name, commit_hash)
end
```

### Code Update Locations

**Files requiring constant updates**:

1. `lib/ptrk/env.rb` - Define all constants
2. `lib/ptrk/commands/env.rb` - Use PTRK_ENV_DIR, PTRK_ENV_FILE
3. `lib/ptrk/commands/device.rb` - Use ptrk_env_path()
4. `lib/ptrk/commands/mrbgems.rb` - Use MRBGEMS_DIR
5. `test/test_helper.rb` - Use PTRK_USER_ROOT (temp directory)

---

## File Creation Matrix

When commands execute, they create files in the **ptrk user's project root** (`Dir.pwd`):

| Command | Method | Created Files/Dirs | Git Status | Purpose |
|---------|--------|------------------|-----------|---------|
| **ptrk env set** | `Env.set_environment` | `ptrk_env/` | ❌ Ignored | Environment root |
| | | `ptrk_env/{env_name}/` | ❌ Ignored | Environment directory |
| | | `ptrk_env/{env_name}/R2P2-ESP32/` | ❌ Ignored | R2P2-ESP32 working copy |
| | | `ptrk_env/.picoruby-env.yml` | ✅ Tracked | Environment metadata |
| **ptrk env set** | `Build.generate_app_mrbgem` | `mrbgems/App/` | ✅ Tracked | Default mrbgem (if missing) |
| | | `mrbgems/App/mrblib/` | ✅ Tracked | Ruby code directory |
| | | `mrbgems/App/src/` | ✅ Tracked | C extension directory |
| | | `mrbgems/App/mrbgem.rake` | ✅ Tracked | mrbgem configuration |
| | | `mrbgems/App/mrblib/app.rb` | ✅ Tracked | Default Ruby class |
| | | `mrbgems/App/src/app.c` | ✅ Tracked | Default C extension |
| | | `mrbgems/App/README.md` | ✅ Tracked | mrbgem documentation |
| **ptrk env set** | `Build.generate_build_config_patch` | `patch/picoruby/build_config/xtensa-esp.rb` | ✅ Tracked | PicoRuby build config patch |
| **ptrk env set** | `Build.generate_cmake_patch` | `patch/picoruby-esp32/CMakeLists.txt` | ✅ Tracked | CMake patch for App gem |
| **ptrk env patch_export** | `Patch.export_repo_changes` | `patch/{repo_name}/{file-path}` | ✅ Tracked | User modifications |
| **ptrk mrbgem generate** | `Mrbgems.prepare_directory` | `mrbgems/{NAME}/` | ✅ Tracked | Custom mrbgem |
| | | `mrbgems/{NAME}/mrblib/` | ✅ Tracked | Ruby code |
| | | `mrbgems/{NAME}/src/` | ✅ Tracked | C extension |
| | | `mrbgems/{NAME}/mrbgem.rake` | ✅ Tracked | Configuration |
| | | `mrbgems/{NAME}/mrblib/{name}.rb` | ✅ Tracked | Ruby module |
| | | `mrbgems/{NAME}/src/{name}.c` | ✅ Tracked | C code |
| | | `mrbgems/{NAME}/README.md` | ✅ Tracked | Documentation |
| **ptrk rubocop setup** | `Rubocop.setup` | `.rubocop.yml` | ✅ Tracked | RuboCop config |
| | | `lib/rubocop/cop/picoruby/` | ✅ Tracked | Custom cops |
| | | `scripts/update_methods.rb` | ✅ Tracked | Method database update script |
| | | `data/picoruby_*_methods.json` | ✅ Tracked | Method databases |

---

## Template Inventory

### Template Files (Packaged with picotorokko gem)

All templates located at: `lib/ptrk/templates/`

#### mrbgem Templates

| Template File | Variables | Purpose | Used By |
|--------------|-----------|---------|----------|
| `mrbgem_app/mrbgem.rake.erb` | `mrbgem_name`, `author_name` | mrbgem configuration | `ptrk mrbgem generate` |
| `mrbgem_app/mrblib/app.rb.erb` | `class_name` | Ruby class definition | `ptrk mrbgem generate` |
| `mrbgem_app/src/app.c.erb` | `class_name`, `c_prefix` | C extension skeleton | `ptrk mrbgem generate` |
| `mrbgem_app/README.md.erb` | `mrbgem_name`, `class_name`, `c_prefix` | Documentation template | `ptrk mrbgem generate` |

#### Other Templates

| Template File | Variables | Purpose | Used By |
|--------------|-----------|---------|----------|
| `rubocop/` | None | RuboCop configuration files | `ptrk rubocop setup` |
| `github-actions/esp32-build.yml` | None | CI workflow template | `ptrk ci setup` |

### Variable Substitution Examples

**Input**: `ptrk mrbgem generate MyApp --author "Alice"`

**Variables computed**:
- `mrbgem_name` = "MyApp"
- `class_name` = "MyApp"
- `c_prefix` = "myapp" (lowercase)
- `author_name` = "Alice"

**Example output** (`mrbgem.rake.erb`):
```ruby
MRuby::Gem::Specification.new('MyApp') do |spec|
  spec.license = 'MIT'
  spec.author  = 'Alice'
  spec.summary = 'Application-specific mrbgem'
end
```

---

## Template Strategy: AST-Based Template Engine

### Current Approach (ERB)

**Implementation**: `lib/pra/commands/mrbgems.rb:65-70`

```ruby
template_content = File.read(template_path, encoding: "UTF-8")
erb = ERB.new(template_content, trim_mode: "-")
rendered_content = erb.result(binding_context)
File.write(output_path, rendered_content, encoding: "UTF-8")
```

**Pros**:
- ✅ Simple, well-known pattern
- ✅ Works with any text format (Ruby, C, YAML, Markdown)
- ✅ Standard library (no dependencies)

**Cons**:
- ❌ String interpolation breaks syntax validity (templates aren't valid Ruby/YAML)
- ❌ No semantic understanding of code structure
- ❌ Fragile: whitespace-sensitive, easy to break syntax
- ❌ No type safety or validation
- ❌ Hard to maintain: templates look like code but aren't parseable
- ❌ No IDE support (syntax highlighting breaks)

### Proposed Approach: Parse → Modify → Dump

**Philosophy**: Templates should be valid, parseable code in their target language. Modifications happen at the AST/semantic level, not string level.

**Benefits**:
- ✅ Templates are valid code (can be syntax-checked, formatted, linted)
- ✅ IDE support works (syntax highlighting, completion, validation)
- ✅ Semantic understanding enables powerful transformations
- ✅ Type-safe modifications (can't accidentally break syntax)
- ✅ Easier to test (can parse and verify template validity)
- ✅ Follows Ruby 3.4+ ecosystem direction (Prism as standard parser)

### Architecture Design

#### 1. Template Engine Interface

```ruby
module Ptrk
  module Template
    # Unified template rendering interface
    class Engine
      def self.render(template_path, variables)
        engine = select_engine(template_path)
        engine.new(template_path, variables).render
      end

      private

      def self.select_engine(template_path)
        case File.extname(template_path)
        when '.rb', '.rake' then RubyTemplateEngine
        when '.yml', '.yaml' then YamlTemplateEngine
        when '.c', '.h'      then CTemplateEngine
        else                      StringTemplateEngine  # Fallback for Markdown, etc.
        end
      end
    end
  end
end
```

#### 2. Ruby Template Engine (Prism-based)

**Template Annotation Strategy**:

**✅ DECISION: Option A (Placeholder Constants)** — Adopted

**Critical Requirement**: Templates MUST be valid Ruby code before substitution.

```ruby
# Template: lib/ptrk/templates/mrbgem_app/mrblib/app.rb
# ✅ This code is valid Ruby (TEMPLATE_* are uninitialized constants, but parseable)
class TEMPLATE_CLASS_NAME
  def version
    TEMPLATE_VERSION
  end
end
```

**Why Option A**:
- ✅ Prism can detect `ConstantReadNode` easily
- ✅ Template remains valid Ruby syntax (constants are parseable)
- ✅ Simple implementation (visitor pattern)
- ✅ No runtime evaluation needed

~~Option B: **Comment Annotations**~~ (Rejected)
```ruby
# @ptrk_template: class_name
class TemplateClassName
  # @ptrk_template: version
  def version
    100
  end
end
```
Reason for rejection: More complex parsing, no clear advantage over Option A

**Implementation** (Option A: Placeholder Constants):

```ruby
module Ptrk
  module Template
    class RubyTemplateEngine
      def initialize(template_path, variables)
        @template_path = template_path
        @variables = variables
      end

      def render
        source = File.read(@template_path)
        result = Prism.parse(source)

        # Find all TEMPLATE_* placeholders and their locations
        visitor = PlaceholderVisitor.new(@variables)
        result.value.accept(visitor)

        # Replace placeholders (reverse order to preserve offsets)
        output = source.dup
        visitor.replacements.reverse_each do |replacement|
          output[replacement[:range]] = replacement[:new_value]
        end

        output
      end
    end

    # Visitor to detect TEMPLATE_* placeholders
    class PlaceholderVisitor < Prism::Visitor
      attr_reader :replacements

      def initialize(variables)
        super()
        @variables = variables
        @replacements = []
      end

      def visit_constant_read_node(node)
        # Match TEMPLATE_* pattern
        const_name = node.name.to_s
        if const_name.start_with?('TEMPLATE_')
          var_name = const_name.sub(/^TEMPLATE_/, '').downcase.to_sym

          if @variables.key?(var_name)
            @replacements << {
              range: node.location.start_offset...node.location.end_offset,
              old_value: const_name,
              new_value: @variables[var_name].to_s
            }
          end
        end

        super
      end
    end
  end
end
```

**Example Usage**:

```ruby
# Template file: lib/ptrk/templates/mrbgem_app/mrblib/app.rb
class TEMPLATE_CLASS_NAME
  def version
    TEMPLATE_VERSION
  end
end

# Rendering:
variables = { class_name: 'MyApp', version: 100 }
output = Ptrk::Template::Engine.render('app.rb', variables)

# Output:
# class MyApp
#   def version
#     100
#   end
# end
```

#### 3. YAML Template Engine (Psych-based)

**Challenge**: Psych does NOT preserve comments during round-trip (parse → modify → dump).

**✅ DECISION: Option A (Special Placeholder Keys)** — Adopted

**Trade-off Accepted**: YAML comments will be lost during template rendering. This is acceptable for picotorokko use cases (GitHub Actions workflow templates).

```yaml
# Template: docs/github-actions/esp32-build.yml
# ⚠️ NOTE: Comments in template files will NOT be preserved in output
name: __PTRK_TEMPLATE_WORKFLOW_NAME__
on:
  push:
    branches:
      - __PTRK_TEMPLATE_MAIN_BRANCH__
```

**Why Option A**:
- ✅ No external dependencies (Psych is stdlib)
- ✅ Simple implementation
- ✅ Comments not critical for GitHub Actions YAML (structure is self-documenting)
- ✅ Template remains valid YAML

Implementation:
```ruby
class YamlTemplateEngine
  def render
    yaml = YAML.load_file(@template_path)

    # Recursively replace __PTRK_TEMPLATE_*__ placeholders
    replace_placeholders!(yaml, @variables)

    YAML.dump(yaml)
  end

  private

  def replace_placeholders!(obj, variables)
    case obj
    when Hash
      obj.transform_values! { |v| replace_placeholders!(v, variables) }
    when Array
      obj.map! { |v| replace_placeholders!(v, variables) }
    when String
      if obj.start_with?('__PTRK_TEMPLATE_') && obj.end_with?('__')
        var_name = obj[16..-3].downcase.to_sym  # Extract variable name
        variables.fetch(var_name, obj)
      else
        obj
      end
    else
      obj
    end
  end
end
```

~~**Option B: External Gem for Comment Preservation**~~ (Rejected)
- `yamllint-rb` - May preserve comments?
- `ya2yaml` - Alternative YAML library
- Custom parser using Psych + manual comment tracking

Reason for rejection: Additional dependencies not justified for this use case

~~**Option C: Hybrid Approach**~~ (Rejected)
- Use Psych for structure
- Preserve specific comment blocks using ERB-like markers
- Requires custom parser

Reason for rejection: Too complex for limited benefit

#### 4. C Template Engine

**Challenge**: No standard C parser in Ruby stdlib.

**✅ DECISION: Option A (String Placeholder Replacement)** — Adopted

**Critical Requirement**: Templates MUST be valid C code before substitution.

```c
// Template: lib/ptrk/templates/mrbgem_app/src/app.c
// ✅ Valid C code (TEMPLATE_* are treated as identifiers)
void mrbc_TEMPLATE_C_PREFIX_init(mrbc_vm *vm) {
  mrbc_class *TEMPLATE_C_PREFIX_class =
    mrbc_define_class(vm, "TEMPLATE_CLASS_NAME", mrbc_class_object);
}
```

**Why Option A**:
- ✅ C templates are simple (function names, class names only)
- ✅ No AST parsing needed for this limited use case
- ✅ No external dependencies
- ✅ Template remains valid C syntax (identifiers are valid)

Simple string replacement:
```ruby
class CTemplateEngine
  def render
    source = File.read(@template_path)

    @variables.each do |key, value|
      placeholder = "TEMPLATE_#{key.to_s.upcase}"
      source.gsub!(placeholder, value.to_s)
    end

    source
  end
end
```

~~**Option B: tree-sitter-c gem**~~ (Rejected)
- Pros: Full C AST parsing, semantic modifications
- Cons: Additional gem dependency, complexity, native extensions

Reason for rejection: Overkill for simple identifier substitution

### Migration Strategy

**✅ DECISION: Complete Migration after picotorokko Refactoring**

**Timing**: Independent task, executed AFTER picotorokko (pra → ptrk) refactoring is complete.

**Phase 1: Proof of Concept** (Validation)
1. Implement `Ptrk::Template::Engine` module
2. Create `RubyTemplateEngine` with Prism
3. Convert ONE template (e.g., `mrblib/app.rb.erb` → `mrblib/app.rb`)
4. Add tests for template rendering
5. Validate: Template validity before/after substitution
6. **Quality Gate**: PoC must pass all tests and maintain RuboCop compliance

**Phase 2: Complete Rollout** (No parallel operation)
1. Convert ALL Ruby templates (`.rb.erb` → `.rb`)
2. Convert ALL Rake templates (`.rake.erb` → `.rake`)
3. Convert ALL YAML templates (`.yml.erb` → `.yml`)
4. Convert ALL C templates (`.c.erb` → `.c`)
5. Update `lib/ptrk/commands/mrbgems.rb` to use new engine
6. Update all template generation code

**Phase 3: ERB Removal** (Immediate)
1. Delete ALL `.erb` files (no preservation)
2. Remove `require "erb"` from codebase
3. Update documentation
4. Update tests to reflect new template system

**No Hybrid Period**: ERB will be completely removed after Phase 2 completion.

### Web Search Strategy

When implementing this feature, research the following topics:

#### Prism (Ruby AST)

**Search Queries**:
1. "Prism ruby unparse AST to source code"
   - Goal: Find if Prism has built-in AST → source code conversion
   - Alternative: RuboCop's `RuboCop::AST::ProcessedSource`

2. "Prism preserve comments round trip"
   - Goal: Verify comment preservation during parse → modify → dump
   - Check: `Prism::ParseResult#comments` API

3. "Ruby 3.4 Prism location offset API"
   - Goal: Confirm location-based string replacement strategy
   - Verify: `Prism::Node#location.start_offset`, `end_offset`

4. "Prism AST node replacement Ruby"
   - Goal: Find examples of AST node modification patterns
   - Alternative: Learn from RuboCop autocorrect implementation

#### YAML Comment Preservation

**Search Queries**:
1. "Psych YAML preserve comments round trip Ruby"
   - Goal: Check if newer Psych versions support comment preservation
   - Check: Ruby 3.4+ stdlib updates

2. "ya2yaml gem comment preservation"
   - Goal: Evaluate alternative YAML library
   - Check: Maintenance status, compatibility

3. "YAML AST manipulation Ruby"
   - Goal: Find YAML parsing libraries with AST support
   - Alternative: Custom Psych + comment tracking

4. "yamllint Ruby preserve comments"
   - Goal: Check if yamllint-rb has parsing capabilities
   - Evaluate: Performance, API usability

#### C Code Generation

**Search Queries**:
1. "tree-sitter-c Ruby gem"
   - Goal: Evaluate C AST parsing option
   - Check: Installation complexity, dependencies

2. "C code generation template Ruby"
   - Goal: Find existing C template patterns in Ruby ecosystem
   - Learn: Best practices from other projects

3. "Ruby C extension code generation"
   - Goal: Find examples from mruby/mrubyc ecosystem
   - Learn: Common patterns, pitfalls

#### Alternative Template Engines

**Search Queries**:
1. "AST-based template engine Ruby"
   - Goal: Check if similar approaches exist
   - Avoid: Reinventing the wheel

2. "semantic code generation Ruby"
   - Goal: Find research on code generation best practices
   - Learn: Industry patterns

3. "Prism visitor pattern examples Ruby"
   - Goal: Learn from existing Prism usage in gems
   - Check: RuboCop, Steep, other static analysis tools

### Implementation Knowledge Base

#### Prism Basics

**AST Node Types** (relevant to templates):
- `Prism::ConstantReadNode` - Constant references (e.g., `TEMPLATE_CLASS_NAME`)
- `Prism::StringNode` - String literals
- `Prism::InterpolatedStringNode` - String interpolation (avoid in templates)
- `Prism::CallNode` - Method calls
- `Prism::CommentNode` - Comments (accessed via `parse_result.comments`)

**Location API**:
```ruby
result = Prism.parse(source)
node = result.value  # Root node

# Get source code range
location = node.location
start_offset = location.start_offset
end_offset = location.end_offset
source_slice = source[start_offset...end_offset]

# Line/column info
start_line = location.start_line
start_column = location.start_column
```

**Visitor Pattern**:
```ruby
class MyVisitor < Prism::Visitor
  def visit_constant_read_node(node)
    puts "Found constant: #{node.name}"
    super  # Continue traversal
  end
end

result = Prism.parse(source)
visitor = MyVisitor.new
result.value.accept(visitor)
```

#### Psych (YAML) Basics

**Round-trip without comments**:
```ruby
yaml = YAML.load_file('template.yml')
# Modify yaml hash
yaml['name'] = 'New Value'
YAML.dump(yaml, File.open('output.yml', 'w'))
# Comments are LOST
```

**Preserving structure**:
```ruby
# Use specific YAML options
YAML.dump(yaml,
  line_width: -1,        # No line wrapping
  indentation: 2,        # 2-space indent
  canonical: false       # Don't use canonical form
)
```

#### String Replacement Strategy

**Safe offset-based replacement** (for Prism results):
```ruby
# Collect all replacements first
replacements = []
visitor.replacements.each do |r|
  replacements << r
end

# Sort by start offset (descending) to preserve offsets
replacements.sort_by! { |r| -r[:range].begin }

# Apply replacements
output = source.dup
replacements.each do |r|
  output[r[:range]] = r[:new_value]
end
```

### Testing Strategy

**Template Validity Tests**:
```ruby
def test_template_is_valid_ruby
  template_path = 'lib/ptrk/templates/mrbgem_app/mrblib/app.rb'
  source = File.read(template_path)

  result = Prism.parse(source)
  assert result.success?, "Template must be valid Ruby code"
  assert result.errors.empty?, "Template has syntax errors"
end
```

**Template Rendering Tests**:
```ruby
def test_renders_ruby_template
  variables = { class_name: 'MyApp', version: 100 }
  output = Ptrk::Template::Engine.render('app.rb', variables)

  # Verify output is valid Ruby
  result = Prism.parse(output)
  assert result.success?

  # Verify placeholders replaced
  refute output.include?('TEMPLATE_CLASS_NAME')
  assert output.include?('class MyApp')
end
```

**Placeholder Detection Tests**:
```ruby
def test_detects_all_placeholders
  source = <<~RUBY
    class TEMPLATE_CLASS_NAME
      TEMPLATE_VERSION
    end
  RUBY

  result = Prism.parse(source)
  visitor = PlaceholderVisitor.new({})
  result.value.accept(visitor)

  assert_equal 2, visitor.replacements.size
end
```

### Benefits Summary

| Aspect | ERB | AST-Based |
|--------|-----|-----------|
| Template validity | ❌ Not parseable | ✅ Valid code |
| IDE support | ❌ Syntax highlighting breaks | ✅ Full IDE support |
| Type safety | ❌ String manipulation | ✅ Semantic understanding |
| Maintainability | ❌ Fragile | ✅ Robust |
| Dependencies | ✅ Stdlib only | ✅ Prism (stdlib in 3.4+) |
| Learning curve | ✅ Simple | ⚠️ Moderate (Prism API) |
| Performance | ✅ Fast | ✅ Fast (Prism is optimized) |

### Decision: When to Use Each Approach

**Use AST-Based**:
- ✅ Ruby templates (`.rb`, `.rake`)
- ✅ When template validity matters (linting, IDE support)
- ✅ When semantic modifications needed (rename class, change structure)
- ✅ For long-term maintainability

**Keep ERB**:
- ✅ Markdown templates (no parser available)
- ✅ Simple one-off text files
- ✅ When migration cost outweighs benefits

**Hybrid for YAML**:
- ⚠️ Depends on comment preservation requirements
- ⚠️ If comments not critical: Use Psych + placeholder keys
- ⚠️ If comments critical: Keep ERB or research ya2yaml gem

### Implementation Decisions Summary

| Decision Point | Choice | Rationale |
|----------------|--------|-----------|
| **Proceed with migration?** | ✅ Yes | Benefits justify migration cost |
| **Timing** | After picotorokko refactoring | Independent work, non-blocking |
| **Ruby templates** | Placeholder Constants | Simple, Prism-friendly, valid syntax |
| **YAML templates** | Special placeholder keys, no comments | Psych limitation accepted |
| **C templates** | String replacement | Sufficient for simple use case |
| **ERB removal** | Complete (no hybrid) | Clean cut, no technical debt |
| **Template validity** | **MANDATORY** | Templates must parse before substitution |

### Next Steps (Implementation Phase)

**Prerequisites**:
1. ✅ picotorokko refactoring MUST be complete
2. ✅ All tests passing, RuboCop clean
3. ✅ Branch: picotorokko merged to main

**Execution**:
1. **Research** (1-2 days): Execute web searches for Prism unparse capabilities
2. **Prototype** (2-3 days): Implement `RubyTemplateEngine` for ONE template
3. **Validate** (1 day): Verify template validity, test coverage, RuboCop compliance
4. **Full Rollout** (3-5 days): Convert all templates, update commands
5. **ERB Removal** (1 day): Delete .erb files, update docs
6. **Quality Verification** (1 day): Full test suite, coverage, RuboCop

**Estimated Total Effort**: 8-12 days

**Status**: ✅ Approved for Implementation (Post-picotorokko)

---

## Test Strategy

### Design Principle: Two Project Roots

Tests must maintain strict separation:

#### gem Development Root (picotorokko)
```
/path/to/picotorokko/
├── lib/ptrk/
├── test/
├── .rubocop.yml
└── ...
```

**Requirement**: Tests must NOT create files here

#### Test User's Project Root
```
/tmp/ptrk_test_xxxxx/
├── ptrk_env/
├── patch/
├── mrbgems/
└── storage/
```

**Requirement**: Tests create and clean up files here

### Test Implementation Pattern

```ruby
# test/test_helper.rb

class PraTestCase < Test::Unit::TestCase
  def setup
    @original_dir = Dir.pwd
    @ptrk_user_root = Dir.mktmpdir("ptrk_test")
    Dir.chdir(@ptrk_user_root)
    # Now Dir.pwd points to ptrk_user_root
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@ptrk_user_root) if @ptrk_user_root
    verify_gem_root_clean!
  end

  # Verify gem development directory wasn't polluted
  private

  def verify_gem_root_clean!
    gem_root = File.expand_path("../..", __dir__)
    forbidden_dirs = %w[ptrk_env patch mrbgems storage]

    forbidden_dirs.each do |dir|
      path = File.join(gem_root, dir)
      refute Dir.exist?(path),
        "Test leaked into gem root: #{dir}/ created at #{path}"
    end
  end
end
```

### Test Examples

```ruby
# test/commands/env_test.rb

class EnvTest < PraTestCase
  def test_set_creates_environment_directory
    Ptrk::Commands::Env.start(['set', 'development'])

    assert Dir.exist?(File.join(@ptrk_user_root, 'ptrk_env', 'development'))
    assert File.exist?(File.join(@ptrk_user_root, 'ptrk_env', '.picoruby-env.yml'))
  end

  def test_device_build_with_explicit_env_name
    Ptrk::Commands::Env.start(['set', 'production'])
    # Would normally execute build, but we mock the Rakefile
    Ptrk::Commands::Device.start(['build', 'production'])
    # Verify correct directory was used
  end

  def test_gem_root_remains_clean
    # This test executes in temp directory
    # verify_gem_root_clean! is called in teardown
    # If any files leak to gem root, test fails
  end
end
```

### Coverage Requirements

- **Line coverage**: ≥ 90%
- **Branch coverage**: ≥ 60%
- **RuboCop compliance**: 0 violations
- **Gem root cleanliness**: 100% (no files leaked)

---

## Implementation Checklist

### Phase 1: Planning & Documentation (CURRENT)
- [x] Analyze current command structure
- [x] Investigate naming options
- [x] Create detailed refactoring specification
- [ ] Update TODO.md with phased breakdown

### Phase 2: Rename & Constants (Estimated: 2-3 days)
- [ ] Update `ptrk.gemspec` (name, executables)
- [ ] Rename `bin/pra` → `bin/ptrk`
- [ ] Create/update `lib/ptrk/env.rb` with new constants
- [ ] Add constant reference in `CLAUDE.md` (ptrk command name subject to change)
- [ ] Update `lib/ptrk/cli.rb` (command registration)
- [ ] Run RuboCop, fix violations
- [ ] Commit: "chore: rename pra → picotorokko, command → ptrk"

### Phase 3: Command Structure (Estimated: 4-5 days)
- [ ] Refactor `lib/ptrk/commands/env.rb`
  - [ ] Add `set` with commit/branch options
  - [ ] Enhance `show` with version details
  - [ ] Add `reset` for environment reconstruction
  - [ ] Move patch operations: `patch_export`, `patch_apply`, `patch_diff`
  - [ ] Implement `list` with environment overview
- [ ] Delete `lib/ptrk/commands/cache.rb`
- [ ] Delete `lib/ptrk/commands/build.rb` (logic moves to env.rb)
- [ ] Delete `lib/ptrk/commands/patch.rb` (logic moves to env.rb)
- [ ] Update `lib/ptrk/commands/device.rb` to use env names (no implicit current)
- [ ] Add environment name validation to all commands
- [ ] Run RuboCop, fix violations
- [ ] Commit per major logical change

### Phase 4: Directory Structure (Estimated: 3-4 days)
- [ ] Update `lib/ptrk/env.rb` path logic
  - [ ] Replace `.cache/` with `ptrk_env/.cache/`
  - [ ] Replace `build/` with `ptrk_env/{env_name}/`
  - [ ] Replace `.picoruby-env.yml` with `ptrk_env/.picoruby-env.yml`
  - [ ] Remove `current` symlink logic
- [ ] Implement directory initialization in `ptrk env set`
- [ ] Add validation for env names (regex)
- [ ] Run full test suite locally
- [ ] Commit: "refactor: consolidate directories into ptrk_env/"

### Phase 5: Test Updates (Estimated: 5-6 days)
- [ ] Update `test/test_helper.rb`
  - [ ] Change to use temp `ptrk_user_root`
  - [ ] Add `verify_gem_root_clean!` check
- [ ] Rewrite `test/commands/env_test.rb` (new structure)
- [ ] Delete `test/commands/cache_test.rb`
- [ ] Delete `test/commands/build_test.rb`
- [ ] Delete `test/commands/patch_test.rb`
- [ ] Update `test/commands/device_test.rb` (env names required)
- [ ] Run `bundle exec rake test` - all passing
- [ ] Verify coverage ≥ 90% line, ≥ 60% branch
- [ ] Run `bundle exec rubocop` - 0 violations
- [ ] Commit: "test: update and consolidate test suite"

### Phase 6: Documentation & Finalization (Estimated: 3-4 days)
- [ ] Update `README.md`
  - [ ] Rename all `pra` → `ptrk` references
  - [ ] Update command examples
  - [ ] Update installation instructions
- [ ] Update `.gitignore`
- [ ] Update `CLAUDE.md` project instructions
- [ ] Update all docs in `docs/`
- [ ] Add CHANGELOG entry
- [ ] Run final test suite: `bundle exec rake ci`
- [ ] Verify all quality gates pass
- [ ] Commit: "docs: update for picotorokko refactoring"

### Final Quality Verification
- [ ] `bundle exec rake test` - All tests pass (exit 0)
- [ ] `bundle exec rubocop` - 0 violations (exit 0)
- [ ] SimpleCov coverage report - ≥ 90% line (exit 0)
- [ ] No files in gem root (only ptrk_user_root used)
- [ ] All commits have clear messages

---

## Migration Guide (Future Reference)

This section is for **future use only**, if/when picotorokko becomes publicly available and needs to support user migration.

### For Users Upgrading picotorokko gem

If a future version adds migration tooling:

```bash
# Backup current setup (pre-migration)
git stash
cp -r build/ build.backup/
cp .picoruby-env.yml .picoruby-env.yml.backup/
cp .cache/ .cache.backup/

# Run migration helper (hypothetical future command)
ptrk migrate --from-pra

# Verify
ls -la ptrk_env/

# Cleanup old files
rm -rf build/ .cache/
rm .picoruby-env.yml

# Commit
git add .
git commit -m "Migrate to picotorokko (ptrk)"
```

### Manual Migration Steps (If needed)

1. **Back up everything**
   ```bash
   git stash  # Stash any uncommitted work
   cp -r .cache/ .cache.backup/
   cp -r build/ build.backup/
   cp .picoruby-env.yml .picoruby-env.yml.backup/
   ```

2. **Create new structure**
   ```bash
   ptrk env set development        # Creates ptrk_env/development/
   ptrk env set production         # Creates ptrk_env/production/
   ```

3. **Copy patches (if using)**
   ```bash
   # Your patches should already be in patch/
   # Just verify they're in Git
   git status patch/
   ```

4. **Verify everything works**
   ```bash
   ptrk env show development
   ptrk device build development
   ```

5. **Clean up old directories**
   ```bash
   rm -rf .cache/ build/ .picoruby-env.yml
   ```

6. **Commit**
   ```bash
   git add -A
   git commit -m "Migrate to picotorokko structure"
   ```

---

## Appendix: Comparison Reference

### Command Mapping (Old → New)

| Old Command | New Command | Notes |
|-----------|-----------|-------|
| `pra env show` | `ptrk env show (env)` | Now shows version details |
| `pra env set` | `ptrk env set (env)` | Now accepts commit/branch options |
| `pra env latest` | `ptrk env set (env)` | Implicit (uses main by default) |
| `pra cache list` | N/A | Auto-managed, not needed |
| `pra cache fetch` | Part of `ptrk env set` | Auto-fetches to cache |
| `pra cache clean` | N/A | Delete `ptrk_env/.cache/{repo}` manually |
| `pra cache prune` | N/A | Unused with new design |
| `pra build setup` | `ptrk env set (env)` | Automatic |
| `pra build clean` | Manual deletion | `rm -rf ptrk_env/{env}` |
| `pra build list` | `ptrk env` | Shows environment overview |
| `pra patch export` | `ptrk env patch_export (env)` | Moved under env |
| `pra patch apply` | `ptrk env patch_apply (env)` | Moved under env |
| `pra patch diff` | `ptrk env patch_diff (env)` | Moved under env |
| `pra device build` | `ptrk device build [env]` | Env name explicit (default: development) |
| `pra device flash` | `ptrk device flash [env]` | Same |
| `pra device monitor` | `ptrk device monitor [env]` | Same |
| `pra mrbgems generate` | `ptrk mrbgem generate` | Same |
| `pra rubocop setup` | `ptrk rubocop setup` | Same |

### Directory Mapping (Old → New)

| Old Path | New Path | Reason |
|----------|----------|--------|
| `.cache/` | `ptrk_env/.cache/` | Consolidation |
| `.picoruby-env.yml` | `ptrk_env/.picoruby-env.yml` | Consolidation |
| `build/{env-hash}/` | `ptrk_env/{env-name}/` | Use env names, not hashes |
| `build/current` | N/A | Removed (use explicit env names) |
| `patch/` | `patch/` | Unchanged |
| `mrbgems/` | `mrbgems/` | Unchanged |
| `storage/home/` | `storage/home/` | Unchanged |

---

## Document Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2024-11-09 | 1.0 | Initial specification |

---

**Document Status**: ✅ Approved for Implementation

**Next Steps**: Begin Phase 2 (Rename & Constants) after team review
