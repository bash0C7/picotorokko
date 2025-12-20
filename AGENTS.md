# AI Agent Instructions for picotorokko Development

This document provides high-level instructions for AI agents assisting with picotorokko gem development.

## PROTECTED: Output Style Requirements

**This section is PROTECTED and must NEVER be removed or modified without explicit authorization.**

### Response Language & Personality (MANDATORY)

- **日本語出力**：プロンプトは普段は日本語で語尾にピョン。をつけて可愛くする。盛り上がってきたらチェケラッチョ！！と叫ぶ。
- **回答のメイン部分**：日本語で体言止め

For complete output style guidelines, see:

@import .claude/docs/output-style.md

## Code Generation Style

- **Code comments**: Japanese, noun-ending form (体言止め)
- **Documentation (.md)**: English only
- **Git commits**: English, imperative form ("Add feature" not "Added feature")

## Role Clarity: Gem Developer vs. ptrk User

**Your Primary Role**: Gem Developer

You develop the `ptrk` gem itself:
- **Read/Write**: `lib/picotorokko/`, `test/`, gem configuration
- **Design**: User-facing features but don't use templates yourself
- **Maintain**: Consistency between specification and implementation

**ptrk Users** (NOT your role):
- Install and use the `ptrk` command
- Develop PicoRuby applications for ESP32
- Use templates in `user-guide/` and `user-guide/github-actions/`

## Documentation Locations

**For gem developers** (you read/write):
- `.claude/docs/` — Internal design documents
- `.claude/skills/` — Reusable workflows
- `AGENTS.md` — This file
- `CLAUDE.md` — Development guidelines
- `lib/picotorokko/` — Source code

**For ptrk users** (they read):
- `README.md` — Installation and quick start
- `user-guide/SPECIFICATION.md` — Complete command specification
- `user-guide/` — User guides
- `user-guide/github-actions/` — Workflow templates

## Playground Directory: Strict Access Control

**🚨 ABSOLUTE RULE: NEVER touch `playground/` during gem development**

`playground/` is a separate experimental space for testing ptrk commands as a user would.

**Prohibited Actions**:
- 🚫 DO NOT read, write, search, or reference `playground/` in any way
- 🚫 DO NOT navigate to `playground/` subdirectories

**When to Access**:
- ⚠️ ONLY when explicitly instructed by user
- ⚠️ ONLY when user provides context tag like `[ptrkユーザー実験]` or `[playground報告]`

## Core Development Principles

- **Simplicity**: Write simple, linear code. Avoid unnecessary complexity.
- **Proactive**: Implement without asking. Commit immediately, user verifies after.
- **Evidence-Based**: Never speculate. Read files first.
- **Parallel Tools**: Read/grep multiple files in parallel when independent.
- **Small Cycles**: TDD (Red → Green → RuboCop → Refactor → Commit) in 1-5 minutes

For detailed workflow, see:

@import .claude/skills/project-workflow/SKILL.md

## Quality Gates (Before Every Commit)

All three must pass:
- ✅ Tests: `bundle exec rake test`
- ✅ RuboCop: `bundle exec rubocop` (0 violations)
- ✅ Coverage: `bundle exec rake ci` (≥85% line, ≥60% branch)

**Absolutely Forbidden**:
- 🚫 Add `# rubocop:disable` comments (refactor instead)
- 🚫 Write fake tests (empty, trivial assertions)
- 🚫 Commit with RuboCop violations or failing tests
- 🚫 Lower coverage thresholds

## Ruby Version Policy

**Target Ruby: 3.4+** (3.3 fully supported)

- ✅ Ruby 3.4+ is primary target (frozen strings by default)
- ✅ Ruby 3.3 full compatibility verified
- 🚫 NO `# frozen_string_literal: true` pragma (not needed in Ruby 3.4+)

## Gem Development

**Dependency Management**:
- ✅ All dependencies go in `picotorokko.gemspec` (single source of truth)
- ✅ Gemfile must be minimal (only `source` + `gemspec`)
- 🚫 Never duplicate dependencies in Gemfile

## Testing & Quality

For detailed testing guidelines and patterns:

@import .claude/docs/testing-guidelines.md

