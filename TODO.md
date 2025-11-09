# TODO: Project Maintenance Tasks

> **TODO Management Methodology**: See `.claude/skills/project-workflow/SKILL.md` and `CLAUDE.md` ## TODO Management section for task management rules and workflow.

---

## 🚀 Core: Major Refactoring - picotorokko (ptrk)

**Status**: Planning Complete, Ready for Implementation

**Full Specification**: [docs/PICOTOROKKO_REFACTORING_SPEC.md](docs/PICOTOROKKO_REFACTORING_SPEC.md)

**Overview**:
- Gem name: `pra` → `picotorokko`
- Command: `pra` → `ptrk`
- Commands: 8 → 4 (env, device, mrbgem, rubocop)
- Directory: Consolidate into `ptrk_env/` (replaces `.cache/`, `build/`, `.picoruby-env.yml`)
- Env names: User-defined (no "current" symlink), defaults to `development`
- Breaking changes: Yes (but no users affected - unreleased gem)
- Estimated effort: 2-3 weeks, 6 phases

**Key Design Decisions**:
- ✅ Two distinct project roots: Gem development vs. ptrk user
- ✅ Environment name validation: `/^[a-z0-9_-]+$/`
- ✅ No implicit state (no `current` symlink)
- ✅ Tests use `Dir.mktmpdir` to keep gem root clean
- ✅ All quality gates must pass: Tests + RuboCop + Coverage

### Phase 1: Planning & Documentation ✅ COMPLETED
- [x] Analyze current command structure
- [x] Investigate naming options
- [x] Create detailed refactoring specification
- [x] Update TODO.md with phased breakdown

### Phase 2: Rename & Constants (2-3 days)
- [ ] Update `ptrk.gemspec` (name, executables)
- [ ] Rename `bin/pra` → `bin/ptrk`
- [ ] Create/update `lib/ptrk/env.rb` with new constants
- [ ] Add constant reference in `CLAUDE.md`
- [ ] Update `lib/ptrk/cli.rb` (command registration)
- [ ] Run RuboCop, fix violations
- [ ] Commit: "chore: rename pra → picotorokko, command → ptrk"

### Phase 3: Command Structure (4-5 days)
- [ ] Refactor `lib/ptrk/commands/env.rb`
  - [ ] Add `set` with commit/branch options
  - [ ] Enhance `show` with version details
  - [ ] Add `reset` for environment reconstruction
  - [ ] Move patch operations: `patch_export`, `patch_apply`, `patch_diff`
  - [ ] Implement `list` with environment overview
- [ ] Delete `lib/ptrk/commands/cache.rb`
- [ ] Delete `lib/ptrk/commands/build.rb`
- [ ] Delete `lib/ptrk/commands/patch.rb`
- [ ] Update `lib/ptrk/commands/device.rb` (env names, no implicit current)
- [ ] Add environment name validation to all commands
- [ ] Run RuboCop, fix violations
- [ ] Commit per major logical change

### Phase 4: Directory Structure (3-4 days)
- [ ] Update `lib/ptrk/env.rb` path logic
  - [ ] Replace `.cache/` with `ptrk_env/.cache/`
  - [ ] Replace `build/` with `ptrk_env/{env_name}/`
  - [ ] Replace `.picoruby-env.yml` with `ptrk_env/.picoruby-env.yml`
  - [ ] Remove `current` symlink logic
- [ ] Implement directory initialization in `ptrk env set`
- [ ] Add validation for env names (regex)
- [ ] Run full test suite locally
- [ ] Commit: "refactor: consolidate directories into ptrk_env/"

### Phase 5: Test Updates & Infrastructure (5-6 days)

**CRITICAL**: This phase solves all Test Infrastructure Issues

- [ ] **Update test infrastructure**
  - [ ] Update `test/test_helper.rb`
    - [ ] Change to use temp `ptrk_user_root` (Dir.mktmpdir)
    - [ ] Add `verify_gem_root_clean!` check
  - [ ] Verify `bundle exec rake test` counts all tests correctly
  - [ ] Fix SimpleCov exit code issue (ensure exit 0 on success)
  - [ ] Ensure ALL THREE pass together:
    - Tests pass: `bundle exec rake test` (exit 0)
    - RuboCop clean: `bundle exec rubocop` (0 violations)
    - Coverage passes: SimpleCov reports without exit code error

