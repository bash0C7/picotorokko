# Build Workspace Guide

## Overview

A **build workspace** is the working directory where ESP32 firmware is actually built and flashed. It's located at `.ptrk_build/{env_name}/R2P2-ESP32/`.

### Directory Structure

```
project-root/
├── .ptrk_env/                    # Environment definitions (git-tracked: .picoruby-env.yml)
│   ├── .picoruby-env.yml
│   └── {env_name}/R2P2-ESP32/    # Source repository
│
├── .ptrk_build/                  # Build workspaces (git-ignored)
│   └── {env_name}/
│       ├── R2P2-ESP32/           # 👈 BUILD WORKSPACE (mutable)
│       ├── storage/home/         # Application code
│       └── mrbgems/              # Custom gems
│
├── storage/home/                 # Application code (source)
├── mrbgems/                      # Custom gems (source)
└── patch/                        # Customization patches (source)
```

## Build Workspace Lifecycle

### 1. Creation (via `ptrk env set`)

```bash
ptrk env set my_env --R2P2-ESP32 "picoruby/R2P2-ESP32"
```

Creates:
- `.ptrk_env/{env_name}/` with source repositories
- `.ptrk_build/{env_name}/` with working copies
- `.picoruby-env.yml` with environment definition

### 2. Setup (via `ptrk device setup_esp32`)

Occurs **only on first build** when `build/repos/esp32` directory is missing:

```bash
cd .ptrk_build/{env_name}/R2P2-ESP32
. ~/esp/esp-idf/export.sh
export ESPBAUD=115200
rake setup_esp32
```

This builds:
- PicoRuby C components
- mrbgems dependencies
- ESP32-specific build artifacts

### 3. Build & Flash (via `ptrk device build`, `ptrk device flash`)

On every subsequent build:

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

**Cause**: Original directory was corrupted or `mrbgems/` not copied

**Solution**:
```bash
# Rebuild workspace
rm -rf .ptrk_build/{env_name}
ptrk device build --env {env_name}  # Recreates workspace
```

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

## Related Documentation

- `.claude/docs/testing-guidelines.md` — Test coverage requirements
- `.claude/docs/tdd-rubocop-cycle.md` — TDD micro-cycle
- `CLAUDE.md` — Build workspace concept overview
