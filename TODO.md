# TODO: Project Maintenance Tasks

## Future Enhancements (Optional)

### CI/CD Integration

- [ ] Branch Protection Rules (Local execution with gh CLI)
  - [ ] Configure branch protection for `main` branch
  - [ ] Require status checks: `test` job must pass
  - [ ] Require branches to be up to date before merging
  - [ ] Optional: Require pull request reviews
  - [ ] Prevent force pushes and deletions

### CLI Command Structure Refactoring

- [x] Clarify "environment" terminology
  - [x] `pra env` → Manages environment definitions (`.picoruby-env.yml`)
  - [x] `pra build` → Manages build environments (`build/` directories)
  - [x] Added terminology documentation and clarified code comments/messages
  - [ ] Consider renaming commands in future if needed (e.g., `pra build-env` or `pra workspace`)

- [x] Reorganize R2P2 device tasks under `pra device` namespace
  - [x] Move `flash`, `monitor` to `pra device flash`, `pra device monitor`
  - [x] Add `pra device build` command (delegates to `rake build`)
  - [x] Add `pra device setup_esp32` command (delegates to `rake setup_esp32`)
  - [x] Use metaprogramming to transparently delegate all R2P2-ESP32 Rake tasks
  - [x] Avoid manual decoration for each task

- [ ] Enhance `pra build setup` for complete build preparation
  - [ ] Add PicoRuby build step (call `rake setup_esp32` via ESP-IDF env)
  - [ ] Ensure `pra build setup` handles all pre-build requirements
  - [ ] Update documentation to reflect `pra build setup` capabilities

- [ ] Update esp32-build.yml template for correct pra command flow
  - [ ] Ensure workflow uses: `pra cache fetch` → `pra build setup` → `pra device build`
  - [ ] Remove internal path exposure (`.cache/*/R2P2-ESP32`)
  - [ ] Remove redundant `pra patch apply` (already done in `pra build setup`)
  - [ ] Validate workflow aligns with local development workflow

- [ ] Add CI/CD update command
  - [ ] Implement `pra ci update` to refresh workflow template

### Documentation Reorganization (Context Window Optimization)

- [x] Split SPEC.md (638 lines) into `.claude/docs/spec/` directory
  - [x] Create `architecture.md` - Design Principles (Immutable Cache, Environment Isolation, Patch Persistence, Task Delegation)
  - [x] Create `cache-management.md` - Cache Commands (`pra cache list/fetch/clean/prune`, 3-level submodule traversal)
  - [x] Create `build-environment.md` - Build Commands (`pra build setup/clean/list`, env-hash format)
  - [x] Create `patch-system.md` - Patch Commands (`pra patch export/apply/diff`)
  - [x] Create `cli-reference.md` - Environment/Delegation Commands (`pra env`, `pra flash`, `pra monitor`, Naming Conventions, Configuration File, Workflow Examples, Troubleshooting)

- [x] Restructure `.claude/skills/picoruby-constraints/`
  - [x] Create `SKILL.md` (30-35 lines: core constraints, memory limits, PicoRuby vs CRuby table, available/unavailable stdlib)
  - [x] Create `reference.md` (examples and references)
  - [x] Update skill description: "Memory constraints and stdlib limitations for ESP32 PicoRuby development"

- [x] Restructure `.claude/skills/development-guidelines/`
  - [x] Create `SKILL.md` (35-40 lines: Language, Tone, Code comments style, Git commits format)
  - [x] Create `code-style.md` (Ruby naming, structure, comments, error handling, performance)
  - [x] Create `examples.md` (output examples, git commit examples, documentation standards, file headers)
  - [x] Update skill description: "Coding standards, naming conventions, and output style"

- [x] Restructure `.claude/skills/project-workflow/`
  - [x] Create `SKILL.md` (35-40 lines: Role summary, directory structure, Rake safety matrix, git safety, session flow)
  - [x] Update skill description: "Development workflow, build system permissions, and git safety protocols"

- [x] Create `.claude/docs/output-style.md` (25 lines: Response Format, Code blocks, Good/bad examples)

- [x] Create `.claude/docs/git-safety.md` (20 lines: Commits, Forbidden commands, Safe commands)

- [x] Create `.claude/docs/testing-guidelines.md` (20 lines: Test Coverage, Development vs CI)

- [x] Simplify CLAUDE.md (93 → 45 lines)
  - [x] Keep: Your Role, Core Principles, Output Style, Git & Build Safety (condensed)
  - [x] Delete: Skills table, Testing & Quality details, Workflow section, TODO Management section
  - [x] Add: @imports for `.claude/docs/output-style.md`, `git-safety.md`, `testing-guidelines.md`

- [x] Delete or relocate SETUP.md
  - [x] Decide: DELETE (if legacy) or MOVE to docs/SETUP.md (user-facing, not loaded by Claude)
  - [x] Current assessment: Most content duplicated in README.md and SPEC.md

- [x] Verify updates
  - [x] Confirm README.md Terminology section aligns with new doc structure
  - [x] Test all @imports in new CLAUDE.md resolve correctly
  - [x] Verify skills descriptions are specific enough for Claude to load contextually
