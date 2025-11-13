# TODO: Project Maintenance Tasks

## Current Status

- ✅ **All Tests**: 197 tests passing (183 main + 14 device)
- ✅ **Quality**: RuboCop clean, coverage 87.14% line / 65.37% branch
- ✅ **Infrastructure**: Executor abstraction, Template engines, Device test framework complete

---

## Test Execution

**Quick Reference**:
```bash
rake              # Default: Run all tests (183 main + 14 device)
rake test         # Run main test suite (183 tests)
rake ci           # CI checks: tests + RuboCop + coverage validation
rake dev          # Development: RuboCop auto-fix + tests + coverage
```

**Quality Metrics**:
- Tests: 197 total, all passing ✓
- Coverage: 87.14% line, 65.37% branch (minimum: 85%/60%)
- RuboCop: 0 violations

---

## ⚠️ Known Issues (Unresolved)

### [TODO-INFRASTRUCTURE-DEVICE-TEST] Thor help command breaks test-unit registration

**Status**: Omitted (low priority)

**Verification**: Commit 64df24f - Confirmed that Thor help command breaks test-unit registration:
- Mixed device_test with main tests (removed delete_if)
- Enabled help test (removed omit)
- **Result**: Only 65/197 tests registered (132+ tests fail to register)
- **Impact**: Help command cannot be tested alongside main test suite
- **Current solution**: Keep device tests isolated via `test:device_internal` task

**Reason for omit**:
- Display-only feature (non-critical)
- `help` command works manually
- No user-facing impact (CI/CD unaffected)

**Next steps if needed**:
- Investigate test-unit + Thor hook interaction
- Consider alternative testing strategy for device commands
- May require refactoring test infrastructure

---

## Completed Infrastructure

- ✅ Executor abstraction (ProductionExecutor, MockExecutor)
- ✅ AST-based template engines (Ruby, YAML, C)
- ✅ Device test framework integration
- ✅ Command name refactoring (pra → picotorokko)
- ✅ Rake task simplification (CI vs development)
- ✅ Documentation structure cleanup (obsolete docs removed, architecture docs organized)

---

## Planned Features

### 🎯 Priority 1: Type System Integration (rbs-inline + Steep)

**Goal**: Add type annotations and static type checking to improve code quality and IDE support

**Strategy**: Use **rbs-inline annotations** (becoming Ruby standard) as primary annotation method. Auto-generate .rbs files. Use Steep for type checking. NO YARD.

**Reference Documentation** (Design & Implementation Guides):
- **Investigation**: [`.claude/docs/rbs-inline-research.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/rbs-inline-research.md) — Deep analysis of rbs-inline (Ruby standard candidate)
- **Strategy**: [`.claude/docs/type-system-strategy.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/type-system-strategy.md) — Overall type system integration plan (Phases 2-5)
- **Phase 2+**: [`.claude/docs/type-annotation-guide.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/type-annotation-guide.md) — Annotation patterns, examples, workflow
- **TDD Workflow**: [`.claude/docs/t-wada-style-tdd-guide.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/t-wada-style-tdd-guide.md) — How RBS integrates into t-wada style TDD

**Status**: Phase 2 complete! Full infrastructure + annotations + RBS generation + Steep type checking:
- ✅ Phase 2 Step 1: Environment setup complete
  - Dependencies: rbs ~> 3.4, steep ~> 1.8, rbs-inline ~> 0.11 in gemspec
  - Steepfile with lib and test targets
  - sig/ directory structure with generated/ subdir
  - Rake tasks: `rake rbs:generate`, `rake steep`
- ✅ Phase 2 Step 2: Comprehensive annotations across all commands
  - Added rbs-inline annotations to CLI + all command classes
  - Full annotations for: Device (8 methods), Mrbgems (1), Rubocop (2)
  - env.rb: 25+ key methods fully annotated
- ✅ Phase 2 Step 3: RBS Collection + Type Generation
  - rbs_collection.yaml: 54 external gems (Thor, FileUtils, YAML, Rake, Minitest, etc.)
  - Generated RBS stubs via `bundle exec rbs collection install`
  - 5 compiled .rbs files (309 lines) from source annotations
  - Steep type checking: 0 errors on picotorokko code ✓
  - All 183 tests passing, coverage 87.14% maintained

