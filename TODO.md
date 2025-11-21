# Project Status

## Current Status (Latest - 2025-11-19)

**🔧 IN PROGRESS: ptrk env latest Submodule Initialization Fix**
- 🔧 **Phase 1-2**: Completed investigation and SPEC.md update
- 🔧 **Phase 3a**: Partially complete - added `cache_clone_with_submodules` method
- 📋 **Updates**: SPEC.md and TODO.md revised for correct design
- 🚀 **Next**: Simplify `ptrk env latest`, implement `.build` setup in `ptrk device build`

**Completed Milestones:**
- ✅ **All Tests**: Passing (100% success rate)
- ✅ **Quality**: RuboCop clean (0 violations), coverage targets met
- ✅ **Error Handling**: All identified code quality issues verified and documented
- ✅ **ptrk init Command**: Complete with PicoRuby templates (.rubocop.yml, CLAUDE.md)
- ✅ **Mrbgemfile DSL**: Complete with template generation
- ✅ **Type System Integration**: Complete (rbs-inline + Steep)
- ✅ **Build Environment Setup**: Automatic git clone/checkout for `ptrk env latest`
- ✅ **Rake Command Polymorphism**: Smart detection for bundle exec vs rake
- ✅ **PicoRuby Development Templates**: Enhanced CLAUDE.md with mrbgems, I2C/GPIO/RMT, memory optimization

---

## Active Implementation: Fix ptrk env latest (Phase 3-4)

### ⚠️ Design Correction
**Old (SPEC.md v1 - incorrect)**:
- `ptrk cache fetch` → `ptrk build setup` → `ptrk device build`

**New (SPEC.md v2 - correct)**:
- `ptrk env latest` → save environment definition only
- `ptrk device build` → setup `.build/` and build firmware

### Phase 3: Remove env creation from ptrk new
- [ ] **TDD RED**: Write test for `ptrk new` without environment creation
- [ ] **TDD GREEN**: Remove `setup_default_environment` from ProjectInitializer
- [ ] **TDD RUBOCOP**: Auto-fix style
- [ ] **TDD REFACTOR**: Clean up any dead code
- [ ] **COMMIT**: "refactor: remove automatic environment creation from ptrk new"

### Phase 3b: Rename ptrk env latest to ptrk env set --latest
- [ ] **TDD RED**: Write test for `ptrk env set --latest` with timestamp env name (YYYYMMDD_HHMMSS format)
- [ ] **TDD GREEN**: Rename latest command to be `ptrk env set --latest`
- [ ] **TDD GREEN**: Auto-set currentenv if .picoruby-env.yml is empty/missing
- [ ] **TDD RUBOCOP**: Auto-fix style
- [ ] **TDD REFACTOR**: Extract timestamp generation logic
- [ ] **COMMIT**: "refactor: rename ptrk env latest to ptrk env set --latest"

### Phase 3c: Implement current environment tracking
- [ ] **TDD RED**: Write test for `ptrk env current ENV_NAME` command
- [ ] **TDD GREEN**: Implement `ptrk env current` to set/get current environment
- [ ] **TDD RUBOCOP**: Auto-fix style
- [ ] **COMMIT**: "feat: add ptrk env current command for environment selection"

### Phase 3d: Support ENV_NAME omission with current fallback
- [ ] **TDD RED**: Write tests for optional ENV_NAME on patch_diff, patch_export, reset, show
- [ ] **TDD GREEN**: Make ENV_NAME optional, default to current environment
- [ ] **TDD RUBOCOP**: Auto-fix style
- [ ] **TDD REFACTOR**: Clean up argument handling
- [ ] **COMMIT**: "feat: make ENV_NAME optional for env commands (default to current)"

### Phase 3e: Remove ptrk env patch_apply
- [ ] **TDD RED**: Write test verifying patch_apply is no longer available
- [ ] **TDD GREEN**: Remove patch_apply command (patches applied during device build)
- [ ] **TDD RUBOCOP**: Auto-fix style
- [ ] **COMMIT**: "refactor: remove patch_apply command (patches applied during build)"

### Phase 4: Implement .build Setup in ptrk device build
- [ ] **TDD RED**: Write test for `.build/` directory creation with submodules
- [ ] **TDD GREEN**: Implement `.build/` setup (clone with submodules, apply patches)
- [ ] **TDD RUBOCOP**: Auto-fix style
- [ ] **TDD REFACTOR**: Extract setup logic into helper methods
- [ ] **COMMIT**: "feat: setup .build directory with submodules in ptrk device build"

### Phase 5: End-to-end Verification
- [ ] Verify workflow: `ptrk init` → `ptrk env latest` → `ptrk device build`
- [ ] Test in playground environment
- [ ] Confirm submodule structure in `.build/R2P2-ESP32/components/picoruby-esp32/picoruby/`

---

## Test Execution

**Quick Reference**:
```bash
bundle exec rake test         # Run all tests (unit → integration → scenario → others)
bundle exec rake test:unit    # Unit tests only (fast feedback, ~1.3s)
bundle exec rake test:scenario # Scenario tests (~0.8s)
bundle exec rake ci           # CI checks: all tests + RuboCop + coverage validation
bundle exec rake dev          # Development: RuboCop auto-fix + unit tests
```

