# Build Environment Management Commands

Build environments in `build/{env-hash}/` provide isolated working directories for each version combination.

---

## `pra build setup [ENV_NAME]`

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
pra build setup stable-2024-11
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

## `pra build clean [ENV_NAME]`

**Description**: Delete specified build environment

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Operation**:
1. If `build/current` is a symlink, read its target
2. If env_name is `current`, delete symlink target and clear `build/current`
3. Otherwise, delete specified environment

**Example**:
```bash
pra build clean development
# => Removing build/34a1c23-20241104_120000_f331744-20241104_115500_df21508-20241104_115000/
```

---

## `pra build list`

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

## env-hash Format

Build directories use a consistent naming format:

```
{R2P2-hash}_{esp32-hash}_{picoruby-hash}

Example:
  f500652-20241105_143022_6a6da3a-20241105_142015_e57c370-20241105_141030
```

- Three commit-hashes concatenated with `_`
- Order: R2P2-ESP32 → picoruby-esp32 → picoruby
- Each hash follows the commit-hash format: `{7-digit}-{YYYYMMDD_HHMMSS}`
