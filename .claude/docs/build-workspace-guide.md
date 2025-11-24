# Build Workspace Guide

## Overview

A **build workspace** is the working directory where ESP32 firmware is actually built and flashed. It's located at `.ptrk_build/{env_name}/R2P2-ESP32/`.

### Directory Structure

```
project-root/
├── .ptrk_env/                                # Environment definitions (git-tracked)
│   ├── .picoruby-env.yml
│   └── {env_name}/
│       └── R2P2-ESP32/                      # Source repository (read-only)
│           ├── components/picoruby-esp32/
│           │   └── picoruby/
│           │       └── (placeholder for mrbgems)
│           └── storage/home/                 # Placeholder
│
├── .ptrk_build/                             # Build workspaces (git-ignored)
│   └── {env_name}/
│       └── R2P2-ESP32/                      # 👈 BUILD WORKSPACE (mutable, only build target)
│           ├── components/picoruby-esp32/
│           │   └── picoruby/
│           │       └── mrbgems/             # Custom gems (from project root)
│           │           └── my_gem/
│           │               ├── mrbgem.rake
│           │               └── src/custom.c
│           ├── storage/home/                 # Application code (from project root)
│           │   ├── app.rb
│           │   └── config.yml
│           ├── build/                        # ESP-IDF build output
│           └── (patched files from project root patch/)
│
├── storage/home/                            # Application code (source, git-tracked)
│   └── *.rb, *.yml, ...
├── mrbgems/                                 # Custom gems (source, git-tracked)
│   └── my_gem/
│       ├── mrbgem.rake
│       └── src/custom.c
└── patch/                                   # Customization patches (source, git-tracked)
    ├── R2P2-ESP32/
    ├── picoruby-esp32/
    └── picoruby/
```

**Key Points:**
- **Source**: `.ptrk_env/{env_name}/`, `storage/home/`, `mrbgems/`, `patch/` (git-tracked)
- **Build Target**: `.ptrk_build/{env_name}/R2P2-ESP32/` (git-ignored, mutable)
- **ENV Level** (`.ptrk_build/{env_name}/`): Only contains R2P2-ESP32 subdirectory
- **mrbgems Location**: Nested within R2P2-ESP32/components/picoruby-esp32/picoruby/mrbgems/

## Build Workspace Lifecycle

### 1. Environment Setup (via `ptrk device build` - automatic)

When `ptrk device build` is called, the build workspace is prepared:

```
Step 1: Copy .ptrk_env/{env_name}/R2P2-ESP32/ → .ptrk_build/{env_name}/R2P2-ESP32/
        (Copies source repositories as the base)

Step 2: Apply patches from project root patch/ directory
        (Overlays customizations onto source repos)

Step 3: Copy project-root/storage/home/ → R2P2-ESP32/storage/home/
        (Places application code in build target)

Step 4: Copy project-root/mrbgems/ → R2P2-ESP32/components/picoruby-esp32/picoruby/mrbgems/
        (Places custom Ruby modules in build target, ready for C compilation)
```

This **ENV → Patch → Storage → mrbgems** workflow ensures the build workspace contains
all project customizations properly layered.

### 2. Initial Setup (via `ptrk device build` with fresh workspace)

Occurs **only on first build** when `build/repos/esp32` directory is missing:

```bash
# (All setup steps above are executed automatically by ptrk device build)

# Then R2P2-ESP32 Rakefile runs:
cd .ptrk_build/{env_name}/R2P2-ESP32
. ~/esp/esp-idf/export.sh
export ESPBAUD=115200
rake setup_esp32
```

This builds:
- PicoRuby C components
- mrbgems dependencies
- ESP32-specific build artifacts

**Generated**: `build/repos/esp32/` directory (marks workspace as "set up")

### 3. Build & Flash (via `ptrk device build`, `ptrk device flash`)

On every build (after setup):

```bash
cd .ptrk_build/{env_name}/R2P2-ESP32
. ~/esp/esp-idf/export.sh
export ESPBAUD=115200
rake build        # Build firmware
rake flash        # Flash to device
rake monitor      # Monitor serial output
```