---

## Completed Features (v0.1.0)

### ✅ ptrk init Command
- Project initialization with templates
- Auto-generation of `.rubocop.yml` with PicoRuby configuration
- Enhanced `CLAUDE.md` with comprehensive development guide
- Template variables: {{PROJECT_NAME}}, {{AUTHOR}}, {{CREATED_AT}}, {{PICOTOROKKO_VERSION}}
- Optional `--with-ci` flag for GitHub Actions integration

### ✅ Environment Management
- `ptrk env set` — Create/update environments with git commit reference
- `ptrk env show` — Display environment details
- `ptrk env list` — List all configured environments
- `ptrk env latest` — Auto-fetch latest repo versions with git clone/checkout
- `ptrk env reset` — Reset to default configuration
- `ptrk env patch_export` — Export patches from specific environment

### ✅ Device Commands
- `ptrk device build` — Build firmware in environment
- `ptrk device flash` — Flash firmware to device
- `ptrk device monitor` — Monitor serial output
- Smart Rake command detection (bundle exec vs rake)
- R2P2-ESP32 Rakefile delegation for actual build tasks

### ✅ Infrastructure
- Executor abstraction (ProductionExecutor, MockExecutor)
- AST-based template engines (Ruby, YAML, C)
- Mrbgemfile template with picoruby-picotest reference
- Type system (rbs-inline annotations, Steep checking)
- Comprehensive error handling with validation

---

## Roadmap (Future Versions)

### Priority 1: Device Testing Framework
- **Status**: Research phase
- **Objective**: Enable `ptrk device {build,flash,monitor} --test` for Picotest integration
- **Estimated**: v0.2.0

### Priority 2: Additional mrbgems Management
- **Status**: Planned
- **Objective**: Commands for generating, testing, publishing mrbgems
- **Estimated**: v0.2.0+

### Priority 3: CI/CD Templates
- **Status**: Planned
- **Objective**: Enhanced GitHub Actions workflow templates
- **Estimated**: v0.3.0+

---

## Documentation Files

**For ptrk Users** (located in docs/):
- `README.md` — Installation and quick start
- `docs/CI_CD_GUIDE.md` — Continuous integration setup
- `docs/MRBGEMS_GUIDE.md` — mrbgems creation and management
- `docs/github-actions/` — Workflow templates for CI/CD

**For Gem Developers** (located in .claude/):
- `.claude/docs/` — Internal design documents
- `.claude/skills/` — Development workflow agents
- `CLAUDE.md` — Development guidelines and conventions
- `SPEC.md` — Detailed feature specification

**Auto-Generated for Projects** (via ptrk init):
- `{{PROJECT_NAME}}/CLAUDE.md` — PicoRuby development guide for the project
- `{{PROJECT_NAME}}/.rubocop.yml` — Project-specific linting configuration
- `{{PROJECT_NAME}}/README.md` — Project setup instructions
- `{{PROJECT_NAME}}/Mrbgemfile` — mrbgems dependencies

---

## Quality Gates

All features must pass:
- ✅ Tests: 100% success rate
- ✅ RuboCop: 0 violations
- ✅ Coverage: Targets met (≥85% line, ≥60% branch)
- ✅ Type checking: Steep validation passing
- ✅ Documentation: Updated with code changes

---

## Recent Changes

### Session 2025-11-18: Code Quality Verification
- Verified all identified code quality issues
- All issues confirmed as fixed with proper error handling and test coverage
- Updated documentation to reflect completion status
- Test suite: All tests passing, coverage targets met

### Session 2025-11-17: PicoRuby Development Templates
- Added `.rubocop.yml` template with PicoRuby-specific configuration
- Enhanced `CLAUDE.md` template with:
  - mrbgems dependency management
  - Peripheral APIs (I2C, GPIO, RMT) with examples
  - Memory optimization techniques
  - RuboCop configuration guide
  - Picotest testing framework
- Updated ProjectInitializer to copy template files
- Fixed UTF-8 encoding in tests for international characters

### Previous Sessions: Environment & Build Features
- Session 6: Fixed `ptrk env latest` infrastructure issues
- Session 5: Implemented build environment setup and Gemfile detection

---

## Known Limitations & Future Work

1. **Device Testing**: Picotest integration not yet implemented (`--test` flag for device commands)
2. **C Linting**: No C linting tools currently in templates (could add clang-format in v0.2.0)
3. **Cache Management**: Not implemented (considered for v0.2.0+)
4. **mrbgems Generation**: Basic support only; full workflow in v0.2.0

---

## Installation & Release

### For End Users
```bash
gem install picotorokko
```

### For Development
```bash
git clone https://github.com/bash0C7/picotorokko
cd picotorokko
bundle install
bundle exec rake test
```

Current version: **0.1.0** (released to RubyGems)

---

## Performance Notes

### Test Execution Performance
- **Parallel execution**: Enabled with multiple workers
- **SimpleCov**: HTMLFormatter in dev, CoberturaFormatter in CI
- **Branch coverage**: CI-only (disabled in dev for speed)

**Monitor with**:
```bash
time bundle exec rake test
```
