# PicoRuby ESP32 Multi-Version Build System Architecture

## Overview

A build system for ESP32 + PicoRuby development that manages multiple versions of R2P2-ESP32 and its nested submodules (picoruby-esp32 → picoruby) in parallel, allowing easy switching and validation across versions.

---

## Design Principles

### 1. Immutable Cache

- Repositories saved in `.cache/` are **never modified**
- Uniquely identified by commit hash + timestamp
- New cache is always created when versions change
- Old caches can be removed via `pra cache prune` when no longer needed

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
