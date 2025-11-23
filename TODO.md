# Project Status

## Remaining Tasks

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

**⚠️ REQUIRES SPECIAL INSTRUCTION FROM USER TO PROCEED**

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

### [TODO-QUALITY-2] Fix RBS parsing encoding error in env.rb

**Status**: ✅ COMPLETED (commit 83bf081)

**Issue**: RBS parsing fails with `invalid byte sequence in US-ASCII` when parsing picoruby RBS files containing non-ASCII characters.

**Solution Applied**: Specified UTF-8 encoding when reading RBS files in `parse_rbs_file` method.

### [TODO-QUALITY-3] Fix mrbgems generate template rendering error

**Status**: ✅ COMPLETED (commit 9c627c6)

**Issue**: `ptrk mrbgems generate` fails with template validation error when using lowercase names.

**Root Cause**: Template uses `TEMPLATE_CLASS_NAME` placeholder, but lowercase names like "mylib" produce `class mylib` which is invalid Ruby (class names must start with uppercase).

**Solution Applied**: Convert `class_name` to PascalCase in `prepare_template_context`:
- "mylib" → "Mylib"
- "my_lib" → "MyLib"
- "MyAwesomeLib" → "MyAwesomeLib" (preserved)

### [TODO-QUALITY-4] Fix patch_export git diff path handling

**Status**: ✅ COMPLETED (commit 4605fab)

**Issue**: `ptrk env patch_export` fails when processing submodule changes.

**Solution Applied**:
- Added `--` separator to git diff command for proper path handling
- Added .git directory existence check to skip non-repository directories

---

## Scenario Tests

### [TODO-SCENARIO-1] mrbgems workflow scenario test

**Status**: ✅ COMPLETED (commit 9c627c6)

**Objective**: Verify mrbgems are correctly generated and included in builds.

**Implementation**:
- Created `test/scenario/mrbgems_workflow_test.rb` with 5 scenario tests
- Covers project creation, custom mrbgem generation, multiple mrbgems, error handling, and class name conversion

### [TODO-SCENARIO-2] patch workflow scenario test

**Status**: ✅ COMPLETED (commit d3c4d77)

**Objective**: Verify patch creation and application workflow.

**Implementation**:
- Created `test/scenario/patch_workflow_test.rb` with 5 scenario tests
- Covers initial state, patch_diff, patch_export, patch content validation, and multiple file handling

### [TODO-SCENARIO-3] Project lifecycle end-to-end scenario test

**Status**: ✅ COMPLETED (commit b8dff0b)

**Objective**: Verify complete project lifecycle from creation to build.

**Implementation**:
- Created `test/scenario/project_lifecycle_test.rb` with 5 scenario tests
- Covers project creation, environment setup, build directory, and ESP-IDF error handling

### [TODO-SCENARIO-4] Multiple environment management scenario test

**Status**: ✅ COMPLETED (commit 964ed34)

**Objective**: Verify multiple environment creation and switching.

**Implementation**:
- Created `test/scenario/multi_env_test.rb` with 5 scenario tests
- Covers environment creation, listing, switching, and build directory coexistence

### [TODO-SCENARIO-5] storage/home workflow scenario test

**Status**: ✅ COMPLETED (commit 091de5d)

**Objective**: Verify storage/home files are correctly copied to build.

**Implementation**:
- Created `test/scenario/storage_home_test.rb` with 5 scenario tests
- Covers directory creation, file operations, nested directories, and binary file support

### [TODO-SCENARIO-6] Phase 5 end-to-end verification scenario test

**Status**: ✅ COMPLETED (commit 33b7022)

**Objective**: Codify the manual e2e verification performed in Phase 5.

**Implementation**:
- Created `test/scenario/phase5_e2e_test.rb` with 5 scenario tests
- Covers project structure creation, environment setup, build directory structure, mrbgems scaffold, and storage/home verification
- Tests use simulated environments without network operations

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