Artifacts are created in:
- `build/` — ESP-IDF build directory
- `build/repos/esp32/` — PicoRuby build cache (persists across builds for speed)

## Implementation Details

### Build Workspace Setup Flow

The `setup_build_environment` method in `lib/picotorokko/commands/env.rb` orchestrates the workspace preparation:

**Code Flow:**
```ruby
# Step 1: Copy ENV source to build directory
FileUtils.cp_r(env_path, build_path)

# Step 2: Apply patches from project root
apply_patches_to_build(build_path)  # Applies patch/ directory

# Step 3: Copy storage/home for application code
FileUtils.cp_r(storage_src, "#{build_path}/R2P2-ESP32/storage/home/")

# Step 4: Copy mrbgems to nested picoruby path
FileUtils.cp_r(mrbgems_src,
               "#{build_path}/R2P2-ESP32/components/picoruby-esp32/picoruby/mrbgems/")
```

**Critical Points:**
- Storage and mrbgems are **only** in R2P2-ESP32, **not** at ENV level
- mrbgems must be in nested path for CMakeLists.txt to discover C sources
- Patches apply to the copied R2P2-ESP32 directory (Step 2), before storage/mrbgems

### mrbgems Placement and C Source Integration

Custom Ruby gems in `project-root/mrbgems/my_gem/` are copied to:
```
.ptrk_build/{env_name}/R2P2-ESP32/
  └── components/picoruby-esp32/picoruby/mrbgems/my_gem/
      ├── mrbgem.rake
      └── src/custom.c
```

The **nested picoruby path** is essential because:
1. R2P2-ESP32's CMakeLists.txt expects mrbgems in this location
2. PicoRuby's build system scans for `src/*.c` files in each gem
3. C sources are automatically compiled into the PicoRuby runtime

**Design Note**: Future enhancement should auto-register mrbgems C sources in CMakeLists.txt.

### Patch Application Sources

Patches can come from two sources and are applied in order:

1. **`.ptrk_env/patch/{repo}/`** — Stored patches (checked into version control)
2. **`project-root/patch/{repo}/`** — Project-level patches (for local customizations)

Both sources overlay files onto the build target in the same order.

### Directory Change Pattern

Always use `Dir.chdir` with a block to ensure the original directory is restored:

```ruby
# ✅ CORRECT: Cleanup guaranteed
Dir.chdir(workspace_path) do
  execute_rake_task("build")
end
# Original directory automatically restored

# ❌ WRONG: May fail to restore if exception occurs
Dir.chdir(workspace_path)
execute_rake_task("build")
Dir.chdir(original_dir)
```

### ESP-IDF Environment Setup

Before any Rake task execution in the build workspace:

```bash
# 1. Source ESP-IDF environment
. ~/esp/esp-idf/export.sh

# 2. Set serial baud rate
export ESPBAUD=115200

# 3. Run Rake task
rake build
```

**Detection**: Check if `~/esp/esp-idf/export.sh` exists. If missing, raise clear error with setup instructions.

### Setup Detection

First build detection is handled by R2P2-ESP32 Rakefile:

```ruby
# R2P2-ESP32/Rakefile
task :deep_clean => [:clean] do
  sh "idf.py fullclean"
  rm_rf File.join(MRUBY_ROOT, "build/repos/esp32")  # 👈 Marks as "not set up"
end
```

**In ptrk device command**: Check if `build/repos/esp32` exists:
- **Missing** → First build, run `rake setup_esp32` first
- **Exists** → Subsequent build, run `rake build` directly

```ruby
workspace = get_build_workspace_path(env_name)
setup_needed = !File.exist?(File.join(workspace, "build/repos/esp32"))

Dir.chdir(workspace) do
  setup_esp32_task if setup_needed
  rake_build_task
end
```

## Debugging Build Workspace Issues

### Problem: "idf.py not found"

**Cause**: ESP-IDF environment not sourced

**Solution**:
```bash
. ~/esp/esp-idf/export.sh
echo $IDF_PATH  # Should print ESP-IDF path
```

