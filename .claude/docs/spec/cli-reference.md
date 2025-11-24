# CLI Commands Reference

Complete reference for `pra` CLI commands, configuration, and workflows.

---

## Environment Inspection Commands

### `ptrk env show`

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

### `ptrk env current [ENV_NAME]`

**Description**: Get or set current environment

**Arguments**:
- `ENV_NAME` (optional) - Environment name to set as current

**Operation**:
- Without argument: Show current environment name
- With argument: Set specified environment as current (must exist in `.picoruby-env.yml`)

**Example**:
```bash
# Show current environment
ptrk env current
# => Current environment: 20251121_150000

# Set current environment
ptrk env current 20251121_180000
# => ✓ Current environment set to: 20251121_180000
```

---

### `ptrk env set ENV_NAME`

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

### `ptrk env set --latest`

**Description**: Fetch latest versions and clone with submodule rewriting

**Operation**:
1. Fetch HEAD commits from R2P2-ESP32, picoruby-esp32, picoruby via `git ls-remote`
2. Generate env-name from timestamp (`YYYYMMDD_HHMMSS` format)
3. Save environment definition to `.picoruby-env.yml`
4. Clone R2P2-ESP32 with `--filter=blob:none` to `.ptrk_env/{env_name}/`
5. Checkout to specified R2P2-ESP32 commit
6. Initialize submodules: `git submodule update --init --recursive --jobs 4`
7. Checkout picoruby-esp32 to specified commit
8. Checkout picoruby (nested submodule) to specified commit
9. Stage submodule changes: `git add components/picoruby-esp32`
10. Amend commit: `git commit --amend -m "ptrk env: {env_name}"`
11. Disable push on all repos: `git remote set-url --push origin no_push`

**Example**:
```bash
ptrk env set --latest
# => Fetching latest commits from GitHub...
#      Checking R2P2-ESP32...
#      Checking picoruby-esp32...
#      Checking picoruby...
#
#    Saving as environment definition '20251121_143045' in .picoruby-env.yml...
#    ✓ Environment definition '20251121_143045' created successfully
#
#    Cloning R2P2-ESP32 to .ptrk_env/20251121_143045/...
#      ✓ R2P2-ESP32 cloned and checked out to abc1234
#      ✓ picoruby-esp32 checked out to def5678
#      ✓ picoruby checked out to ghi9012
#      ✓ Push disabled on all repositories
```

---

## R2P2-ESP32 Task Delegation Commands

**Note**: The `ptrk build` command has been removed to avoid conflict with Build Environment Management commands. Use `rake build` directly in the R2P2-ESP32 directory instead.

### `pra flash [ENV_NAME]`

**Description**: Flash built firmware to ESP32

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Operation**:
1. cd into `build/{env}/R2P2-ESP32/`
2. Setup ESP-IDF environment variables
3. Execute `rake flash` in R2P2-ESP32's `Rakefile`

---

### `pra monitor [ENV_NAME]`

**Description**: Monitor ESP32 serial output

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Operation**:
1. cd into `build/{env}/R2P2-ESP32/`
2. Setup ESP-IDF environment variables
3. Execute `rake monitor` in R2P2-ESP32's `Rakefile`

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
pra flash
pra monitor

# Ctrl+C to exit
```

### Scenario 2: Validate Latest Version

```bash
# 1. Fetch latest version and create environment
ptrk env set --latest
# => Fetching latest from GitHub...
#    Created environment: 20251121_150000
#    Cloning R2P2-ESP32 with submodules...
#    ✓ Environment '20251121_150000' created successfully

# 2. Set as current and build
ptrk env current 20251121_150000
ptrk device build

# 3. If issues found, revert to previous
ptrk env current 20251120_120000
ptrk device build
```

### Scenario 3: Patch Management

```bash
# 1. Prepare build workspace
ptrk device prepare

# 2. Make changes in .ptrk_build/{env}/R2P2-ESP32/
# (edit files)

# 3. Review changes
ptrk patch diff

# 4. Export changes to patch
ptrk patch export

# 5. Git commit
git add .ptrk_env/*/patch/ storage/home/
git commit -m "Update patches and storage"

# 6. Test application in another environment
ptrk env current 20251121_103000
ptrk device prepare  # patches auto-applied
ptrk device build
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
# List available patches
ptrk patch list

# Check working changes
ptrk patch diff

# Re-prepare workspace (patches auto-applied)
ptrk device prepare
ptrk device build
```
