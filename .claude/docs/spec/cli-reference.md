# CLI Commands Reference

Complete reference for `pra` CLI commands, configuration, and workflows.

---

## Environment Inspection Commands

### `pra env show`

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

### `pra env set ENV_NAME`

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
pra env set development
# => Switching to development
#    build/current -> build/34a1c23-20241104_120000_f331744-20241104_115500_df21508-20241104_115000/
```

---

### `pra env latest`

**Description**: Fetch latest versions and switch to them

**Operation**:
1. Fetch HEAD commits from each repo via GitHub API or `git ls-remote`
2. Generate new environment name (e.g., `latest-20241105-143500`)
3. Save to `.cache` via `pra cache fetch`
4. Setup environment via `pra build setup`
5. Switch via `pra env set`

---

## R2P2-ESP32 Task Delegation Commands

**Note**: The `pra build` command has been removed to avoid conflict with Build Environment Management commands. Use `rake build` directly in the R2P2-ESP32 directory instead.

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
pra env show

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
# 1. Fetch latest version
pra env latest
# => Fetching latest from GitHub...
#    Created environment: latest-20241105-143500
#    Setting up environment...
#    Switched to: latest-20241105-143500

# 2. Build
cd build/current/R2P2-ESP32
rake build
cd ../../..

# 3. If issues found, revert to stable
pra env set stable-2024-11
cd build/current/R2P2-ESP32
rake build
cd ../../..
```

### Scenario 3: Patch Management

```bash
# 1. Make changes in build/current/
# (edit files)

# 2. Export changes to patch
pra patch export

# 3. Git commit
git add patch/ storage/home/
git commit -m "Update patches and storage"

# 4. Test application in another environment
pra env set development
pra build setup  # patches auto-applied
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
pra cache clean R2P2-ESP32
pra cache fetch latest
```

### Build Environment Missing

```bash
# Check cache
pra cache list

# Setup environment
pra build setup ENV_NAME
```

### Patches Not Applied

```bash
# Check diff
pra patch diff

# Re-apply
pra build clean
pra build setup ENV_NAME
```