- [ ] **Fix device_test.rb Thor command argument handling**
  - **Current Status**: `test/commands/device_test.rb` TEMPORARILY EXCLUDED
  - **Root Cause**: Thor interprets env names (e.g., `'test-env'`) as subcommands
  - **Solution Required**: Refactor device command to accept env_name as explicit option (`--env` flag)
  - **Files**: `test/commands/device_test.rb`, `lib/ptrk/commands/device.rb`, `Rakefile`
  - **Priority**: High (core feature testing blocked)

- [ ] **Rewrite test suite for new structure**
  - [ ] Rewrite `test/commands/env_test.rb` (new structure)
  - [ ] Delete `test/commands/cache_test.rb`
  - [ ] Delete `test/commands/build_test.rb`
  - [ ] Delete `test/commands/patch_test.rb`
  - [ ] Update `test/commands/device_test.rb` (env names required)

- [ ] **Quality gates verification**
  - [ ] Run `bundle exec rake test` - all passing (exit 0)
  - [ ] Verify coverage ≥ 80% line, ≥ 50% branch
  - [ ] Run `bundle exec rubocop` - 0 violations
  - [ ] Commit: "test: update and consolidate test suite"

**TDD Cycle Requirements**:
- Red → Green → `rubocop -A` → Refactor → Commit
- 1-5 minutes per iteration
- All quality gates must pass before commit
- Never add `# rubocop:disable` or fake tests
- If any test fails or SimpleCov has issues, redesign immediately

### Phase 6: Documentation & Finalization (3-4 days)
- [ ] Update `README.md`
  - [ ] Rename all `pra` → `ptrk` references
  - [ ] Update command examples
  - [ ] Update installation instructions
- [ ] Update `.gitignore`
- [ ] Update `CLAUDE.md` project instructions
- [ ] Update all docs in `docs/`
- [ ] Add CHANGELOG entry
- [ ] Run final test suite: `bundle exec rake ci`
- [ ] Verify all quality gates pass
- [ ] Commit: "docs: update for picotorokko refactoring"

### Final Quality Verification
- [ ] `bundle exec rake test` - All tests pass (exit 0)
- [ ] `bundle exec rubocop` - 0 violations (exit 0)
- [ ] SimpleCov coverage report - ≥ 80% line, ≥ 50% branch (exit 0)
- [ ] No files in gem root (only ptrk_user_root used)
- [ ] All commits have clear messages

---

## 🔮 Post-Refactoring Enhancements

### AST-Based Template Engine ✅ APPROVED

**Status**: Approved for Implementation (Execute AFTER picotorokko refactoring)

**Full Specification**: [docs/PICOTOROKKO_REFACTORING_SPEC.md#template-strategy-ast-based-template-engine](docs/PICOTOROKKO_REFACTORING_SPEC.md#template-strategy-ast-based-template-engine)

**Overview**: Replace ERB-based template generation with AST-based approach (Parse → Modify → Dump)

**Key Decisions**:
- ✅ Ruby templates: Placeholder Constants (e.g., `TEMPLATE_CLASS_NAME`)
- ✅ YAML templates: Special placeholder keys (e.g., `__PTRK_TEMPLATE_*__`), comments NOT preserved
- ✅ C templates: String replacement (e.g., `TEMPLATE_C_PREFIX`)
- ✅ ERB removal: Complete migration, no hybrid period
- ✅ **Critical requirement**: All templates MUST be valid code before substitution

**Key Components**:
- `Ptrk::Template::Engine` - Unified template interface
- `RubyTemplateEngine` - Prism-based (Visitor pattern for ConstantReadNode)
- `YamlTemplateEngine` - Psych-based (recursive placeholder replacement)
- `CTemplateEngine` - String gsub-based (simple identifier substitution)

**Migration Phases**:
1. PoC (2-3 days): ONE template + validation
2. Complete Rollout (3-5 days): ALL templates converted
3. ERB Removal (1 day): Delete .erb files

**Web Search Required** (before implementation):
- Prism unparse/format capabilities
- Prism location offset API verification
- RuboCop autocorrect patterns for learning

**Estimated Effort**: 8-12 days

**Priority**: High (approved, post-picotorokko)

### Future Enhancements (Phase 5+)

For detailed implementation guide and architecture design of the PicoRuby RuboCop Custom Cop, see [docs/RUBOCOP_PICORUBY_GUIDE.md](docs/RUBOCOP_PICORUBY_GUIDE.md).

