# TODO: mrbgems Support Feature Implementation

> **Overview**: Implement comprehensive mrbgems support in `pra` CLI to allow users to create and manage application-specific mrbgems (like `App`) with C language code integration alongside PicoRuby code.

**User Intent**: PicoRuby developers need to write C code (for tuning, low-layer code) that integrates with their application. Instead of embedding C directly in PicoRuby, users should be able to create application-specific mrbgems in the `pra` project template, managed alongside the application.

---

## 📐 Architecture Design

### Design Decisions

#### 1. **mrbgem Template Structure**

Following the pattern from `picoruby-irq` at https://github.com/picoruby/picoruby/tree/master/mrbgems/picoruby-irq

**Standard mrbgem Directory Layout**:
```
mrbgems/App/
├── mrbgem.rake              # mRuby gem specification
├── mrblib/
│   └── app.rb               # Ruby class definition (Class App)
├── src/
│   └── app.c                # C implementation with mrbc_app_init function
├── include/                 # Optional: C headers
└── ports/
    └── esp32/
        └── app.c            # ESP32-specific implementation (if needed)
```

#### 2. **Ruby Class Design**

- **Class App**: Class methods only (no instance creation)
  - Singleton pattern for low-level functionality
  - Example: `App.version`, `App.get_status`, etc.
- **Implementation location**: `mrblib/app.rb` for pure Ruby, `src/app.c` for C bindings

#### 3. **C Code Structure**

Following the pattern from picoruby-irq and picoruby-machine mrbgems:

```c
#if defined(PICORB_VM_MRUBY)

// mruby implementation

#elif defined(PICORB_VM_MRUBYC)

// mrubyc implementation (which ESP32 uses with MRubyC VM)
void mrbc_app_init(struct VM *vm) {
  // Register App class methods
  // Define class method implementations
}

#endif
```

#### 4. **build_config Integration**

**Reference**: `build_config` in PicoRuby build system (e.g., `xtensa-esp.rb`)

```ruby
# In user's custom build_config:
conf.gem core: 'picoruby-irq'
conf.gem app: 'App'  # or: conf.gem local: 'path/to/mrbgems/App'
```

**ESP-IDF CMakeLists.txt Integration**:

Option A (Recommended for `pra`): Add as independent ESP-IDF component

```cmake
# components/app-mrbgem/CMakeLists.txt
idf_component_register(
  SRCS
    ${COMPONENT_DIR}/src/app.c
  INCLUDE_DIRS
    ${COMPONENT_DIR}/include
  REQUIRES picoruby-esp32
)
```

Option B: Add to existing picoruby-esp32 component CMakeLists.txt

```cmake
# In picoruby-esp32/CMakeLists.txt SRCS section:
${COMPONENT_DIR}/picoruby/mrbgems/App/src/app.c

# In picoruby-esp32/CMakeLists.txt INCLUDE_DIRS section:
${COMPONENT_DIR}/picoruby/mrbgems/App/include
```

**Decision for pra**: Use **Option A** (independent component) for modularity, but also support patching Option B if needed.

---

## 🔧 Implementation Plan

### Phase 1: Core Commands & Templates

#### 1.1 Create mrbgem Templates

- [ ] **Create template directory structure**
  - `lib/pra/templates/mrbgems/` - Base templates for all mrbgems
  - `lib/pra/templates/mrbgems/app/` - App-specific template (default)
  - `lib/pra/templates/mrbgems/<name>/` - Generic template for other mrbgems

- [ ] **Template files for App mrbgem**
  - `app/mrbgem.rake` - Minimal mrbgem specification
  - `app/mrblib/app.rb` - Empty App class with class methods structure
  - `app/src/app.c` - Skeleton C implementation with mrbc_app_init
  - `app/include/app.h` - Optional header template
  - `app/.keep` - Placeholder for empty directories

- [ ] **Template Substitution Logic**
  - Support variable interpolation: `{{gem_name}}`, `{{author}}`, `{{license}}`
  - Example: Replace `{{gem_name}}` with `App` in template files

#### 1.2 Implement `pra mrbgems generate` Command

- [ ] **Create `lib/pra/commands/mrbgems.rb`**
  - Subcommand: `pra mrbgems generate <name>` [--template=<template>] [--author=<author>]
  - Default template: `app` (creates basic app-style mrbgem)
  - Generate mrbgem directory in `mrbgems/<name>/`
  - Copy and substitute template files
  - Validate mrbgem name (alphanumeric, underscore)
  - Support other built-in templates: `machine`, `irq`, etc. (future)

