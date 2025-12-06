# Cache Management Commands

The cache system maintains immutable repository versions in `.cache/`, allowing version switching without re-downloading.

---

## `ptrk cache list`

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

## `ptrk cache fetch [ENV_NAME]`

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

## `ptrk cache clean REPO`

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

## `ptrk cache prune`

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
