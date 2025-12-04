# Patch Management Commands

The patch system allows git-managed changes to be persisted and applied across environments.

**Important**: Patches are automatically applied during `ptrk device build` or `ptrk device prepare`. There is no explicit `apply` command.

---

## `ptrk patch list`

**Description**: List all patch files in the project

**Example**:
```bash
ptrk patch list
# => Patches:
#      R2P2-ESP32/config.h
#      R2P2-ESP32/src/main.c
```

---

## `ptrk patch diff [ENV_NAME]`

**Description**: Display diff between current changes in `build/{env}/` and existing patches

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Example**:
```bash
ptrk patch diff
# => === Patch Differences ===
#    Environment: 20251124_120000
#
#    R2P2-ESP32:
#      Working changes: config.h
#      Stored patches: config.h, src/main.c
```

---

## `ptrk patch export [ENV_NAME]`

**Description**: Export changes from `.ptrk_build/{env}/` to `patch/`

**Arguments**:
- `ENV_NAME` - Environment name (default: `current`)

**Operation**:
1. Execute `git diff --name-only` in `.ptrk_build/{env}/R2P2-ESP32/`
2. For each modified file:
   - Recreate directory structure in `patch/R2P2-ESP32/`
   - Save diff to patch file
3. Same process for `components/picoruby-esp32/` and `picoruby/`

**Example**:
```bash
# After editing .ptrk_build/{env}/R2P2-ESP32/config.h

ptrk patch export
# => Exporting patches from: 20251124_120000
#      R2P2-ESP32: 1 file(s)
#        Exported: R2P2-ESP32/config.h
#    ✓ Patches exported
```

---

## Workflow

### Recommended: Iterative Development

```bash
# 1. Prepare build environment
ptrk device prepare

# 2. Edit files in .ptrk_build/{env}/R2P2-ESP32/
vim .ptrk_build/{env}/R2P2-ESP32/config.h

# 3. Export changes
ptrk patch export

# 4. Build (does not reset)
ptrk device build
```

### Alternative: Direct Creation

```bash
# Create patch file directly
mkdir -p patch/R2P2-ESP32
echo '#define VALUE 42' > patch/R2P2-ESP32/config.h

# Build applies patches automatically
ptrk device build
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

Patches are git-managed and automatically applied during `ptrk build setup`.
