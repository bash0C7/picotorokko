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

**CRITICAL**: rbs-inline is becoming part of Ruby's standard tooling. This makes it the primary choice for type annotations, NOT YARD.

- [ ] **Research rbs-inline deeply (HIGHEST PRIORITY)**
  - **Background**: rbs-inline allows writing RBS as inline comments, auto-generates .rbs files
  - **Future**: Will become Ruby language standard (part of core tooling)
  - **Survey usage patterns**:
    - Official examples: https://github.com/soutaro/rbs-inline
    - Real-world gems using rbs-inline
    - Best practices from Ruby core team
  - **Syntax examples**:
    ```ruby
    # @rbs (String, count: Integer) -> Array[String]
    def process(name, count:)
      # Implementation
    end

    # @rbs @items: Array[String]
    attr_reader :items
    ```
  - **Tools integration**:
    - `rbs-inline` command: Generate .rbs from inline comments
    - Steep integration: Use generated .rbs for type checking
    - CI/CD: Auto-generate .rbs as part of build process
  - Document findings in `.claude/docs/rbs-inline-research.md`

- [ ] **Evaluate rbs-inline vs YARD integration strategy**
  - **Key Question**: Should we use YARD at all, or go rbs-inline only?
  - **Option A**: rbs-inline for types + YARD for documentation
    - Pros: Best of both worlds (types + rich docs)
    - Cons: Potential duplication, sync issues
  - **Option B**: rbs-inline only, generate docs from RBS
    - Pros: Single source of truth, no sync issues
    - Cons: Less rich documentation than YARD
  - **Recommendation**: Document decision with rationale
  - Consider: RBS documentation generators (rbs-doc, steep docs)

- [ ] **Research Steep configuration**
  - Review Steep setup for gem projects
  - Understand Steepfile configuration options
  - Evaluate integration with CI/CD (GitHub Actions)
  - Test with rbs-inline generated .rbs files

- [ ] **Design type annotation strategy (rbs-inline first)**
  - **Decision**: Use rbs-inline as primary annotation method
  - Prioritize files for type coverage (start with public API: `lib/picotorokko/cli.rb`, commands)
  - Define rbs-inline annotation guidelines in `.claude/docs/type-annotation-guide.md`
  - Plan gradual rollout (which files first?)
  - **Documentation strategy**: Decide if YARD is needed or RBS docs sufficient

- [ ] **Create proof-of-concept**
  - Add rbs-inline annotations to one file (e.g., `lib/picotorokko/env.rb`)
  - Run `rbs-inline` to generate .rbs file
  - Configure Steep to use generated .rbs
  - Run `steep check` and verify it works
  - Compare with YARD: Does RBS provide enough documentation?
  - Document setup process and lessons learned

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

#### Phase 5: RBS-Driven TDD Workflow Integration (CRITICAL)

**Goal**: Integrate RBS type definitions into the core TDD cycle (Red-Green-Refactor)

**Rationale**: Type-First TDD ensures type safety from the beginning and keeps types synchronized with implementation throughout development.

- [ ] **Design Type-First TDD Workflow**
  - Document the new cycle: Type → RED → GREEN → RuboCop → REFACTOR (+ Type Update) → COMMIT
  - Define when to write types: Before tests (Type-First) or during refactor
  - Document in `.claude/docs/type-first-tdd.md`

- [ ] **Integrate RBS into Micro-Cycle (CLAUDE.md update)**
  - **RED Phase**: Write type signature BEFORE test
    ```ruby
    # @rbs (String, Integer) -> Array[String]
    def process_data(name, count)
      # Implementation comes in GREEN phase
    end
    ```
  - **GREEN Phase**: Implement to satisfy both test AND type
    - Run `steep check` alongside `rake test`
    - Fix type errors before moving to refactor
  - **REFACTOR Phase**: Update types if signature changes
    - Refactor implementation → Update RBS inline annotations
    - Re-run `steep check` to verify type consistency
    - Ensure types still match actual behavior

- [ ] **Add Type Checking to Quality Gates**
  - Update Micro-Cycle checklist in CLAUDE.md:
    ```markdown
    1. TYPE: Write RBS inline annotation for new method
    2. RED: Write failing test
       bundle exec rake test → ❌
    3. GREEN: Implement minimal code
       bundle exec rake test → ✅
       steep check → ✅ (verify types match)
    4. RUBOCOP: Auto-fix violations
       bundle exec rubocop -A
    5. REFACTOR: Improve code + update types if needed
       steep check → ✅ (re-verify after refactor)
    6. COMMIT: All gates pass
       bundle exec rake ci → ✅
    ```

- [ ] **Create Type-Check Rake Task**
  - Add `rake type` task: runs `steep check`
  - Add `rake type:watch` for continuous type checking during development
  - Integrate into `rake dev` workflow

- [ ] **RBS/YARD Synchronization Strategy**
  - Document: RBS is source of truth for types
  - YARD `@param`/`@return` should reflect RBS signatures
  - Add check script: Compare RBS types with YARD annotations
  - Run as part of pre-commit verification

- [ ] **Update CLAUDE.md with Type-First Workflow**
  - Replace current Micro-Cycle with Type-First TDD cycle
  - Add examples: "Adding a new command with types"
  - Document: Types are part of "done" definition
  - Emphasize: Types written BEFORE implementation (like tests)

