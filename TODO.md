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

### 🎯 Priority 1: Type System Integration (RBS + Steep)

**Goal**: Add type annotations and static type checking to improve code quality and IDE support

**Benefits**:
- Early error detection via static analysis
- Better IDE autocomplete and documentation
- Self-documenting code via type signatures
- Gradual adoption (can add types incrementally)

#### Phase 1: Investigation & Design (1-2 days)

- [ ] **Research rbs-inline usage patterns**
  - Survey how other gems use rbs-inline (e.g., ruby/rbs examples)
  - Evaluate inline annotation syntax vs separate .rbs files
  - Document pros/cons of each approach

- [ ] **Research Steep configuration**
  - Review Steep setup for gem projects
  - Understand Steepfile configuration options
  - Evaluate integration with CI/CD (GitHub Actions)

- [ ] **Design type annotation strategy**
  - Decide: inline annotations vs .rbs files (recommend inline for picotorokko)
  - Prioritize files for type coverage (start with public API: `lib/picotorokko/cli.rb`, commands)
  - Define type annotation guidelines in `.claude/docs/`
  - Plan gradual rollout (which files first?)

- [ ] **Create proof-of-concept**
  - Add rbs-inline to one file (e.g., `lib/picotorokko/env.rb`)
  - Configure Steep for that file
  - Run `steep check` and verify it works
  - Document setup process

#### Phase 2: Core API Type Annotations (2-3 days)

- [ ] **Add dependencies to gemspec**
  - Add `rbs` and `steep` as development dependencies
  - Create `Steepfile` configuration
  - Update Rake tasks to include type checking

- [ ] **Annotate public API surface**
  - `lib/picotorokko/cli.rb` - CLI entry point
  - `lib/picotorokko/commands/*.rb` - All command classes
  - `lib/picotorokko/env.rb` - Environment management
  - Each file: Add inline type annotations with rbs-inline syntax

- [ ] **Annotate core infrastructure**
  - `lib/picotorokko/executor.rb` - Executor abstraction
  - `lib/picotorokko/template/engine.rb` - Template engine interface
  - `lib/picotorokko/template/*_engine.rb` - Individual engines

- [ ] **Verify with Steep**
  - Run `steep check` after each annotation batch
  - Fix type errors discovered by Steep
  - Ensure all tests still pass

#### Phase 3: Retroactive Application to Existing Code (1-2 days)

- [ ] **Annotate remaining lib/ files**
  - `lib/picotorokko/patch_applier.rb`
  - `lib/picotorokko/version.rb`
  - Any utility modules

- [ ] **Add Steep to CI pipeline**
  - Update `.github/workflows/main.yml`
  - Add `steep check` step after RuboCop
  - Fail CI if type errors detected

- [ ] **Document type system usage**
  - Add guide to `.claude/docs/type-system.md`
  - Update CLAUDE.md with type annotation workflow
  - Add examples of common patterns

#### Phase 4: Continuous Type Coverage (Ongoing)

- [ ] **Establish type coverage metrics**
  - Track percentage of annotated methods
  - Set target: 80%+ coverage of public methods
  - Add to quality gates in CI

- [ ] **New code requirement**
  - All new methods must have type annotations
  - Add to CLAUDE.md development workflow
  - Include in PR review checklist

---

### 📚 Priority 2: Gem Documentation Generation

**Goal**: Generate comprehensive documentation from source code and markdown files

**Benefits**:
- Always up-to-date documentation (generated from code)
- Unified documentation source (code comments + markdown)
- Professional documentation hosting
- Better discoverability for gem users

#### Phase 1: Research & Design (1 day)

- [ ] **Research documentation tools**
  - **YARD** - Ruby standard, comment-based documentation
  - **RDoc** - Built-in Ruby tool, simpler but less featured
  - **Steep's RBS docs** - If using RBS, can generate docs from types
  - **Jekyll/Docusaurus** - Static site generators for hosting
  - Document recommendations in `.claude/docs/documentation-generation.md`

- [ ] **Survey existing documentation**
  - Identify what should be generated: API reference, guides, examples
  - Map current docs/ structure to generated output
  - Decide: What stays in markdown, what comes from code?

