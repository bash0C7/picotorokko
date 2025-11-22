# Project Status

## Current Status (Latest - 2025-11-22)

**✅ COMPLETED: Phase 4a (Build Directory Setup)**
- ✅ **Phase 4a**: Complete - `.ptrk_build` directory setup from `.ptrk_env` cache
- ✅ **Phase 3b-rubocop**: Complete - RBS parsing and JSON generation
- ✅ **Phase 3c-rubocop**: Complete - Project `.rubocop.yml` linked to current env
- ✅ **Phase 3d**: Complete - ENV_NAME optional with current fallback
- ✅ **Phase 3e**: Complete - `patch_apply` command removed
- ✅ **Phase 3f**: Complete - `ptrk rubocop` command removed
- ✅ **Tests**: All unit tests (152) and integration tests (81) passing with 85.28% line coverage
- ✅ **Quality**: RuboCop clean (0 violations)
- 🚀 **Next**: Phase 4d (device default env to current)

**Completed Milestones:**
- ✅ **All Tests**: Passing (229 unit + integration tests, 100% success rate)
- ✅ **Quality**: RuboCop clean (0 violations), 84.24% line coverage
- ✅ **Phase 3c**: `ptrk env current` command for environment selection
- ✅ **Phase 3b-cleanup**: Removed `ptrk env latest` (replaced by `ptrk env set --latest`)
- ✅ **Phase 3b-submodule**: Full implementation of `ptrk env set --latest` with submodule rewriting
- ✅ **Phase 3b (Part 1)**: Added `--latest` option to `ptrk env set` command
- ✅ **Phase 3**: Removed automatic environment creation from ptrk new
- ✅ **Phase 3a**: Directory naming consistency - `.ptrk_env` + YYYYMMDD_HHMMSS format
- ✅ **Error Handling**: All identified code quality issues verified and documented
- ✅ **ptrk init Command**: Complete with PicoRuby templates (.rubocop.yml, CLAUDE.md)
- ✅ **Mrbgemfile DSL**: Complete with template generation
- ✅ **Type System Integration**: Complete (rbs-inline + Steep)
- ✅ **Build Environment Setup**: Automatic git clone/checkout for `ptrk env set --latest`
- ✅ **Rake Command Polymorphism**: Smart detection for bundle exec vs rake
- ✅ **PicoRuby Development Templates**: Enhanced CLAUDE.md with mrbgems, I2C/GPIO/RMT, memory optimization

---

## Active Implementation: Fix ptrk env latest (Phase 3-4)

### ⚠️ Design Correction
**Old (SPEC.md v1 - incorrect)**:
- `ptrk cache fetch` → `ptrk build setup` → `ptrk device build`

**New (SPEC.md v2 - correct)**:
- `ptrk env latest` → save environment definition only
- `ptrk device build` → setup `.ptrk_build/` and build firmware

### Phase 3a: Directory naming consistency (ptrk_env → .ptrk_env)
- [x] **TDD RED**: Write tests for `.ptrk_env/` directory usage
- [x] **TDD GREEN**: Update `ENV_DIR` constant from `ptrk_env` to `.ptrk_env`
- [x] **TDD GREEN**: Update `ENV_NAME_PATTERN` to `/^\d+_\d+$/` (YYYYMMDD_HHMMSS format only)
- [x] **TDD GREEN**: Update `validate_env_name!` for new pattern
- [x] **TDD GREEN**: Update all `get_build_path`, `get_environment`, file operations to use `.ptrk_env/`
- [x] **TDD GREEN**: Update test fixtures and test setup
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **COMMIT**: "refactor: rename ptrk_env to .ptrk_env and validate env names as YYYYMMDD_HHMMSS"

### Phase 3: Remove env creation from ptrk new
- [x] **TDD RED**: Write test for `ptrk new` without environment creation
- [x] **TDD GREEN**: Remove `setup_default_environment` from ProjectInitializer
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **TDD REFACTOR**: Clean up any dead code
- [x] **COMMIT**: "refactor: remove automatic environment creation from ptrk new"

### Phase 3b: Rename ptrk env latest to ptrk env set --latest

