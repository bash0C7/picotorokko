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
- Use templates in `docs/` and `docs/github-actions/`

## Documentation Locations

**For gem developers** (you read/write):
- `.claude/docs/` — Internal design documents
- `.claude/skills/` — Reusable workflows
- `AGENTS.md` — This file
- `CLAUDE.md` — Development guidelines
- `lib/picotorokko/` — Source code

**For ptrk users** (they read):
- `README.md` — Installation and quick start
- `docs/SPECIFICATION.md` — Complete command specification
- `docs/` — User guides
- `docs/github-actions/` — Workflow templates

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

**Local Development**:
```bash
bundle exec rake              # ✅ Unit tests only (~1.3s)
bundle exec rake test         # ✅ Fast tests: unit + integration (~31s)
bundle exec rake test:all     # ⚠️  All tests including scenario (~35s, before pushing)
```

**CI Pipeline** (`bundle exec rake ci`):
```bash
bundle exec rake ci           # ✅ Runs all tests + RuboCop + coverage
```

The CI task automatically includes scenario tests as part of comprehensive validation. This keeps local development fast while ensuring full coverage verification before merge.

## Documentation Updates

When code changes affect behavior:

@import .claude/skills/documentation-standards/SKILL.md

**Quick Reference**:
1. Command behavior changed? → Update `docs/SPECIFICATION.md` + `README.md`
2. Template/workflow changed? → Update user guides in `docs/`
3. Public API changed? → Update rbs-inline annotations
4. Architecture changed? → Update `.claude/docs/` design documents

## Specialized Subagents

The project includes specialized subagents for focused development tasks. **Use these subagents instead of running commands directly** to keep your local development session clean and focused.

### Test Execution via Subagents

**For running tests locally**:
- ⚠️ NEVER run `bundle exec rake test` directly in Claude Code
- ✅ Use the `debug-workflow` subagent to run and debug tests
- ✅ Use the `Project Workflow` skill for build system guidance

**Example**:
```
Use the debug-workflow subagent to help me debug test/scenario/new_scenario_test.rb
```

### debug-workflow Subagent

**Location**: `.claude/agents/debug-workflow.md`

**Purpose**: Helps developers debug failing scenario tests using the Ruby debug gem

**Invoke with**:
```
Use the debug-workflow subagent to help me debug test/scenario/your_test.rb
```

**What it does**:
- Analyzes test structure and identifies failing assertions
- Guides interactive step execution with `ruby -r debug`
- Interprets debug output, variable values, and file system states
- Teaches the four core debugging patterns:
  1. Command success checking (status codes, output)
  2. File system verification (directory/file existence)
  3. Assertion pattern matching (regex, includes)
  4. Multi-step workflow debugging (state after each step)

**When to use**:
- Test is failing and you need to understand why
- You're in a debug session and need guidance on next steps
- You want to learn the step execution workflow
- You need help interpreting complex test behavior

**Key Features**:
- References official debugging guide (`.claude/docs/step-execution-guide.md`)
- Integrates with t-wada TDD cycle
- Provides debugger command reference
- Shows practical debugging patterns specific to scenario tests
- Links to test helpers and project-specific context

**Subagent Tools**: Bash, Read, Grep
**Model**: Haiku (fast, cost-effective pattern-based guidance)

### Git Operations

**For git commits**:
- ✅ Use `git add`, `git status`, `git log`, `git diff` (read-only, always safe)
- ⚠️ For committing: Use the Bash tool with proper git protocols (no --force, no --amend without checking authorship)
- 🚫 Never: `git reset --hard`, `git rebase -i`, `git push --force`

See the Bash tool's git safety protocol for safe commit procedures.

### RuboCop Auto-Fix

**For running RuboCop**:
- Use `bundle exec rubocop --auto-correct-all` via Bash tool
- RuboCop violations must be fixed before committing
- Never add `# rubocop:disable` comments—refactor the code instead

