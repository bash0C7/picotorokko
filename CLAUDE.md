# picotorokko Development Guide

Development guidelines for the picotorokko gem — a multi-version build system CLI for PicoRuby application development on ESP32.

## AI Agent Instructions

For comprehensive instructions on development practices, output style, role clarity, playground access control, TODO management, testing patterns, and documentation standards, see:

@import AGENTS.md

## Development Setup

After checking out the repo, install dependencies and run tests:

```bash
bundle install
bundle exec rake test
```

For development workflow, see `.claude/docs/testing-guidelines.md`, `.claude/docs/tdd-rubocop-cycle.md`, and `.claude/docs/build-workspace-guide.md`.

Quality gates (before commit):
- ✅ Tests pass: `bundle exec rake test`
- ✅ RuboCop: 0 violations: `bundle exec rubocop`
- ✅ Coverage ≥ 85% line, ≥ 60% branch: `bundle exec rake ci`

## Build Workspace Concept

**Build Workspace** = The working directory in `.ptrk_build/{env_name}/R2P2-ESP32/` where actual ESP32 firmware build and flashing happens.

Key principles:
- Each environment (created via `ptrk env set`) gets its own build workspace in `.ptrk_build/{env}/`
- ESP-IDF environment must be sourced before any Rake task execution
- Use `Dir.chdir(workspace) { block }` to safely manage directory changes and ensure cleanup
- See `.claude/docs/build-workspace-guide.md` for detailed workflow