**Deliverables**:
- Type annotations in all source files (CLI, Commands, Env modules)
- Generated .rbs files in sig/generated/picotorokko/
- RBS Collection with 54 gems in sig/rbs_collection/
- Ready for CI: `rake steep` validates types before merge

---

### 📚 Priority 2: Gem Documentation Generation

**Goal**: Generate comprehensive documentation from RBS type definitions

**Strategy**: Rely on RubyDoc.info for Phase 2 (zero config). Evaluate rbs-doc/Steep docs for Phase 3 local generation.

**CRITICAL**: Priority 1 decision (rbs-inline only, NO YARD) means documentation comes from auto-generated .rbs files only.

**Reference Documentation** (Design & Implementation):
- **Design**: [`.claude/docs/documentation-generation.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/documentation-generation.md) — RBS-only documentation strategy (Phases 1-3)
- **Phase 2 goal**: Commit .rbs files, let RubyDoc.info auto-generate docs on gem publish

**Status**: Phase 1 design complete. Waiting for Priority 1 Phase 2 completion (.rbs files in sig/)

---

### 🔄 Priority 3: Documentation Update Automation

**Goal**: Ensure implementation changes always trigger documentation updates

**Strategy**: Integrate documentation checks into dev workflow (CLAUDE.md + Quality Gates). Escalate to Claude Skill (Phase 2) and CI validation (Phase 4) later.

**Reference Documentation** (Design & Implementation):
- **Design**: [`.claude/docs/documentation-automation-design.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/documentation-automation-design.md) — File change → doc mapping (Phases 1-4)
- **Phase 1 (COMPLETE)**: Documentation Check added to CLAUDE.md ("Before every commit" + "Quality Gates")
  - File change mapping: lib/picotorokko/commands/ → SPEC.md + README.md, etc.
  - Reference: `.claude/docs/documentation-automation-design.md` for full mapping

**Status**: Phase 1 complete (CLAUDE.md integration). Phases 2-4 pending (Skill, Hook, CI validation)

---

## ✅ Critical Priority: ptrk init Command Implementation

**Background**: New users cannot start projects without initialization command. Manual setup requires 10+ steps and is prone to errors. SPEC.md defines directory structure but no command exists to create it. Template engine is fully implemented and ready to use.

**Goal**: Implement `ptrk init` command to initialize complete PicoRuby project structure with single command.

### ✅ Phase 1: Minimum Implementation (COMPLETE)

