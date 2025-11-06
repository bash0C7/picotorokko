# Patch Management Commands

The patch system allows git-managed changes to be persisted and applied across environments.

---

## `pra patch export [ENV_NAME]`

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

pra patch export
# => Exporting changes from build/current/
#    patch/R2P2-ESP32/storage/home/custom.rb (created)
#    patch/picoruby-esp32/ (no changes)
#    patch/picoruby/ (no changes)
#    Done!
```

---

## `pra patch apply [ENV_NAME]`

**Description**: Apply `patch/` to `build/{env}/`

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Operation**:
1. Read all files under `patch/R2P2-ESP32/`
2. Copy to corresponding paths in `build/{env}/R2P2-ESP32/`
3. Create directory structure if different
4. Same process for `components/picoruby-esp32/` and `picoruby/`

---

## `pra patch diff [ENV_NAME]`

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

## Patch Directory Structure

```
patch/
├── README.md
├── R2P2-ESP32/          # Directory hierarchy structure
│   └── storage/
│       └── home/
│           └── custom.rb
├── picoruby-esp32/
│   └── (if changed)
└── picoruby/
    └── (if changed)
```

Patches are git-managed and automatically applied during `pra build setup`.