- [ ] **Register command in `lib/pra/cli.rb`**
  - Add: `desc 'mrbgems SUBCOMMAND ...ARGS', 'mrbgem generation and management commands'`
  - Add: `subcommand 'mrbgems', Pra::Commands::Mrbgems`

#### 1.3 Implement `pra setup` Enhancement

**Current State**: `pra setup` doesn't exist as a command; app setup is done in R2P2-ESP32

**Enhancement Approach**:
- [ ] **Create `lib/pra/commands/app.rb`** (new command for app-level management)
  - Subcommand: `pra app setup` [--name=<app_name>] [--template=<template>]
  - OR: Extend existing setup in R2P2-ESP32 to call this automatically
  - Generate base application template in R2P2-ESP32/main/ if needed
  - Create App mrbgem: `mrbgems/App/` with full structure
  - Register in `lib/pra/cli.rb`

- [ ] **Alternatively**: `pra init` command
  - `pra init <project_dir>` - Initialize new PicoRuby project with App mrbgem
  - Create directory structure: `project_dir/main/`, `project_dir/mrbgems/App/`, `project_dir/.picoruby-env.yml`
  - This aligns with typical CLI patterns (like `rails new`, `cargo init`)

---

### Phase 2: build_config & CMakeLists.txt Integration

#### 2.1 build_config Registration

- [ ] **Understand current build_config management**
  - Locate where `xtensa-esp.rb` or custom build configs are stored
  - How are they currently specified/referenced?

- [ ] **Implement automatic mrbgem registration in build_config**
  - `lib/pra/mrbgems/registrar.rb` - Helper to register mrbgems
  - Add to build_config: `conf.gem local: '../mrbgems/App'`
  - OR: `conf.gem app: 'App'` (if custom `app:` is supported in mruby build system)
  - Handle relative path correctly from build_config perspective

- [ ] **Validate mrbgem is recognized by PicoRuby build system**
  - Test build to confirm `mrbgems/App` is compiled
  - Ensure `Class App` is available in PicoRuby REPL after build

#### 2.2 CMakeLists.txt Integration (ESP-IDF side)

- [ ] **Implement CMakeLists.txt patch generation**
  - Create patch file in `patches/R2P2-ESP32/` OR `patches/picoruby-esp32/`
  - OR: Implement auto-generation during `pra build setup`
  - Patch includes mrbgem component registration (Option A) or source file additions (Option B)

- [ ] **Option A: Independent Component**
  - Create `components/app-mrbgem/CMakeLists.txt` dynamically
  - Add to main `components/picoruby-esp32/CMakeLists.txt`: `REQUIRES app-mrbgem`

- [ ] **Option B: Direct Integration**
  - Add to `picoruby-esp32/CMakeLists.txt` SRCS:
    ```cmake
    ${COMPONENT_DIR}/picoruby/mrbgems/App/src/app.c
    ```
  - Add to INCLUDE_DIRS:
    ```cmake
    ${COMPONENT_DIR}/picoruby/mrbgems/App/include
    ```

---

### Phase 3: Patch Management & Customization

#### 3.1 Patch System for mrbgem Customization

- [ ] **Understand current patch system**
  - Review `lib/pra/commands/build.rb` `apply_patches` method
  - Patches are in `patches/R2P2-ESP32/`, `patches/picoruby-esp32/`, `patches/picoruby/`

- [ ] **Allow users to customize mrbgem via patches**
  - If user modifies `mrbgems/App/src/app.c`, create patch: `patches/picoruby/mrbgems/App/src/app.c`
  - During `pra build setup`, patches are applied to working build environment
  - Allows version-agnostic customization of App mrbgem

- [ ] **Implement `pra patch manage-mrbgem` command** (optional enhancement)
  - Simplify patch creation for mrbgem files
  - Automatically track `mrbgems/App/` changes
  - Sync between source and patches

---

## 📋 Detailed Task Breakdown

### Tasks to Implement (in order)

#### T1. Design & Create mrbgem Templates
- [ ] Create directory: `lib/pra/templates/mrbgems/app/`
- [ ] Create: `lib/pra/templates/mrbgems/app/mrbgem.rake` (template)
- [ ] Create: `lib/pra/templates/mrbgems/app/mrblib/app.rb` (template)
- [ ] Create: `lib/pra/templates/mrbgems/app/src/app.c` (template with PICORB_VM_MRUBYC block)
- [ ] Create: `lib/pra/templates/mrbgems/app/include/app.h` (template)
- [ ] Create placeholder files (`.keep`) for empty directories

#### T2. Implement Template Substitution Logic
- [ ] Add: `lib/pra/mrbgems/template_engine.rb`
  - Read template files
  - Replace variables: `{{gem_name}}`, `{{author}}`, `{{license}}`
  - Write to destination

