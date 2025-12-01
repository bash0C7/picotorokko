# picotorokko Development Guide

## Project Context

**picotorokko** is a multi-version build system CLI for PicoRuby application development on ESP32.

**Tech Stack**: Ruby 3.4+, Rake, Thor CLI, RuboCop, test-unit, SimpleCov
**Target**: Gem developers maintaining the `ptrk` command-line tool

## AI Agent Instructions

For comprehensive instructions on development practices, output style, role clarity, and workflow guidelines:

@import AGENTS.md

## Development Setup

After checking out the repo:

```bash
bundle install              # Install dependencies
bundle exec rake test       # Run test suite
bundle exec rubocop         # Check code style
bundle exec rake ci         # Full CI check with coverage
```

## Quality Gates (Before Every Commit)

All three must pass:
- ✅ Tests: `bundle exec rake test`
- ✅ RuboCop: `bundle exec rubocop` (0 violations required)
- ✅ Coverage: `bundle exec rake ci` (≥85% line, ≥60% branch)

## Important File Locations

- `/lib/picotorokko/` — Gem source code
- `/test/` — Test suite
- `/.claude/docs/` — Internal development guides
- `/.claude/skills/` — Reusable workflows for AI agents
- `/docs/` — User-facing documentation
- `/docs/SPECIFICATION.md` — Source of truth for command behavior

## Development Workflow

**TDD Cycle**: Red → Green → RuboCop → Refactor → Commit (1-5 minutes per cycle)

See detailed guides:
- `.claude/skills/project-workflow/` — TDD workflow and git safety
- `.claude/docs/testing-guidelines.md` — Test patterns and examples
- `.claude/docs/tdd-rubocop-cycle.md` — Micro-cycle implementation

## Build Workspace Concept

**Build Workspace** = `.ptrk_build/{env_name}/R2P2-ESP32/`

The working directory where ESP32 firmware builds and flashing occur.

Key principles:
- Each environment gets isolated workspace in `.ptrk_build/{env}/`
- Always use `Dir.chdir(workspace) { block }` for safe directory changes
- ESP-IDF must be sourced before any Rake task execution
- See `.claude/docs/build-workspace-guide.md` for detailed workflow

## Code Style Conventions

- **Indentation**: 2 spaces (RuboCop enforced)
- **Comments**: Japanese, noun-ending style (体言止め)
- **Documentation**: English only
- **Git Commits**: English, imperative mood
- **Output Style**: See `.claude/docs/output-style.md`

## Anti-Patterns to Avoid

- 🚫 Adding `# rubocop:disable` comments (refactor instead)
- 🚫 Writing fake or trivial tests
- 🚫 Committing with RuboCop violations or failing tests
- 🚫 Lowering coverage thresholds
- 🚫 Touching `playground/` during gem development (strict separation)
- 🚫 Using fixed `sleep` in tests (use proper process monitoring)