**Design**: Use git submodule mechanism for cross-repo consistency
- Clone R2P2-ESP32 at specified commit
- Initialize submodules and checkout picoruby-esp32 & picoruby at specified commits
- Disable push on all repos to prevent accidental pushes
- Generate env-name from local timestamp (YYYYMMDD_HHMMSS format)

#### Phase 3b-submodule: Implement submodule rewriting

**Git Operations Flow**:
```bash
# 1. Clone R2P2-ESP32 with minimal object fetch
git clone --filter=blob:none {R2P2_URL} .ptrk_env/{env_name}/
cd .ptrk_env/{env_name}
git checkout {R2P2_commit}

# 2. Initialize and fetch all nested submodules recursively
git submodule update --init --recursive --jobs 4

# 3. Checkout picoruby-esp32 to specified commit
cd components/picoruby-esp32
git checkout {esp32_commit}

# 4. Checkout nested picoruby submodule
cd picoruby
git checkout {picoruby_commit}

# 5. Stage and commit submodule changes
cd ../..  # Return to .ptrk_env/{env_name}
git add components/picoruby-esp32
git commit --amend -m "ptrk env: {YYYYMMDD_HHMMSS}"

# 6. Disable push on all repos
git remote set-url --push origin no_push
cd components/picoruby-esp32 && git remote set-url --push origin no_push
cd picoruby && git remote set-url --push origin no_push
```

**Implementation Tasks**:
- [x] **TDD RED**: Write test for `ptrk env set --latest` with submodule rewriting
- [x] **TDD GREEN**: Generate env-name from local timestamp (YYYYMMDD_HHMMSS using `Time.now.strftime`)
- [x] **TDD GREEN**: Clone R2P2-ESP32 with `--filter=blob:none` to `.ptrk_env/{env_name}/`
- [x] **TDD GREEN**: Handle git clone failures (fatal error, no retry)
- [x] **TDD GREEN**: Checkout R2P2-ESP32 to specified commit
- [x] **TDD GREEN**: Initialize submodules: `git submodule update --init --recursive --jobs 4`
- [x] **TDD GREEN**: Extract picoruby-esp32 & picoruby commit refs from env definition
- [x] **TDD GREEN**: Checkout picoruby-esp32 to specified commit
- [x] **TDD GREEN**: Checkout picoruby (nested submodule) to specified commit
- [x] **TDD GREEN**: Stage submodule changes: `git add components/picoruby-esp32`
- [x] **TDD GREEN**: Amend commit with env-name: `git commit --amend -m "ptrk env: {env_name}"`
- [x] **TDD GREEN**: Disable push on main repo: `git remote set-url --push origin no_push`
- [x] **TDD GREEN**: Disable push on picoruby-esp32 submodule
- [x] **TDD GREEN**: Disable push on picoruby nested submodule
- [x] **TDD GREEN**: Record R2P2-ESP32, picoruby-esp32, picoruby commit hashes in .picoruby-env.yml
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **COMMIT**: "feat: implement ptrk env set --latest with submodule rewriting"

#### Phase 3b-cleanup: Remove ptrk env latest command
- [x] **TDD RED**: Write test verifying `ptrk env latest` is no longer available
- [x] **TDD GREEN**: Remove `latest` command from env.rb
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **COMMIT**: "refactor: remove ptrk env latest command (replaced by ptrk env set --latest)"

#### Phase 3b-rubocop: Generate RuboCop config in env set

**Design**: Extract RBS files directly from env's picoruby repository
- Source: `.ptrk_env/{env}/picoruby/mrbgems/picoruby-*/sig/*.rbs`
- Parse RBS using `RBS::Parser.parse_signature` (reference: picoruby.github.io/lib/rbs_doc/class_formatter.rb)
- Extract methods from `RBS::AST::Members::MethodDefinition` nodes
- Compare with CRuby core class methods
- Store env-specific JSON databases

**RBS Parsing Pattern** (from picoruby.github.io):
```ruby
sig = RBS::Parser.parse_signature(File.read(path))
sig[2].each do |dec|
  case dec
  when RBS::AST::Declarations::Class, RBS::AST::Declarations::Module
    methods = {instance: [], singleton: []}
    dec.members.each do |member|
      case member
      when RBS::AST::Members::MethodDefinition
        next if member.comment&.string&.include?("@ignore")
        methods[member.kind] << member.name.to_s  # kind: :instance or :singleton
      end
    end
  end
end
```