#### T3. Implement `pra mrbgems generate` Command
- [ ] Create: `lib/pra/commands/mrbgems.rb`
  - Implement: `generate(name, options = {})` method
  - Support: `--template`, `--author`, `--license` options
  - Validate mrbgem name
  - Call `TemplateEngine` to create mrbgem directory
- [ ] Register in `lib/pra/cli.rb`
- [ ] Add tests: `test/commands/mrbgems_test.rb`

#### T4. Implement `pra app setup` or `pra init` Command (TBD)
- [ ] Decide: `app setup` (extend existing) vs `init` (new project initialization)
- [ ] Create: `lib/pra/commands/app.rb` (if new command)
- [ ] Integrate: Call `pra mrbgems generate App` during setup
- [ ] Register in `lib/pra/cli.rb`
- [ ] Add tests

#### T5. Implement build_config Registration
- [ ] Create: `lib/pra/mrbgems/registrar.rb`
  - Detect build_config file location
  - Add mrbgem registration: `conf.gem local: '../mrbgems/App'` or equivalent
  - Handle relative paths correctly
- [ ] Add tests

#### T6. Implement CMakeLists.txt Integration
- [ ] Analyze: How to auto-generate or patch CMakeLists.txt
- [ ] Implement: Patch generation in `lib/pra/mrbgems/cmake_generator.rb`
  - Option A: Create `components/app-mrbgem/CMakeLists.txt`
  - Option B: Patch `picoruby-esp32/CMakeLists.txt` for direct integration
- [ ] Integrate into `pra build setup` or `pra mrbgems generate`
- [ ] Add tests

#### T7. End-to-End Integration Testing
- [ ] Create: `test/integration/mrbgems_integration_test.rb`
- [ ] Test: Full workflow
  1. `pra app setup --name myapp`
  2. Verify: `mrbgems/App/` structure created
  3. `pra build setup`
  4. Verify: App mrbgem compiled into firmware
  5. Access in PicoRuby: `App.version` returns value from C code

#### T8. Documentation & Examples
- [ ] Update: `README.md` with `pra mrbgems` command documentation
- [ ] Create: `docs/MRBGEMS_GUIDE.md` - User guide for creating custom mrbgems
- [ ] Update: CI_CD_GUIDE.md if relevant

---

## 📚 References & Research

### Files to Review
- [ ] `lib/pra/commands/build.rb` - Study patch application mechanism (lines 176-210)
- [ ] `lib/pra/env.rb` - Environment variable handling
- [ ] PicoRuby source: `mrbgems/picoruby-irq/` - Study mrbgem structure
- [ ] PicoRuby build system: `build_config/xtensa-esp.rb` - Understand mrbgem registration

### ESP-IDF & PicoRuby Documentation
- [ ] ESP-IDF v5.x CMakeLists.txt: `idf_component_register()` function signature
- [ ] MRuby documentation: `mrbgem.rake` specification format
- [ ] PicoRuby build system: How `conf.gem` directive works

---

## 🎯 User Workflow (Target)

After implementation, users will be able to:

### 1. Initialize a new PicoRuby project with App mrbgem
```bash
pra init my_iot_project
# Creates: my_iot_project/main/, my_iot_project/mrbgems/App/, .picoruby-env.yml
```

### 2. Generate additional mrbgems (future)
```bash
pra mrbgems generate Sensor --template=basic --author="John Doe"
# Creates: mrbgems/Sensor/ with structure ready for C code
```

### 3. Write C code in the mrbgem
```c
// mrbgems/App/src/app.c
#ifdef PICORB_VM_MRUBYC
void mrbc_app_init(struct VM *vm) {
  // Register class methods for App
  // Implementation code here
}
#endif
```

### 4. Customize via patches (if needed)
```bash
# Edit mrbgems/App/src/app.c
vi mrbgems/App/src/app.c

# Create patch for version control
pra patch create picoruby mrbgems/App/src/app.c
```

### 5. Build and deploy
```bash
pra build setup
pra device build
pra device flash
```

---

## 🔗 Related Tasks in TODO.md

- [ ] [README.md] Implement `pra device help` command (prerequisite: understand command structure)
- [ ] [Code Quality] Refactor duplicate patch application logic (will benefit mrbgems patch system)

---

## Notes

- **Complexity**: Medium-high (template system + integration with build system)
- **Testing**: Requires integration testing with actual PicoRuby build
- **User Impact**: High - enables significant functionality extension for application developers
- **Timeline**: Estimate 2-3 weeks for full implementation
