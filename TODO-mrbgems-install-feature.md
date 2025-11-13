# TODO: Mrbgemfile Installation Feature

**Feature Overview**: Add gem installation functionality to `ptrk mrbgems` via `Mrbgemfile` (Ruby DSL)

**Status**: Design phase - User will manually refine specifications

**Created**: 2025-01-13
**Priority**: High

---

## 📋 Table of Contents

1. [Feature Design](#feature-design)
2. [Phase 1: Mrbgemfile DSL](#phase-1-mrbgemfile-dsl)
3. [Phase 2: ptrk init Default Environment](#phase-2-ptrk-init-default-environment)
4. [Phase 3: Documentation](#phase-3-documentation)
5. [Open Questions](#open-questions)
6. [Context & References](#context--references)

---

## Feature Design

### Core Concept

**Problem**:
- Users need to manually edit `build_config/xtensa-esp.rb` (or other build_config files) to add mrbgems
- CMakeLists.txt also needs manual edits when C code is involved
- No centralized, version-controlled mrbgem dependency management

**Solution**:
- Create `Mrbgemfile` in project root (Bundler-like Ruby DSL)
- Apply mrbgems to all build_config/*.rb files during `ptrk device build`
- Automatically append CMake directives to CMakeLists.txt

### Key Decisions (Confirmed)

1. **File name**: `Mrbgemfile` (Gemfile for mrbgems)
2. **Timing**: Apply during `ptrk device build` (NOT `ptrk build setup`)
3. **Syntax**: Ruby DSL matching `conf.gem` syntax in build_config
4. **Scope**: Apply to ALL build_config/*.rb files (user controls via `if config == "..."`)
5. **CMake**: User provides raw CMake strings (flexible, simple implementation)

---

## Phase 1: Mrbgemfile DSL

### 1.1 DSL Specification (NEEDS REFINEMENT)

**Current Draft**:

```ruby
# Mrbgemfile (project root)
# PicoRuby/mruby mrbgem dependency management

mrbgems do |config|
  # config: build_config file name without extension (e.g., "xtensa-esp", "rp2040")

  # GitHub source
  gem github: "ksbmyk/picoruby-ws2812", branch: "main"
  conf.gem github: "bash0C7/picoruby-mpu6886", branch: "main"  # conf.gem also works

  # Commit hash fixed version
  gem github: "picoruby/stable-gem", ref: "abc1234"

  # mruby core mrbgems
  gem core: "sprintf"
  gem core: "fiber"

  # Local filesystem
  gem path: "./local-gems/my-sensor"

  # Git repository (non-GitHub)
  gem git: "https://gitlab.com/custom/gem.git", branch: "develop"

  # Target-specific gems (user controls with if/unless)
  if config == "xtensa-esp"
    gem github: "picoruby/atom-matrix-led", branch: "main"
  end

  unless config == "rp2040"
    gem github: "picoruby/esp32-wifi", branch: "main"
  end

  # CMake: Single line
  gem github: "picoruby/sensor",
      branch: "main",
      cmake: "target_sources(picoruby_app PRIVATE ${CMAKE_CURRENT_LIST_DIR}/components/picoruby-esp32/picoruby/mrbgems/sensor/src/sensor.c)"

  # CMake: Multi-line (heredoc)
  gem github: "picoruby/complex-driver",
      branch: "main",
      cmake: <<~CMAKE
        target_sources(picoruby_app PRIVATE
          ${CMAKE_CURRENT_LIST_DIR}/components/picoruby-esp32/picoruby/mrbgems/complex-driver/src/main.c
          ${CMAKE_CURRENT_LIST_DIR}/components/picoruby-esp32/picoruby/mrbgems/complex-driver/src/util.c
        )
        target_include_directories(picoruby_app PRIVATE
          ${CMAKE_CURRENT_LIST_DIR}/components/picoruby-esp32/picoruby/mrbgems/complex-driver/include
        )
      CMAKE
end
```

**Open Questions** (User will refine):
- Should we support `version:` parameter? (e.g., `gem github: "...", version: "1.0.0"`)
- Should we validate gem source URLs?
- Should we cache gem metadata (commit hashes, etc.)?
- Error handling: What if DSL syntax is invalid?
- Should we support comments in DSL?

### 1.2 Implementation Components

#### Component A: MrbgemsDSL Parser

**File**: `lib/picotorokko/mrbgems_dsl.rb`

**Responsibilities**:
- Parse Mrbgemfile and evaluate DSL
- Pass `config` name to block
- Support both `gem` and `conf.gem` methods
- Normalize gem spec into structured hash

**Output Format**:
```ruby
[
  {
    source_type: :github,
    source: "ksbmyk/picoruby-ws2812",
    branch: "main",
    ref: nil,
    cmake: nil
  },
  {
    source_type: :core,
    source: "sprintf",
    branch: nil,
    ref: nil,
    cmake: nil
  },
  {
    source_type: :github,
    source: "picoruby/sensor",
    branch: "main",
    ref: nil,
    cmake: "target_sources(...)"
  }
]
```

**Tests Required**:
- Parse github: source
- Parse core: source
- Parse path: source
- Parse git: source
- Handle branch: parameter
- Handle ref: parameter
- Handle cmake: parameter (string)
- Handle cmake: parameter (heredoc)
- Support conf.gem alias
- Conditional evaluation (if config == "...")
- Invalid source error handling
- Empty Mrbgemfile

#### Component B: BuildConfigApplier

**File**: `lib/picotorokko/build_config_applier.rb`

**Responsibilities**:
- Read build_config/*.rb file
- Insert `conf.gem` lines into MRuby::Build.new block
- Use marker comments to manage generated sections
- Preserve existing conf.gem lines (no duplication)

**Marker Format**:
```ruby
MRuby::Build.new do |conf|
  # ... existing config ...

  # === BEGIN Mrbgemfile generated ===
  conf.gem github: "ksbmyk/picoruby-ws2812", branch: "main"
  conf.gem core: "sprintf"
  # === END Mrbgemfile generated ===
end
```

**Tests Required**:
- Insert conf.gem into empty block
- Insert conf.gem with existing conf.gem
- Replace existing marker section
- Preserve non-gem configuration
- Handle multiple MRuby::Build blocks (error)
- Handle missing MRuby::Build block (error)
- Generate correct conf.gem syntax for each source_type

#### Component C: CMakeApplier

**File**: `lib/picotorokko/cmake_applier.rb`

**Responsibilities**:
- Read CMakeLists.txt
- Append cmake: strings to file end
- Use marker comments to manage generated sections
- Remove old marker sections before inserting new

**Marker Format**:
```cmake
# ... existing CMake config ...

# === BEGIN Mrbgemfile generated ===
target_sources(picoruby_app PRIVATE ${CMAKE_CURRENT_LIST_DIR}/components/picoruby-esp32/picoruby/mrbgems/sensor/src/sensor.c)
target_sources(picoruby_app PRIVATE
  ${CMAKE_CURRENT_LIST_DIR}/components/picoruby-esp32/picoruby/mrbgems/complex-driver/src/main.c
  ${CMAKE_CURRENT_LIST_DIR}/components/picoruby-esp32/picoruby/mrbgems/complex-driver/src/util.c
)
# === END Mrbgemfile generated ===
```

**Tests Required**:
- Append cmake to empty file
- Replace existing marker section
- Handle multiple cmake: gems
- Preserve existing CMake config
- Handle missing CMakeLists.txt (skip silently? or error?)

#### Component D: Integration into `ptrk device build`

**File**: `lib/picotorokko/commands/device.rb`

**Modify**: `build` method (or `method_missing` delegation)

**Flow**:
```
ptrk device build
  ↓
1. Check if Mrbgemfile exists
  ↓
2. If exists:
   a. Find all build_config/*.rb files
   b. For each build_config:
      - Instantiate MrbgemsDSL with config name
      - Evaluate Mrbgemfile
      - Apply gems to build_config/*.rb (BuildConfigApplier)
      - Apply cmake: gems to CMakeLists.txt (CMakeApplier)
  ↓
3. Proceed with build (delegate to R2P2-ESP32 Rakefile)
```

**Tests Required**:
- Build with Mrbgemfile present
- Build without Mrbgemfile (skip)
- Build with invalid Mrbgemfile (error)
- Build with multiple build_config files
- Build with cmake: gems
- Integration: verify conf.gem added to build_config
- Integration: verify CMake directives added

### 1.3 TDD Implementation Order

**Order optimizes for fast feedback and small commits**:

1. **Step 1.1**: MrbgemsDSL - Basic parsing (RED → GREEN)
   - Test: Parse single github: gem
   - Implement: MrbgemsDSL class skeleton
   - Implement: `gem` method, `detect_source_type`, `extract_source`

2. **Step 1.2**: MrbgemsDSL - All source types (RED → GREEN)
   - Test: Parse core:, path:, git:
   - Implement: All source type handlers

3. **Step 1.3**: MrbgemsDSL - Parameters (RED → GREEN)
   - Test: branch:, ref:, cmake:
   - Implement: Parameter extraction

4. **Step 1.4**: MrbgemsDSL - conf.gem alias (RED → GREEN)
   - Test: conf.gem syntax works
   - Implement: `conf` method

5. **Step 1.5**: MrbgemsDSL - Conditional evaluation (RED → GREEN)
   - Test: if config == "xtensa-esp"
   - Implement: Pass config to block via `instance_exec`

6. **Step 1.6**: BuildConfigApplier - Insert conf.gem (RED → GREEN)
   - Test: Insert into empty MRuby::Build block
   - Implement: Marker insertion logic

7. **Step 1.7**: BuildConfigApplier - Replace existing (RED → GREEN)
   - Test: Replace existing marker section
   - Implement: Marker detection and removal

8. **Step 1.8**: CMakeApplier - Append cmake (RED → GREEN)
   - Test: Append to CMakeLists.txt
   - Implement: Marker management

9. **Step 1.9**: Device#build integration (RED → GREEN)
   - Test: Mrbgemfile applied during build
   - Implement: Hook into device build flow

10. **Step 1.10**: RuboCop + Coverage
    - Run: `bundle exec rubocop -A`
    - Verify: Coverage ≥ 85% line, ≥ 60% branch

11. **Step 1.11**: Commit
    - Message: "feat: Add Mrbgemfile DSL and application logic"

---

## Phase 2: ptrk init Default Environment

### 2.1 Current Status (INCOMPLETE)

**Current behavior**:
- `ptrk init` creates empty `.picoruby-env.yml`:
  ```yaml
  environments: {}  # Empty
  ```
- User must manually run:
  1. `ptrk env latest` (fetch R2P2-ESP32 latest)
  2. `ptrk cache fetch latest` (download to .cache/)
  3. `ptrk build setup latest` (construct build/)
  4. `ptrk device build` (finally build)

**Problem**: Too many manual steps for new users.

### 2.2 Desired Behavior

**New behavior**:
- `ptrk init` automatically fetches R2P2-ESP32 latest and creates "default" environment:
  ```yaml
  current: default

  environments:
    default:
      R2P2-ESP32:
        commit: f500652
        timestamp: "20250113_120000"
      picoruby-esp32:
        commit: 6a6da3a
        timestamp: "20250113_120000"
      picoruby:
        commit: e57c370
        timestamp: "20250113_120000"
      created_at: "2025-01-13 12:00:00"
      notes: "Initial environment (R2P2-ESP32 latest)"
  ```

**User flow after `ptrk init`**:
```bash
ptrk init my-project
# => Fetching R2P2-ESP32 latest...
#    Downloading to .cache/...
#    Setting up build environment...
#    ✓ Done! Run 'ptrk device build' to start development

cd my-project
ptrk device build  # Immediately usable
```

### 2.3 Implementation Changes

**File**: `lib/picotorokko/commands/init.rb`

**Modify**: `default` method (or `call` method)

**New flow**:
```
ptrk init my-project
  ↓
1. Create directory structure (existing)
  ↓
2. Generate template files (existing)
  ↓
3. 🆕 Fetch R2P2-ESP32 latest:
   a. Call Picotorokko::Commands::Env.new.latest
   b. This creates "latest" environment in .picoruby-env.yml
  ↓
4. 🆕 Rename "latest" to "default":
   a. Load .picoruby-env.yml
   b. Rename environments["latest"] to environments["default"]
   c. Set current: default
  ↓
5. 🆕 Fetch to cache:
   a. Call Picotorokko::Commands::Cache.new.fetch("default")
   b. Download R2P2-ESP32 + submodules to .cache/
  ↓
6. 🆕 Setup build environment:
   a. Call Picotorokko::Commands::Device.new.setup("default")
   b. Copy .cache/ → build/default/
   c. Apply patches
   d. Create build/current symlink
  ↓
7. Print success message with next steps
```

**Error handling**:
- GitHub fetch fails → **Error and exit** (no skip option)
- Submodule fetch fails → **Error and exit**
- Build setup fails → **Error and exit**

**Tests Required**:
- ptrk init creates default environment
- ptrk init fetches R2P2-ESP32 latest
- ptrk init downloads to .cache/
- ptrk init sets up build/
- ptrk init fails if GitHub unreachable (error)
- ptrk init fails if fetch fails (error)
- Integration: User can run `ptrk device build` immediately after init

### 2.4 TDD Implementation Order

1. **Step 2.1**: Env#latest refactoring (prepare for reuse)
   - Extract fetch logic into reusable method
   - Test: Env#latest still works

2. **Step 2.2**: Init calls Env#latest (RED → GREEN)
   - Test: Init creates "latest" environment
   - Implement: Call Env.new.latest from Init

3. **Step 2.3**: Init renames to "default" (RED → GREEN)
   - Test: .picoruby-env.yml has "default" environment
   - Implement: Rename logic

4. **Step 2.4**: Init fetches to cache (RED → GREEN)
   - Test: .cache/ populated after init
   - Implement: Call Cache.new.fetch

5. **Step 2.5**: Init sets up build (RED → GREEN)
   - Test: build/current exists after init
   - Implement: Call Device.new.setup

6. **Step 2.6**: Init error handling (RED → GREEN)
   - Test: Fetch fails → init fails
   - Implement: Error propagation

7. **Step 2.7**: RuboCop + Coverage

8. **Step 2.8**: Commit
   - Message: "feat: Auto-create default environment in ptrk init"

---

## Phase 3: Documentation

### 3.1 Files to Update

1. **SPEC.md**:
   - Add "Mrbgemfile Management" section
   - Add DSL syntax reference
   - Add workflow examples

2. **README.md**:
   - Update Quick Start (init → build)
   - Mention Mrbgemfile in "Getting Started"

3. **docs/MRBGEMS_GUIDE.md** (NEW):
   - Comprehensive Mrbgemfile guide
   - DSL reference with examples
   - Common patterns (conditional gems, CMake usage)
   - Troubleshooting

4. **docs/PROJECT_INITIALIZATION_GUIDE.md**:
   - Update with new init behavior (auto-fetch)

### 3.2 Documentation TDD

1. **Step 3.1**: SPEC.md update
   - Add Mrbgemfile section
   - Add DSL examples

2. **Step 3.2**: README.md update
   - Update Quick Start

3. **Step 3.3**: MRBGEMS_GUIDE.md creation
   - Comprehensive guide

4. **Step 3.4**: Commit
   - Message: "docs: Add Mrbgemfile documentation"

---

## Open Questions

### Critical (User MUST decide)

1. **Mrbgemfile DSL syntax refinement**:
   - Should we support `version:` parameter?
   - Should we support gem groups (like Bundler)? E.g., `group :development do ... end`
   - Should we support `gemspec` directive (like Bundler)?
   - Should we validate gem source URLs at DSL parse time?

2. **CMake string format**:
   - Current design: User provides raw CMake strings
   - Alternative: Structured hash? E.g., `cmake: { sources: ["src/*.c"], includes: ["include/"] }`
   - Trade-off: Flexibility vs. simplicity

3. **Error handling strategy**:
   - DSL syntax error → Fail immediately or collect all errors?
   - Missing build_config file → Skip or error?
   - Duplicate gem → Skip, warn, or error?

4. **ptrk env set improvements**:
   - Should we allow specifying picoruby-esp32 and picoruby commits separately?
   - Current: Only R2P2-ESP32 commit (others are "placeholder")
   - Proposed:
     ```bash
     ptrk env set my-env \
       --r2p2 abc1234 \
       --esp32 def5678 \
       --picoruby ghi9012
     ```

### Nice-to-have (Lower priority)

5. **Mrbgemfile validation command**:
   - `ptrk mrbgems validate` - Check Mrbgemfile syntax without building

6. **Mrbgemfile lock file**:
   - `Mrbgemfile.lock` - Record exact commit hashes used (like Gemfile.lock)

7. **Gem conflict detection**:
   - Warn if multiple gems provide same module/class

8. **Gem source caching**:
   - Cache gem repositories locally to speed up builds

---

## Context & References

### Related Files

- `lib/picotorokko/commands/env.rb` - Environment management (3-repo support exists, but `env set` is incomplete)
- `lib/picotorokko/commands/device.rb` - Device operations (where Mrbgemfile will be applied)
- `lib/picotorokko/commands/init.rb` - Project initialization (needs auto-fetch)
- `lib/picotorokko/env.rb` - Environment utilities (fetch, cache, build path logic)
- `SPEC.md` - User-facing specification (needs Mrbgemfile section)

### Architecture Notes

**env-hash Structure** (IMPORTANT):
- `.picoruby-env.yml` already supports 3 independent commits:
  ```yaml
  environments:
    env_name:
      R2P2-ESP32: { commit: xxx, timestamp: yyy }
      picoruby-esp32: { commit: xxx, timestamp: yyy }
      picoruby: { commit: xxx, timestamp: yyy }
  ```
- env_hash format: `{r2p2_hash}_{esp32_hash}_{picoruby_hash}`
- **Problem discovered**: `ptrk env set` only accepts R2P2-ESP32 commit (lib/picotorokko/commands/env.rb:55-69)
- **Fix needed**: Allow specifying all 3 commits independently

**Template Engine** (lib/picotorokko/template/):
- Ruby Template Engine (ruby_engine.rb) - Can parse and modify Ruby AST
- C Template Engine (c_engine.rb) - Can parse and modify C code
- YAML Template Engine (yaml_engine.rb) - Can parse and modify YAML
- These are READY to use for BuildConfigApplier and CMakeApplier

**Patch System** (lib/picotorokko/patch_applier.rb):
- Applies patches from `patch/` to `build/` during `ptrk build setup`
- Mrbgemfile should NOT be a patch - it's a configuration file

### User Workflow (Current vs. Desired)

**Current (Manual)**:
```bash
ptrk init my-project
cd my-project
ptrk env latest           # Fetch latest versions
ptrk cache fetch latest   # Download to .cache/
ptrk build setup latest   # Setup build/
# Manually edit build_config/xtensa-esp.rb to add conf.gem
ptrk device build         # Finally build
```

**Desired (Automatic)**:
```bash
ptrk init my-project
cd my-project
# Create Mrbgemfile with gem dependencies
ptrk device build  # Mrbgemfile auto-applied, then build
```

---

## Progress Tracking

### Phase 1: Mrbgemfile DSL
- [ ] Step 1.1: MrbgemsDSL - Basic parsing
- [ ] Step 1.2: MrbgemsDSL - All source types
- [ ] Step 1.3: MrbgemsDSL - Parameters
- [ ] Step 1.4: MrbgemsDSL - conf.gem alias
- [ ] Step 1.5: MrbgemsDSL - Conditional evaluation
- [ ] Step 1.6: BuildConfigApplier - Insert conf.gem
- [ ] Step 1.7: BuildConfigApplier - Replace existing
- [ ] Step 1.8: CMakeApplier - Append cmake
- [ ] Step 1.9: Device#build integration
- [ ] Step 1.10: RuboCop + Coverage
- [ ] Step 1.11: Commit

### Phase 2: ptrk init Default Environment
- [ ] Step 2.1: Env#latest refactoring
- [ ] Step 2.2: Init calls Env#latest
- [ ] Step 2.3: Init renames to "default"
- [ ] Step 2.4: Init fetches to cache
- [ ] Step 2.5: Init sets up build
- [ ] Step 2.6: Init error handling
- [ ] Step 2.7: RuboCop + Coverage
- [ ] Step 2.8: Commit

### Phase 3: Documentation
- [ ] Step 3.1: SPEC.md update
- [ ] Step 3.2: README.md update
- [ ] Step 3.3: MRBGEMS_GUIDE.md creation
- [ ] Step 3.4: Commit

---

## Notes for Implementation

1. **DO NOT start implementation yet** - User will refine specifications first
2. **Mrbgemfile DSL syntax is DRAFT** - User wants to refine before implementation
3. **ptrk env set improvement is CRITICAL** - Must support 3 independent commits
4. **ptrk init auto-fetch is MANDATORY** - No skip option, fail on error
5. **CMake string format is flexible** - User provides raw strings, ptrk just inserts them

---

## Revision History

- 2025-01-13: Initial draft (design phase)
- (User will add revisions as specifications are refined)