**JSON Output Format**:
```json
{
  "Array": {"instance": ["each", "map", "select"], "singleton": ["new"]},
  "String": {"instance": ["upcase", "downcase"], "singleton": ["new"]}
}
```

**Implementation Tasks**:
- [x] **TDD RED**: Write test for RuboCop setup during `ptrk env set --latest`
- [x] **TDD GREEN**: Generate `.ptrk_env/{env}/rubocop/data/` directory during env creation
- [x] **TDD GREEN**: Locate RBS files: `Dir.glob(".ptrk_env/{env}/picoruby/mrbgems/picoruby-*/sig/*.rbs")`
- [x] **TDD GREEN**: Parse RBS files using `RBS::Parser.parse_signature(File.read(path))`
- [x] **TDD GREEN**: Walk AST: iterate `RBS::AST::Declarations::Class/Module` nodes
- [x] **TDD GREEN**: Extract methods: filter `RBS::AST::Members::MethodDefinition` nodes
- [x] **TDD GREEN**: Handle RBS parse errors: skip file with warning output (don't halt)
- [x] **TDD GREEN**: Classify methods by `member.kind` (`:instance` vs `:singleton`)
- [x] **TDD GREEN**: Filter `@ignore` annotations: `next if member.comment&.string&.include?("@ignore")`
- [x] **TDD GREEN**: Extract CRuby core class methods (Array, String, Hash, Integer, Float, Symbol, Regexp, Range, Numeric)
- [x] **TDD GREEN**: Calculate unsupported methods: `cruby_methods - picoruby_methods`
- [x] **TDD GREEN**: Generate `picoruby_supported_methods.json` in `.ptrk_env/{env}/rubocop/data/`
- [x] **TDD GREEN**: Generate `picoruby_unsupported_methods.json` in `.ptrk_env/{env}/rubocop/data/`
- [x] **TDD GREEN**: Generate env-specific `.rubocop-picoruby.yml` in `.ptrk_env/{env}/rubocop/`
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **COMMIT**: "feat: generate env-specific RuboCop configuration in ptrk env set"

### Phase 3c: Implement current environment tracking
- [x] **TDD RED**: Write test for `ptrk env current ENV_NAME` command
- [x] **TDD GREEN**: Implement `ptrk env current` to set/get current environment
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **COMMIT**: "feat: add ptrk env current command for environment selection"

#### Phase 3c-rubocop: Sync .rubocop.yml with current env

**Design**: Merge env-specific RuboCop config with existing project config
- Use `inherit_from` to reference `.ptrk_env/{env}/rubocop/.rubocop-picoruby.yml`
- Preserves user's existing `.rubocop.yml` settings
- Auto-generates if doesn't exist

- [x] **TDD RED**: Write test for `.rubocop.yml` placement when `ptrk env current` is set
- [x] **TDD GREEN**: Create `.rubocop.yml` in project root if not exists
- [x] **TDD GREEN**: Add `inherit_from: .ptrk_env/{env}/rubocop/.rubocop-picoruby.yml` to `.rubocop.yml`
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **COMMIT**: "feat: generate project .rubocop.yml linked to current env"

### Phase 3d: Support ENV_NAME omission with current fallback
- [x] **TDD RED**: Write tests for optional ENV_NAME on patch_diff, patch_export, reset, show
- [x] **TDD GREEN**: Make ENV_NAME optional, default to current environment
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **COMMIT**: "feat: make ENV_NAME optional for env commands (default to current)"

### Phase 3e: Remove ptrk env patch_apply
- [x] **TDD RED**: Write test verifying patch_apply is no longer available
- [x] **TDD GREEN**: Remove patch_apply command (patches applied during device build)
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **COMMIT**: "refactor: remove patch_apply command (patches applied during build)"

### Phase 3f: Remove ptrk rubocop command
- [x] **TDD RED**: Write test verifying `ptrk rubocop` is no longer available
- [x] **TDD GREEN**: Remove RuboCop command class (`lib/picotorokko/commands/rubocop.rb`)
- [x] **TDD GREEN**: Remove CLI registration from `lib/picotorokko/cli.rb`
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **COMMIT**: "refactor: remove ptrk rubocop command (integrated into ptrk env)"

### Phase 4: Implement .ptrk_build Setup in ptrk device build

**Design**: Separate readonly env cache from build working directory
- `.ptrk_env/{env_name}/` - readonly env (git working copies from env definition)
- `.ptrk_build/{env_name}/` - build working directory (patches, storage/home applied)

#### Phase 4a: Setup .ptrk_build directory structure
- [x] **TDD RED**: Write test for `.ptrk_build/{env_name}/` directory creation
- [x] **TDD GREEN**: Copy entire tree from `.ptrk_env/{env_name}/` to `.ptrk_build/{env_name}/`
- [x] **TDD GREEN**: Add BUILD_DIR constant (".ptrk_build")
- [x] **TDD GREEN**: Update get_build_path to return .ptrk_build/{env_name}
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **COMMIT**: "feat: setup .ptrk_build directory from env cache"

#### Phase 4b: Apply patches to .ptrk_build directory
- [x] **TDD GREEN**: Implement patch application via apply_patches_to_build method
- [x] **TDD GREEN**: Patches applied automatically during setup_build_environment
- [x] **COMMIT**: Included in Phase 4a commit

#### Phase 4c: Reflect storage/home contents
- [x] **TDD GREEN**: Copy from `storage/home/` to `.ptrk_build/{env_name}/R2P2-ESP32/storage/home/`
- [x] **TDD GREEN**: Copy from `mrbgems/` to `.ptrk_build/{env_name}/R2P2-ESP32/mrbgems/`
- [x] **COMMIT**: Included in Phase 4a commit

#### Phase 4d: Update ptrk device default env
- [x] **TDD GREEN**: Change `ptrk device build` default from `latest` to `current`
- [x] **TDD RUBOCOP**: Auto-fix style
- [x] **COMMIT**: "refactor: use current as default env for all device commands"

### Phase 5: End-to-end Verification
- [ ] Verify workflow: `ptrk env set --latest` → `ptrk env current 20251121_060114` → `ptrk device build`
- [ ] Test in playground environment
- [ ] Confirm `.ptrk_env/20251121_060114/R2P2-ESP32/` has complete submodule structure (git submodule update executed)
- [ ] Confirm `.ptrk_build/20251121_060114/R2P2-ESP32/` is copy of .ptrk_env with patches and storage/home applied
- [ ] Verify push is disabled on all repos: `git remote -v` shows no push URL
- [ ] Verify `.ptrk_env/` repos cannot be accidentally modified

---

## Code Quality: AGENTS.md Rule Compliance

### [TODO-QUALITY-1] Remove rubocop:disable from lib/picotorokko/commands/env.rb

**Issue**: AGENTS.md prohibits `# rubocop:disable` comments. Refactor instead.

**Violations Found**:
- `lib/picotorokko/commands/env.rb:16` — `# rubocop:disable Metrics/ClassLength`
- `lib/picotorokko/commands/env.rb:187` — `# rubocop:disable Metrics/BlockLength`

**Refactoring Tasks** (behavior must not change):
- [ ] **Extract helper modules**: Move related methods into separate modules (e.g., `EnvSetup`, `EnvValidation`, `RubocopSetup`)
- [ ] **Split no_commands block**: Break large `no_commands` block into smaller logical groups
- [ ] **TDD verification**: Ensure all existing tests pass after refactoring
- [ ] **RuboCop clean**: Verify 0 violations without disable comments
- [ ] **COMMIT**: "refactor: extract helper modules to eliminate rubocop:disable in env.rb"

**Estimated effort**: Medium (class is ~800 lines, needs careful extraction)

---

## Implementation Notes

### Dependencies to Add

Add to `Gemfile`:
```ruby
gem "rbs", "~> 3.0"  # For RBS file parsing in Phase 3b-rubocop
gem "steep", "~> 1.5"  # For Steepfile configuration access (if needed)
```

### Key Design Decisions

#### 1. Environment Name Format: YYYYMMDD_HHMMSS
- **Pattern**: `^\d+_\d+$` (numbers_numbers only, no hyphens)
- **Generation**: `Time.now.strftime("%Y%m%d_%H%M%S")`
- **Validation**: All commands validate against this pattern
- **Current tracking**: `.picoruby-env.yml` stores which env is current

#### 2. Git Clone Failures
- **No retry**: Fatal error, terminate immediately
- **Reason**: Indicates network/permission issues that won't resolve with retry
- **User guidance**: Error message should direct to diagnostics

#### 3. RBS Parse Errors
- **Skip with warning**: Parse errors don't halt the entire env creation
- **Warning output**: Log warning to stderr for each failed RBS file
- **Reason**: A single malformed RBS file shouldn't break the entire env setup
- **Impact**: Missing methods from failed files won't be in JSON databases

#### 4. Git Submodule Structure
- **Three-level**: R2P2-ESP32 → components/picoruby-esp32 → picoruby
- **Initialization**: Use `--recursive --jobs 4` for parallel submodule fetching
- **Commit checkout**: Each level must be checked out independently
- **Push safety**: Disable push on all three levels via `git remote set-url --push origin no_push`

#### 5. Directory Separation
- **`.ptrk_env/{env}/`**: Read-only cache from git clones with submodules
- **`.ptrk_build/{env}/`**: Working directory for patching and building
- **Why separate**: Enables cache reuse, prevents accidental env modification

#### 6. RBS Method Extraction Pattern
- **Source**: picoruby.github.io/lib/rbs_doc/class_formatter.rb
- **Parser**: `RBS::Parser.parse_signature(File.read(path))`
- **AST nodes**: `RBS::AST::Declarations::Class/Module` and `RBS::AST::Members::MethodDefinition`
- **Filtering**: Skip methods with `@ignore` annotation or `@private` comment
- **Classification**: Use `member.kind` to separate `:instance` and `:singleton` methods

#### 7. JSON Database Structure
```json
{
  "ClassName": {
    "instance": ["method1", "method2"],
    "singleton": ["class_method1", "class_method2"]
  }
}
```
- **Sorted**: Method names alphabetically within each category
- **Used by**: RuboCop custom cop UnsupportedMethod detection

#### 8. Backwards Compatibility
- **ptrk rubocop command**: Complete removal (Phase 3f), no deprecation needed
- **Existing YAML**: Auto-migration handled by default env setter
- **Test impact**: All tests must use new `.ptrk_env` directory name

### Testing Strategy

#### MockExecutor for Git Operations
- Stub all system() calls in tests
- Return successful exit codes by default
- Override specific calls for failure scenarios
- Never actually clone/checkout in unit tests

#### Integration Tests for Submodules
- Use real git operations (git clone, submodule init/update)
- Test with temporary directories
- Verify submodule structure after clone
- Confirm push is disabled on all levels

#### RBS Parsing Tests
- Use fixture RBS files (simple class/method definitions)
- Test parse errors with malformed RBS
- Verify warning output when parse fails
- Test @ignore annotation filtering

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

### Session 2025-11-21: Phase 3a - Directory Naming Consistency
- **Implemented Phase 3a**: Complete directory rename and env naming pattern update
- **Constants updated**:
  - `ENV_DIR`: `"ptrk_env"` → `".ptrk_env"` (hidden directory for cleaner project root)
  - `ENV_NAME_PATTERN`: `/^[a-z0-9_-]+$/` → `/^\d+_\d+$/` (strict YYYYMMDD_HHMMSS format)
- **Full test coverage**: 153 unit tests + 70 integration tests (100% passing, 83.29% coverage)
- **All file operations updated**: ProjectInitializer, templates, tests
- **RuboCop**: 0 violations, quality gates met
- **TDD Microycle**: Perfect RED → GREEN → RUBOCOP → REFACTOR → COMMIT cycle

### Session 2025-11-18: Code Quality Verification
- Verified all identified code quality issues
- All issues confirmed as fixed with proper error handling and test coverage
- Updated documentation to reflect completion status
- Test suite: All tests passing, coverage targets met

### Session 2025-11-17: PicoRuby Development Templates
- Added `.rubocop.yml` template with PicoRuby-specific configuration
- Enhanced `CLAUDE.md` template with mrbgems, peripheral APIs, memory optimization
- Updated ProjectInitializer to copy template files
- Fixed UTF-8 encoding in tests for international characters

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