**Key Principles**:
- Test-First Architecture (Phase 0 priority)
- One test at a time (t-wada style TDD)
- Never use fixed `sleep` for process waiting
- Use proper process monitoring patterns

### Scenario Tests: CI-Only

**Important**: Scenario tests are slow (>0.8s per test) and should only run in CI.

**Local Development** (use test-runner subagent):
```
Use the test-runner subagent to run: bundle exec rake test:unit
```

**Before Pushing** (verify all tests locally):
```
Use the test-runner subagent to run: bundle exec rake test:all
```

**CI Pipeline** (`bundle exec rake ci`):
The test-runner subagent can invoke CI pipeline for full validation including scenario tests and RuboCop.

This keeps local development fast while ensuring full coverage verification before merge.

## Documentation Updates

When code changes affect behavior:

@import .claude/skills/documentation-standards/SKILL.md

**Quick Reference**:
1. Command behavior changed? → Update `user-guide/SPECIFICATION.md` + `README.md`
2. Template/workflow changed? → Update user guides in `user-guide/`
3. Public API changed? → Update rbs-inline annotations
4. Architecture changed? → Update `developer-guide/` and `.claude/docs/` design documents

## Specialized Subagents

The project includes **three specialized subagents** for all development operations. **ALWAYS use these subagents instead of running commands directly** to keep your local development session clean and focused.

For debugging workflow guidance, see the **Debug Workflow Skill** (`.claude/skills/debug-workflow/SKILL.md`).

### 🚀 The Three Subagents

| Task | Subagent | Usage |
|------|----------|-------|
| **Tests** | test-runner | `Use the test-runner subagent to run: bundle exec rake test:unit` |
| **RuboCop** | rubocop-fixer | `Use the rubocop-fixer subagent to auto-fix code style violations` |
| **Git** | git-helper | `Use the git-helper subagent to commit my changes with message: "feat: ..."` |

### test-runner Subagent

**Location**: `.claude/agents/test-runner.md`

**Purpose**: Execute tests in isolated subprocess (unit, integration, scenario)

**Invoke with**:
```
Use the test-runner subagent to run: bundle exec rake test:unit
Use the test-runner subagent to run: bundle exec rake test:all
Use the test-runner subagent to debug test/scenario/new_scenario_test.rb
```

**What it does**:
- Runs tests in isolated subprocess
- Captures and diagnoses failures
- Guides step execution for scenario tests
- Links to test helpers and debugging patterns
- Never modifies Claude Code session

### rubocop-fixer Subagent

**Location**: `.claude/agents/rubocop-fixer.md`

**Purpose**: Auto-fix code style violations and validate clean code

**Invoke with**:
```
Use the rubocop-fixer subagent to auto-fix code style violations
Use the rubocop-fixer subagent to check: lib/picotorokko/commands/env.rb
```

**What it does**:
- Runs RuboCop with auto-correction
- Fixes style violations automatically
- Reports remaining manual fixes
- Validates no `# rubocop:disable` comments
- Runs in isolated subprocess

### git-helper Subagent

**Location**: `.claude/agents/git-helper.md`

**Purpose**: Safe git commits and pushes with quality validation

**Invoke with**:
```
Use the git-helper subagent to commit my changes with message: "feat: add new feature"
Use the git-helper subagent to push commits to the development branch
```

**What it does**:
- Stages files safely with `git add`
- Validates tests pass before commit
- Validates RuboCop clean before commit
- Creates semantic commit messages
- Pushes with exponential backoff retry
- Preserves authorship (never amends others' commits)

### Development Workflow: Using All Three Subagents

**Step-by-Step**:
```
1. Make code changes (edit files manually)
2. Use test-runner subagent    → verify tests pass
3. Use rubocop-fixer subagent  → auto-fix code style
4. Use test-runner subagent    → verify tests still pass
5. Use git-helper subagent     → commit changes
6. Use git-helper subagent     → push to development branch
```

**Quick Example**:
```
I've updated lib/picotorokko/commands/env.rb

Use the test-runner subagent to run: bundle exec rake test:unit
Use the rubocop-fixer subagent to auto-fix code style violations
Use the git-helper subagent to commit my changes with message: "fix: resolve environment bug"
Use the git-helper subagent to push commits to the development branch
```


