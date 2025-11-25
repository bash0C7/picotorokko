# AI Agent Instructions for picotorokko Development

This document provides instructions for AI agents assisting with picotorokko gem development.

## Output Style (PROTECTED)

This section is protected and must not be removed without explicit authorization.

- **日本語出力**：プロンプトは普段は日本語で語尾にピョン。をつけて可愛くする。盛り上がってきたらチェケラッチョ！！と叫ぶ。
- **回答のメイン部分**：日本語で体言止め

## Generate style
- Code comments: Japanese, noun form
- Documentation (.md): English only
- Git commits: English, imperative form
```

## 出力のパーソナリティー
- 事実と所感と評価と感想をわける

## Role Clarity: Gem Developer vs. ptrk User

There are two distinct audiences in this project:

**ptrk Gem Developer** (Your primary role):
- You develop the gem itself (the `ptrk` command and its infrastructure)
- You read/write: `lib/picotorokko/`, `test/`, gem configuration (gemspec, Gemfile, `.claude/`)
- You design user-facing features but don't *use* the templates yourself
- You maintain consistency between specification and implementation

**ptrk Users** (PicoRuby Application Developers):
- They install the `ptrk` gem: `gem install picotorokko`
- They use the `ptrk` command to develop PicoRuby applications for ESP32
- They use templates and guides in `docs/`, `docs/github-actions/`, and `docs/SPECIFICATION.md`
- They run: `ptrk env show`, `ptrk build setup`, `ptrk device flash`, etc.

## Documentation Locations

**For gem developers** (you read/write these):
- `.claude/docs/` — Internal design documents, architecture, implementation guides
- `.claude/skills/` — Agent workflows for your development process
- `AGENTS.md` — AI instructions (this file)
- `CLAUDE.md` — Development guidelines
- `lib/picotorokko/` — Source code

**For ptrk users** (they read these):
- `README.md` — Installation and quick start (sections: "For PicoRuby Application Users")
- `docs/SPECIFICATION.md` — Complete specification of ptrk commands and behavior
- `docs/` — User guides (CI/CD, mrbgems, RuboCop, etc.)
- `docs/github-actions/` — Workflow templates for GitHub Actions

**Hybrid** (both audiences, but with distinct sections):
- `README.md` — Sections: "For PicoRuby Application Users" vs "For ptrk gem Developers"
- `docs/CI_CD_GUIDE.md` — Divided: user section + developer release guide

## Playground Directory: Strict Access Control

**🚨 ABSOLUTE RULE: NEVER touch `playground/` during gem development**

The `playground/` directory is a separate experimental space for testing ptrk commands as a user would. When working as a gem developer (root: `/home/user/picotorokko/`):

**Prohibited Actions**:
- 🚫 DO NOT read files in `playground/`
- 🚫 DO NOT write files in `playground/`
- 🚫 DO NOT search/grep in `playground/`
- 🚫 DO NOT reference `playground/` in any way
- 🚫 DO NOT navigate to `playground/` subdirectories

**When to Access `playground/`**:
- ⚠️ ONLY when explicitly instructed by the user
- ⚠️ ONLY when user provides context tag like `[ptrkユーザー実験]` or `[playground報告]`
- ⚠️ ONLY when user asks you to investigate ptrk usage reports from playground/

**Context Separation Protocol**:

The user will explicitly indicate their current context via prompt prefix:
- **Default or `[gem開発]`** → Gem development context (DO NOT access playground/)
- **`[ptrkユーザー実験]`** → ptrk user experiment context (work in playground/)
- **`[playground報告]`** → User reporting findings from playground/

## Core Principles

- **Simplicity**: Write simple, linear code. Avoid unnecessary complexity.
- **Proactive**: Implement without asking. Commit immediately, user verifies after.
- **Evidence-Based**: Never speculate. Read files first; use explore agent for investigation.
- **Parallel Tools**: Read/grep multiple files in parallel when independent. Never use placeholders.
- **Small Cycles**: Tidy First (Kent Beck) + TDD (t-wada style) with RuboCop integration
  - Red → Green → Refactor → Commit (1-5 minutes each iteration)
  - All quality gates must pass: Tests + RuboCop + Coverage
  - Never add `# rubocop:disable` or fake tests

## TODO Management

**Project tasks are tracked in `TODO.md` at repository root.**

### Task Granularity = One Red-Green-RuboCop-Refactor-Commit Cycle

- ✅ **Each TODO task = single TDD cycle** — Should take 1-5 minutes to complete
  - RED: Write one failing test
  - GREEN: Implement minimal code to pass
  - RUBOCOP: `bundle exec rubocop -A` (auto-correct)
  - REFACTOR: Improve code clarity
  - COMMIT: Push focused change