- [ ] **Test Type-First Workflow with Real Feature**
  - Pick a small new feature (e.g., `ptrk config validate`)
  - Follow Type → RED → GREEN → REFACTOR cycle
  - Document pain points and improvements
  - Iterate on workflow based on experience

---

### 📚 Priority 2: Gem Documentation Generation

**Goal**: Generate comprehensive documentation from source code and markdown files

**Benefits**:
- Always up-to-date documentation (generated from code)
- Unified documentation source (code comments + markdown)
- Professional documentation hosting
- Better discoverability for gem users

**CRITICAL DEPENDENCY**: This priority depends on Priority 1 Phase 1 decision regarding rbs-inline vs YARD.

#### Phase 1: Research & Design (1 day)

**NOTE**: Start AFTER completing Priority 1 Phase 1 (rbs-inline research)

- [ ] **Review Priority 1 Phase 1 decision on rbs-inline vs YARD**
  - If rbs-inline only: Skip YARD setup, focus on RBS doc generators
  - If rbs-inline + YARD: Proceed with YARD integration
  - Document chosen strategy and rationale

- [ ] **Research documentation tools (based on Priority 1 decision)**
  - **Option A (rbs-inline only)**:
    - **rbs-doc** - Generate documentation from RBS files
    - **Steep's RBS docs** - Built-in RBS documentation
    - **RubyDoc.info RBS support** - Check if supported
  - **Option B (rbs-inline + YARD)**:
    - **YARD** - Ruby standard, comment-based documentation
    - **yard-rbs** - YARD plugin for RBS integration
    - Synchronization strategy between rbs-inline and YARD
  - **Common**:
    - **RDoc** - Built-in Ruby tool (fallback option)
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

#### Phase 3: RBS Documentation Integration (1 day)

**NOTE**: Implementation depends on Priority 1 Phase 1 decision (rbs-inline only vs rbs-inline + YARD)

- [ ] **Configure documentation generator for RBS**
  - **If rbs-inline only**:
    - Use rbs-doc or Steep's built-in RBS documentation
    - Configure to read generated .rbs files from sig/ directory
    - Ensure type signatures appear in generated docs
    - Test documentation output quality
  - **If rbs-inline + YARD**:
    - Install yard-rbs plugin for RBS integration
    - Configure YARD to read both inline comments and .rbs files
    - Ensure type signatures from RBS appear in YARD docs
    - Test combined documentation output

- [ ] **Verify type/doc consistency (CRITICAL for Type-First TDD)**
  - **Synchronization Policy**:
    - rbs-inline annotations in source code = Single source of truth
    - Generated .rbs files = Auto-generated, committed to repo
    - Documentation = Generated from rbs-inline annotations (+ YARD if used)
  - If using YARD:
    - Compare YARD `@param`/`@return` with rbs-inline annotations
    - Ensure they match (automated check via `scripts/check_rbs_yard_sync.rb`)
    - Document any discrepancies
    - Pre-commit check enforces synchronization

- [ ] **Add type generation to commit workflow**
  - Final verification before `git commit`:
    1. `rake rbs:generate` → Generate .rbs files from rbs-inline annotations ✅
    2. `steep check` → Types are valid ✅
    3. (Optional) `scripts/check_rbs_yard_sync.rb` → RBS/YARD in sync ✅
    4. `bundle exec rake ci` → All quality gates pass ✅
  - Document in CLAUDE.md as mandatory step
  - Add to Quality Gates section in TODO.md

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
  - [ ] Public API changed? → Update rbs-inline annotations + documentation comments
  - [ ] rbs-inline annotations added/changed? → Run `rbs-inline` to regenerate .rbs files
  - [ ] Generated .rbs files updated? → Run `steep check` to verify type validity
  ```

- [ ] **Add rbs-inline Generation to Pre-Commit Workflow**
  - **Strategy**: rbs-inline annotations in code → .rbs files generated automatically
  - Create Rake task: `rake rbs:generate`
    - Runs `rbs-inline` on all lib/ files
    - Generates .rbs files in sig/ directory
    - Outputs summary of generated types
  - Add to commit checklist:
    1. Write/update rbs-inline annotations in code
    2. Run `rake rbs:generate` to update .rbs files
    3. Run `steep check` to verify generated types
    4. Commit both source code and generated .rbs files
  - Document in CLAUDE.md as mandatory workflow

- [ ] **Optional: Add Documentation Sync Check (if using YARD)**
  - **NOTE**: Only needed if Priority 2 decides to use rbs-inline + YARD
  - Create script: `scripts/check_rbs_yard_sync.rb`
  - Parse rbs-inline annotations from code
  - Parse YARD `@param`, `@return` tags (if present)
  - Compare and report mismatches
  - Add to commit checklist if YARD is used
  - Initially: Warning only (don't block commits)
  - Later: Make mandatory after stabilization

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

### Pre-Commit Checks (Local Development)

- ✅ All tests passing (197+ tests): `bundle exec rake test`
- ✅ RuboCop: 0 violations: `bundle exec rubocop`
- ✅ Coverage: ≥85% line, ≥60% branch: `bundle exec rake ci`
- ✅ **rbs-inline annotations added** (Priority 1+): Inline annotations for all new/modified public methods
- ✅ **RBS files generated** (Priority 1+): `rake rbs:generate` creates/updates .rbs files in sig/
- ✅ **Steep check passing** (Priority 1+): `steep check` returns no errors on generated .rbs
- ✅ **RBS/YARD synchronization** (Priority 1+2, if using YARD): `scripts/check_rbs_yard_sync.rb` passes

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