- ✅ Create `lib/picotorokko/commands/init.rb`
- ✅ Register `init` subcommand in `lib/picotorokko/cli.rb`
- ✅ Implement basic directory creation (storage/home, patch/{R2P2-ESP32,picoruby-esp32,picoruby}, ptrk_env/)
- ✅ Generate `.gitignore` file (exclude .cache/, build/, ptrk_env/*/)
- ✅ Generate `ptrk_env/.picoruby-env.yml` (empty environment definition template)
- ✅ Add comprehensive tests in `test/commands/init_test.rb`
- ✅ RuboCop clean, coverage 88.69% (exceeds 85%/60% requirement)
- ✅ Commit: 1bd280f - Add complete rbs-inline type annotations

### ✅ Phase 2: Template Expansion (COMPLETE)

- ✅ Create `lib/picotorokko/templates/project/` directory structure
- ✅ Add project README.md template (with placeholder variables)
- ✅ Add sample application (storage/home/app.rb)
- ✅ Add Gemfile template (with picotorokko dependency)
- ✅ Add CLAUDE.md template (ptrk user context, auto-generated)
- ✅ Test: verify all templates render correctly with variables
- ✅ RuboCop clean, coverage 88.39% (exceeds 85%/60% requirement)
- ✅ All tests passing: 196/196 (100% pass rate)

### ✅ Phase 3: Optional Features (COMPLETE)

- ✅ `--with-ci` option (copy GitHub Actions ESP32 build workflow)
  - ✅ Commit: c20b669 - Add --with-ci option
  - ✅ Tests: 196 passing, workflow copied only when enabled
- ✅ `--with-mrbgem NAME` option (generate mrbgem templates)
  - ✅ Commit: cc054d9 - Add --with-mrbgem option
  - ✅ Support multiple mrbgems
  - ✅ Tests: 199 passing, generate single and multiple mrbgems
- ✅ `--author "Name"` option (get from git config user.name)
  - ✅ Already implemented in prepare_variables method
- ✅ `--path PATH` option (create project in specified directory)
  - ✅ Already implemented in determine_project_root method
- ✅ RuboCop clean, coverage 88.69% (exceeds 85%/60% requirement)

**Current Status**:
- Tests: 199 tests passing, 100% pass rate
- Coverage: 88.69% line, 66.67% branch
- RuboCop: 0 violations
- All 3 commits on branch

### ✅ Phase 4: Documentation (COMPLETE)

- ✅ Update README.md "Quick Start" section (start with `ptrk init` command)
  - ✅ Commit: f2e407d - Updated Quick Start with ptrk init steps
  - ✅ Added option flags documentation (--author, --path, --with-ci, --with-mrbgem)
  - ✅ Updated development status (199 tests, 88.69% coverage)
  - ✅ Added Project Initialization section to Commands Reference
- ✅ Update SPEC.md with `ptrk init` command reference and full specification
  - ✅ Comprehensive `ptrk init` command documentation (103 lines)
  - ✅ Directory structure documentation with tree view
  - ✅ Detailed examples for all option combinations
  - ✅ Operation steps explained step-by-step
- ✅ Update docs/CI_CD_GUIDE.md (mention `--with-ci` option)
  - ✅ Commit: baa2e10 - Added Option A: ptrk init --with-ci (recommended)
  - ✅ Option B for manual workflow copy (for existing projects)
  - ✅ Clarified recommended approach for new projects
- ✅ Create docs/PROJECT_INITIALIZATION_GUIDE.md (detailed user guide)
  - ✅ Commit: 43d2335 - Comprehensive 386-line user guide
  - ✅ Quick start examples with command variations
  - ✅ Detailed option explanations with use cases
  - ✅ Project structure walkthrough with descriptions
  - ✅ Troubleshooting section with 5+ solutions
  - ✅ Next steps guide after initialization
  - ✅ Links to related documentation

**Documentation Summary** (Phase 4):
- 7 commits total (code + docs)
- 199 tests passing, 100% pass rate
- 88.69% line coverage, 66.67% branch coverage
- RuboCop: 0 violations
- All documentation in English, consistent style

### Phase 5: User Testing (PENDING)

- [ ] Test ptrk init in playground/ (project with all options)
- [ ] Verify all generated files are correct and functional
- [ ] Test GitHub Actions workflow CI/CD execution
- [ ] Verify mrbgem generation and compilation
- [ ] Create user FAQ for common issues
- [ ] Document any user experience improvements found

**Success Criteria**:
- New users can create complete projects with `ptrk init` command ✅
- Manual setup steps reduced from 10+ to 0 ✅
- All generated files follow project conventions ✅
- Tests cover all code paths (≥85% line coverage) ✅

---

## Quality Gates

All features must meet these criteria before merging:

### Pre-Commit Checks (Local Development)

- ✅ All tests passing (197+ tests): `bundle exec rake test`
- ✅ RuboCop: 0 violations: `bundle exec rubocop`
- ✅ Coverage: ≥85% line, ≥60% branch: `bundle exec rake ci`
- ✅ **Documentation updated** (Priority 3 Phase 1): If code changed, related docs reviewed and updated in same commit. See `.claude/docs/documentation-structure.md` for file mapping.
- ✅ **rbs-inline annotations added** (Priority 1+): Inline annotations for all new/modified public methods
- ✅ **RBS files generated** (Priority 1+): `rake rbs:generate` creates/updates .rbs files in sig/
- ✅ **Steep check passing** (Priority 1+): `steep check` returns no errors on generated .rbs

### Pre-Push Checks (Final Verification)

- ✅ Documentation updated (SPEC.md, README.md, relevant guides)
- ✅ YARD comments added for public methods (Priority 2+)
- ✅ Architecture docs updated if design changed (docs/architecture/)
- ✅ TODO.md updated (completed tasks removed, new issues added)

### Commit Message Quality

- ✅ Imperative mood ("Add feature" not "Added feature")
- ✅ Concise first line (<50 chars)
- ✅ Detailed body if needed (wrap at 72 chars)
- ✅ References related issues/PRs if applicable
