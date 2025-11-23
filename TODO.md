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

**Issue**: `ptrk mrbgems generate` fails with template validation error.

**Error**: `レンダリング後のコードが無効なRubyコードです (RuntimeError)`

**Error Location**: `lib/picotorokko/template/ruby_engine.rb:55:in 'verify_output_validity!'`

**Tasks**:
- [ ] Investigate which template file causes invalid Ruby output
- [ ] Fix template or validation logic
- [ ] TDD verification: Ensure all existing tests pass
- [ ] COMMIT: "fix: resolve mrbgems generate template rendering error"

**Estimated effort**: Low-Medium

### [TODO-QUALITY-4] Fix patch_export git diff path handling

**Issue**: `ptrk env patch_export` fails when processing submodule changes.

**Error**: `fatal: ambiguous argument 'components/picoruby-esp32': unknown revision or path`

**Error Location**: `lib/picotorokko/commands/env.rb:859:in 'export_repo_changes'`

**Tasks**:
- [ ] Fix git diff command to properly separate paths from revisions using `--`
- [ ] Handle submodule paths correctly in export logic
- [ ] TDD verification: Ensure all existing tests pass
- [ ] COMMIT: "fix: handle git diff path arguments correctly in patch_export"

**Estimated effort**: Low-Medium

---

## Scenario Tests

### [TODO-SCENARIO-1] mrbgems workflow scenario test

**Objective**: Verify mrbgems are correctly generated and included in builds.

**Scenario Steps**:
1. `ptrk new testapp` → Verify `mrbgems/app/` is generated
2. `ptrk mrbgems generate mylib` → Verify `mrbgems/mylib/` is generated
3. `ptrk device build` → Verify `.ptrk_build/{env}/R2P2-ESP32/mrbgems/` contains all mrbgems
4. Multiple mrbgems → Verify both `app/` and `mylib/` are copied

**Tasks**:
- [ ] Create scenario test file: `test/scenario/mrbgems_workflow_test.rb`
- [ ] Implement test for each scenario step
- [ ] TDD verification: All tests pass
- [ ] COMMIT: "test: add mrbgems workflow scenario test"

**Estimated effort**: Medium

### [TODO-SCENARIO-2] patch workflow scenario test

**Objective**: Verify patch creation and application workflow.

**Scenario Steps**:
1. `ptrk env set --latest` → Initial state (no patches/)
2. Modify file in `.ptrk_build/` → `ptrk env patch_diff` shows changes
3. `ptrk env patch_export` → `patches/*.patch` files generated
4. Next `ptrk device build` → Patches applied to new `.ptrk_build/`
5. `ptrk env patch_diff` → No differences (patches already applied)

**Tasks**:
- [ ] Create scenario test file: `test/scenario/patch_workflow_test.rb`
- [ ] Implement test for each scenario step
- [ ] TDD verification: All tests pass
- [ ] COMMIT: "test: add patch workflow scenario test"

**Estimated effort**: Medium

### [TODO-SCENARIO-3] Project lifecycle end-to-end scenario test

**Objective**: Verify complete project lifecycle from creation to build.

**Scenario Steps**:
1. `ptrk new myapp` → Project structure created (Gemfile, storage/, mrbgems/, etc.)
2. `ptrk env set --latest` → Environment cloned with submodules
3. `ptrk env current {env}` → Environment selected, .rubocop.yml linked
4. `ptrk device build` → Build directory setup, mrbgems/storage copied
5. `ptrk device flash` → (ESP-IDF required, verify error message)
6. `ptrk device monitor` → (ESP-IDF required, verify error message)

**Tasks**:
- [ ] Create scenario test file: `test/scenario/project_lifecycle_test.rb`
- [ ] Implement test for each scenario step
- [ ] TDD verification: All tests pass
- [ ] COMMIT: "test: add project lifecycle scenario test"

**Estimated effort**: Medium

### [TODO-SCENARIO-4] Multiple environment management scenario test

**Objective**: Verify multiple environment creation and switching.

**Scenario Steps**:
1. `ptrk env set --latest` → Create env1 (YYYYMMDD_HHMMSS)
2. Sleep 1 second
3. `ptrk env set --latest` → Create env2 (different timestamp)
4. `ptrk env list` → Both environments displayed
5. `ptrk env current {env1}` → Select env1
6. `ptrk device build` → Build uses env1
7. `ptrk env current {env2}` → Switch to env2
8. `ptrk device build` → Build uses env2
9. Verify `.ptrk_build/{env1}/` and `.ptrk_build/{env2}/` both exist

**Tasks**:
- [ ] Create scenario test file: `test/scenario/multi_env_test.rb`
- [ ] Implement test for each scenario step
- [ ] TDD verification: All tests pass
- [ ] COMMIT: "test: add multiple environment management scenario test"

**Estimated effort**: Medium

### [TODO-SCENARIO-5] storage/home workflow scenario test

**Objective**: Verify storage/home files are correctly copied to build.

**Scenario Steps**:
1. Create `storage/home/app.rb` with test content
2. `ptrk device build` → Verify `.ptrk_build/{env}/R2P2-ESP32/storage/home/app.rb` exists
3. Verify content matches source
4. Update `storage/home/app.rb` content
5. `ptrk device build` → Verify updated content in build directory
6. Add `storage/home/lib/helper.rb` → Verify nested directory copied

**Tasks**:
- [ ] Create scenario test file: `test/scenario/storage_home_test.rb`
- [ ] Implement test for each scenario step
- [ ] TDD verification: All tests pass
- [ ] COMMIT: "test: add storage/home workflow scenario test"

**Estimated effort**: Low-Medium

### [TODO-SCENARIO-6] Phase 5 end-to-end verification scenario test

**Objective**: Codify the manual e2e verification performed in Phase 5.

**Scenario Steps** (with workarounds):
1. Setup playground: `bundle config set --local path vendor/bundle && bundle install`
2. Create project: `ptrk new myapp`
3. Edit Gemfile: Change ptrk gem path to `"../.."` (local development)
4. **Workaround**: Add `gem "rbs", "~> 3.0"` to Gemfile (until TODO-QUALITY-2 fixed)
5. Install dependencies: `bundle config set --local path vendor/bundle && bundle install`
6. Setup environment: `ptrk env set --latest`
   - Expect: RBS UTF-8 error (TODO-QUALITY-2)
   - After fix: Should complete successfully
7. Set current: `ptrk env current {env_name}`
8. Build: `ptrk device build`
   - Expect: "rake: not found" (ESP-IDF not installed)
   - Verify: .ptrk_build created, storage/home copied, mrbgems copied

**Verification Points**:
- [ ] Submodule structure exists (3 levels):
  - `.ptrk_env/{env}/`
  - `.ptrk_env/{env}/components/picoruby-esp32/`
  - `.ptrk_env/{env}/components/picoruby-esp32/picoruby/`
- [ ] Push disabled on all repos: `git remote -v` shows `no_push` for push URL
- [ ] .ptrk_build directory created from .ptrk_env
- [ ] storage/home/ copied to R2P2-ESP32/storage/home/
- [ ] mrbgems/ copied to R2P2-ESP32/mrbgems/
- [ ] Appropriate error when ESP-IDF not installed

**Tasks**:
- [ ] Create scenario test file: `test/scenario/phase5_e2e_test.rb`
- [ ] Implement test for each verification point
- [ ] Include workaround steps with comments for future removal
- [ ] TDD verification: All tests pass
- [ ] COMMIT: "test: add Phase 5 e2e verification scenario test"

**Estimated effort**: Medium-High (complex setup with multiple workarounds)

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