### Problem: "build/repos/esp32 not found"

**Cause**: `rake setup_esp32` not run yet

**Solution**:
```bash
cd .ptrk_build/{env_name}/R2P2-ESP32
. ~/esp/esp-idf/export.sh
export ESPBAUD=115200
rake setup_esp32
```

### Problem: "No such file or directory" in build workspace

**Cause**: Build workspace corrupted, or source files missing from project root

**Possible Causes:**
- `storage/home/` or `mrbgems/` missing from project root
- `patch/` directory missing
- File permissions issue

**Solution**:
```bash
# Verify project root structure
ls -la storage/home/      # Should exist and have files
ls -la mrbgems/           # Should exist (may be empty)
ls -la patch/             # Should exist (may be empty)

# Rebuild workspace
rm -rf .ptrk_build/{env_name}
ptrk device build --env {env_name}  # Recreates workspace
```

### Problem: mrbgems C files not compiling

**Cause**: mrbgems not in correct nested picoruby path

**Debug:**
```bash
# Check if mrbgems are in correct location
ls .ptrk_build/{env_name}/R2P2-ESP32/components/picoruby-esp32/picoruby/mrbgems/

# Should show: my_gem/, other_gem/, etc.
# NOT in: .ptrk_build/{env_name}/mrbgems/
```

**Solution**:
```bash
# Rebuild workspace (will place mrbgems in correct nested path)
rm -rf .ptrk_build/{env_name}
ptrk device build --env {env_name}
```

### Problem: "patch files not applied"

**Cause**: patch/ directory missing from project root or `.ptrk_env/patch/`

**Debug:**
```bash
# Check for project root patches
ls -la patch/R2P2-ESP32/     # Project-level patches

# Check for stored patches
ls -la .ptrk_env/patch/R2P2-ESP32/  # Stored patches

# Check if patches applied in build
grep "CUSTOM_VALUE" .ptrk_build/{env_name}/R2P2-ESP32/custom/config.h
```

**Solution**:
- Create `patch/` directory if it doesn't exist
- Add patch files in `patch/R2P2-ESP32/` subdirectory
- Rebuild workspace

## Reference: R2P2-ESP32 Rake Tasks

From R2P2-ESP32 Rakefile:

| Task | Purpose |
|------|---------|
| `rake setup_esp32` | Build PicoRuby C components (first build only) |
| `rake setup_esp32c3` | Same, for C3 variant |
| `rake build` | Build ESP32 firmware |
| `rake flash` | Flash firmware to device |
| `rake monitor` | Monitor serial output (Ctrl+] to exit) |
| `rake clean` | Clean build artifacts |
| `rake deep_clean` | Clean everything including PicoRuby cache |

## Design Decisions & Future Enhancements

### Current Architecture (as of 2025-11-24)

- ✅ **Build target unified**: Only `R2P2-ESP32` is the mutable build target
- ✅ **mrbgems nested placement**: Custom gems in nested picoruby path ready for CMakeLists.txt
- ✅ **Multi-source patches**: Both `.ptrk_env/patch/` and `project-root/patch/` supported
- ⚠️ **CMakeLists.txt integration**: Needs implementation for auto-registering mrbgems C sources

### Future Enhancements (Planned)

1. **CMakeLists.txt Auto-Integration**
   - Auto-discover mrbgems C sources in nested path
   - Auto-update CMakeLists.txt with C source references
   - Enable seamless C extension compilation

2. **ptrk mrbgems Workflow**
   - Design user-facing `ptrk mrbgems add` command
   - Ensure gems are placed in correct nested path
   - Integrate with Mrbgemfile for reproducibility

3. **Storage/mrbgems Symlink Option**
   - Consider symlinks instead of file copying
   - Reduce storage usage for large projects
   - Maintain Windows compatibility

## Related Documentation

- `CLAUDE.md` — Build workspace concept overview and AI agent instructions
- `.claude/docs/testing-guidelines.md` — Test coverage requirements
- `.claude/docs/tdd-rubocop-cycle.md` — TDD micro-cycle workflow