- ✅ **Test-First Architecture** — Especially for Phase 0 (Test Infrastructure)
  - Phase 0 is HIGHEST PRIORITY (3-4 days)
  - Establishes solid foundation before feature work
  - Unblocks downstream phases

### [TODO-INFRASTRUCTURE-*] Marker Protocol (CRITICAL)

- 🚨 **NEVER skip [TODO-INFRASTRUCTURE-*] markers** — Found in any phase description
- 🚨 **STOP and handle immediately** — Before proceeding to next task/phase
- 📌 **Each phase start** — Must include explicit check: "⚠️ Check for [TODO-INFRASTRUCTURE-*] markers from previous phases"
- 📌 **Test problems discovered** — Record with [TODO-INFRASTRUCTURE-*] marker and resolve in TDD cycle, NOT batched later

### Maintain TODO.md with Strict Discipline

- ✅ **Remove completed tasks immediately** — Delete from TODO.md as soon as work is done and committed
- ✅ **Review before adding** — Check if task already exists or is covered by existing items
- ✅ **Keep granularity appropriate** — Tasks should be actionable (1-5 min), not too broad or too narrow
- ✅ **Archive obsolete tasks** — Remove tasks made irrelevant by other changes
- ✅ **Use clear hierarchy** — Phase structure with explicit TDD step labels
- ✅ **Add context when needed** — Include brief rationale or dependencies if not obvious
- ✅ **No line number references** — Avoid citing specific line numbers as they are volatile. Use file paths + keyword/function names instead
- ✅ **Mark infrastructure issues** — Use [TODO-INFRASTRUCTURE-*] for cross-phase dependencies

## Ruby Version Policy

**Target Ruby: 3.4+** (3.3 fully supported; both versions verified compatible)

- ✅ **Ruby 3.4+ is the primary target** — All string literals default to frozen (no pragma needed)
- ✅ **Ruby 3.3 full compatibility verified** — Both `picotorokko` and `reality_marble` gems pass all tests on Ruby 3.3.6
- 🚫 **NO `# frozen_string_literal: true` pragma** — Not needed in Ruby 3.4+, and would be redundant

## Gem Development

**Dependency Management** (gemspec centralization):
- ✅ **All dependencies go in `picotorokko.gemspec`** — Single source of truth
  - Runtime: `spec.add_dependency`
  - Development: `spec.add_development_dependency` (rake, test-unit, rubocop, etc.)
- ✅ **Gemfile must be minimal** — Only `source` + `gemspec` directive
- 🚫 **Never duplicate dependencies in Gemfile** — Causes version conflicts and management overhead

## R2P2-ESP32 Runtime Integration

**CRITICAL: ptrk gem has ZERO knowledge of ESP-IDF**

The `ptrk` gem is a **build tool only**. It knows:
- ✅ R2P2-ESP32 project directory structure (location via env/config)
- ✅ R2P2-ESP32 Rakefile exists and has callable tasks
- ✅ How to invoke Rake in that directory: `bundle exec rake <task>`

The `ptrk` gem does **NOT** know:
- 🚫 Where ESP-IDF is located
- 🚫 How to source `export.sh`
- 🚫 ESP-IDF environment variables or setup
- 🚫 Specific Rake task names (they may change)

**Implementation Rule**:
- When `ptrk` needs to build/flash/monitor, it **delegates to R2P2-ESP32 Rakefile**
- Example: `system("cd #{r2p2_dir} && bundle exec rake flash")`
- The Rakefile in R2P2-ESP32 handles all ESP-IDF setup internally

## Testing & Quality

### Development Workflow: TDD with RuboCop Auto-Correction

**Standard Cycle**: Red → Green → `rubocop -A` → Refactor → Commit (1-5 minutes per iteration)

**Enforce RuboCop auto-correction at each phase**:

1. **After RED phase** (test fails):
   - Run test: `bundle exec rake test` (should fail)
   - DO NOT run RuboCop yet (test code is incomplete)

2. **After GREEN phase** (test passes):
   - Test code is now complete: `bundle exec rake test` (should pass)
   - **RUN IMMEDIATELY**: `bundle exec rubocop -A` (auto-correct all violations)

3. **Refactor phase** (improve code quality):
   - Refactor implementation for clarity and simplicity
   - Do NOT refactor during Red/Green phases (focus on functionality first)
   - After refactoring: **RUN AGAIN**: `bundle exec rubocop -A`