- [ ] **Design documentation structure**
  - Source: Code comments (YARD tags) + RBS types + docs/*.md
  - Output: Static site (GitHub Pages or similar)
  - Define workflow: Generate locally, commit to gh-pages branch, auto-deploy

- [ ] **Investigate hosting options**
  - **GitHub Pages** - Free, simple, integrated with repo
  - **RubyDoc.info** - Automatic for RubyGems, YARD-based
  - **Custom domain** - If needed for branding
  - Recommendation: Start with RubyDoc.info (zero config), add GitHub Pages later if needed

#### Phase 2: YARD Setup & Code Documentation (2-3 days)

- [ ] **Add YARD to development dependencies**
  - Add to gemspec: `spec.add_development_dependency "yard"`
  - Create `.yardopts` configuration file
  - Add Rake task: `rake yard` to generate docs

- [ ] **Document public API with YARD tags**
  - Add `@param`, `@return`, `@example` to all public methods
  - Start with: `lib/picotorokko/commands/*.rb` (user-facing commands)
  - Then: `lib/picotorokko/env.rb`, executor, template engines
  - Follow YARD best practices (link to classes, use markdown in descriptions)

- [ ] **Integrate docs/ markdown files**
  - Configure YARD to include docs/*.md as extra files
  - Add `{file:docs/MRBGEMS_GUIDE.md}` references in code
  - Ensure YARD links to guides from API documentation

- [ ] **Generate and review documentation**
  - Run `yard doc` locally
  - Review generated HTML output
  - Ensure all links work, examples render correctly
  - Iterate on YARD comments for clarity

#### Phase 3: RBS Type Documentation Integration (1 day)

- [ ] **Configure YARD to read RBS types**
  - Install yard-rbs plugin if available
  - Or: Use Steep's RBS documentation generator
  - Ensure type signatures appear in generated docs

- [ ] **Verify type/YARD consistency**
  - Compare YARD `@param` annotations with RBS signatures
  - Ensure they match (CI check if possible)
  - Document any discrepancies

#### Phase 4: Automated Deployment (1 day)

- [ ] **Setup RubyDoc.info integration**
  - Verify gem publishes trigger automatic doc generation on RubyDoc.info
  - Test with pre-release version if needed
  - Add badge to README.md: Documentation link

- [ ] **Optional: GitHub Pages setup**
  - Create `.github/workflows/docs.yml` for doc generation
  - Deploy to `gh-pages` branch on release
  - Configure custom domain if desired

- [ ] **Add documentation to release checklist**
  - Update CONTRIBUTING.md release process
  - Verify docs generated before publishing gem
  - Check RubyDoc.info after release

#### Phase 5: Documentation Maintenance (Ongoing)

- [ ] **Add doc quality to CI**
  - Run `yard stats --list-undoc` in CI
  - Fail if critical methods lack documentation
  - Set target: 90%+ documentation coverage

- [ ] **Update CLAUDE.md workflow**
  - Add documentation step to Micro-Cycle
  - New public methods must have YARD comments
  - Documentation counts as part of "done"

---

### 🔄 Priority 3: Documentation Update Automation

**Goal**: Ensure implementation changes always trigger documentation updates

**Benefits**:
- Prevents docs from becoming stale
- Reduces manual verification burden
- Catches documentation gaps early
- Maintains docs/ and README.md consistency with code

#### Phase 1: CLAUDE.md Workflow Integration (30 minutes)

- [ ] **Extend CLAUDE.md Micro-Cycle section**
  - Add "Documentation Check" step before commit
  - List specific triggers: command changes → SPEC.md, template changes → MRBGEMS_GUIDE.md
  - Reference `.claude/docs/documentation-structure.md` for details
  - Make it part of quality gates (like RuboCop)

- [ ] **Add documentation checklist to commit workflow**
  ```markdown
  📝 **Documentation Check** (before commit):
  - [ ] Command behavior changed? → Update SPEC.md + README.md
  - [ ] New/changed commands? → Update CLI reference
  - [ ] Directory structure changed? → Update guides (MRBGEMS_GUIDE.md, CI_CD_GUIDE.md)
  - [ ] Templates modified? → Update docs/github-actions/ + guides
  - [ ] Public API changed? → Update YARD comments + RBS types
  ```

- [ ] **Link to documentation-structure.md**
  - Add prominent reference in CLAUDE.md
  - Ensure Claude reads it during planning phase

#### Phase 2: Claude Skill for Documentation Sync (2-3 hours)

- [ ] **Create `.claude/skills/documentation-sync/SKILL.md`**
  - Define skill purpose: Detect and update stale documentation
  - Map file changes to affected docs (lib/picotorokko/commands/ → SPEC.md, README.md)
  - Provide step-by-step workflow for syncing docs

- [ ] **Add detection logic**
  - Check `git diff` for changed implementation files
  - Generate checklist of potentially affected docs
  - Prompt review of each doc with proposed changes

- [ ] **Test skill with recent changes**
  - Simulate a command change
  - Invoke skill manually
  - Verify it detects correct documentation files
  - Iterate on detection logic

#### Phase 3: Git Post-Commit Hook (Optional, 4-6 hours)

- [ ] **Create `.git/hooks/post-commit` script**
  - Detect changes to `lib/picotorokko/commands/`, `lib/picotorokko/env.rb`, etc.
  - Print warning if docs may need updates
  - Non-blocking (exit 0 always)
  - Suggest running documentation-sync skill

- [ ] **Add hook installation to setup**
  - Document in CONTRIBUTING.md
  - Optionally: Add `rake setup` task to install hook
  - Ensure developers are aware of the hook

- [ ] **Test hook behavior**
  - Make implementation change
  - Commit (hook should trigger)
  - Verify warning message is helpful
  - Ensure development flow not disrupted

#### Phase 4: CI Documentation Validation (Future)

- [ ] **Design doc consistency checker**
  - Compare documented commands in SPEC.md with actual CLI
  - Detect missing/outdated command documentation
  - Run as part of CI (non-blocking warning initially)

- [ ] **Implement checker script**
  - Parse SPEC.md for command references
  - Run `ptrk --help`, `ptrk env --help`, etc.
  - Compare output with documented commands
  - Report discrepancies

- [ ] **Add to GitHub Actions workflow**
  - Run after main tests
  - Post comment on PR if docs outdated
  - Initially: Warning only (don't fail CI)
  - Later: Make required check after stabilization

---

## Quality Gates

All features must meet these criteria before merging:

- ✅ All tests passing (197+ tests)
- ✅ RuboCop: 0 violations
- ✅ Coverage: ≥85% line, ≥60% branch
- ✅ Documentation updated (SPEC.md, README.md, relevant guides)
- ✅ YARD comments added for public methods (Priority 2+)
- ✅ RBS type annotations added (Priority 1+)
- ✅ Steep check passing (Priority 1+)