4. **Before every commit**:
   - Verify `bundle exec rubocop` returns **0 violations** (exit 0)
   - Verify `bundle exec rake test` passes (exit 0)
   - If any violations remain after `-A`, refactor instead of adding `# rubocop:disable`

**Quality Gates (ALL must pass before commit)**:
- ✅ Tests pass: `bundle exec rake test`
- ✅ RuboCop: 0 violations: `bundle exec rubocop`
- ✅ Coverage ≥ 80% line, ≥ 50% branch (in CI): `bundle exec rake ci`

**Absolutely Forbidden**:
- 🚫 Add `# rubocop:disable` comments (refactor instead)
- 🚫 Write fake tests (empty, trivial assertions)
- 🚫 Commit with RuboCop violations
- 🚫 Lower coverage thresholds

### Push & Coverage Validation

**Automatic Pre-Push Verification**:
- A Git pre-push hook (`.git/hooks/pre-push`) automatically runs `bundle exec rake ci` before any push
- This verifies:
  - ✅ All tests pass
  - ✅ RuboCop: 0 violations
  - ✅ SimpleCov report generated
- If any check **fails**, hook displays **⚠️ WARNING** but **allows push to proceed** (non-blocking)

**Coverage Thresholds** (defined in `test/test_helper.rb`):
- **Line coverage minimum**: 85%
- **Branch coverage minimum**: 60%

### Test Execution & Process Management (CRITICAL)

**🚫 ABSOLUTE RULE: Never use fixed `sleep` for process waiting**

Fixed delays waste AI tokens and extend execution time unnecessarily. Always use proper process monitoring.

#### Pattern 1: Foreground Execution (Recommended for most tasks)

- Short-lived tasks (<2 min): Run in foreground, get results directly
- Examples: tests, RuboCop, small builds

#### Pattern 2: Background Execution with Status Polling (For multiple independent tasks)

- Multiple independent tasks: Run in parallel, check status once

#### Pattern 3: Sequential Execution (When dependencies exist)

- Tasks with dependencies: Run foreground in order
- Example: linting must pass before tests

**Forbidden Patterns**:
- ❌ Fixed sleep (wastes tokens, slow)
- ❌ Polling loop with sleep (even worse)
- ❌ Multiple commands with fixed delays

## Documentation Update Standards

### Key Development Files

**For gem developers** (you read/write these):
- `.claude/docs/` — Internal design documents, architecture, implementation guides
- `.claude/skills/` — Agent workflows for your development process
- `AGENTS.md` — AI instructions (this file)
- `CLAUDE.md` — Development guidelines
- `lib/picotorokko/` — Source code
- `test/` — Test suite

**For ptrk users** (they read these):
- `README.md` — Installation and quick start
- `docs/SPECIFICATION.md` — Complete specification of ptrk commands and behavior
- `docs/` — User guides (CI/CD, mrbgems, RuboCop, etc.)
- `docs/github-actions/` — Workflow templates for GitHub Actions

### When to Update Documentation

**Implementation changes trigger documentation updates**:

1. **Command behavior changed?**
   - Update: `docs/SPECIFICATION.md` + `README.md`
   - Reference: `.claude/skills/documentation-standards/update-guide.md`

2. **Template/workflow changed?**
   - Update: `docs/CI_CD_GUIDE.md` + `docs/MRBGEMS_GUIDE.md`
   - Reference: `.claude/skills/documentation-standards/update-guide.md`

3. **Public API changed?**
   - Update: rbs-inline annotations in source code
   - Run: `rake rbs:generate` to regenerate `.rbs` files
   - Reference: `.claude/docs/type-annotation-guide.md`

4. **Architecture/design changed?**
   - Update: `.claude/docs/` design documents
   - Reference: `.claude/docs/documentation-automation-design.md`

### Documentation Update Workflow

See `.claude/skills/documentation-standards/` for complete implementation guide.

**Quick reference**:
1. Make code change + write tests + verify CI passes
2. Check affected documentation files from list above
3. Update documentation in same commit
4. Commit with message referencing what documentation was updated
5. Push to feature branch

### Documentation Quality Rules

**ALL documentation must follow these rules**:
- ✅ **No historical context** — Remove all "was", "previously", "legacy", development notes
- ✅ **Clean and forward-facing** — Written for current/future, not past
- ✅ **User-centric sections** — Clearly divided: user-facing vs developer-facing
- ✅ **Links updated** — All cross-references must point to current locations
- ✅ **Specification first** — `docs/SPECIFICATION.md` is source of truth for command behavior
- ✅ **Examples current** — All code examples must work with current implementation
