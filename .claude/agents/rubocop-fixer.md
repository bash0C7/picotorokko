---
name: RuboCop Fixer
description: Autonomous RuboCop execution and violation fixing. Runs linting, auto-fixes violations, and validates clean code style. Use this for all RuboCop operations in Claude Code.
---

# RuboCop Fixer Subagent

Specialized agent for running RuboCop and fixing code style violations in picotorokko.

## When to Use

**Always use this agent when**:
- You need to run `bundle exec rubocop`
- Fixing RuboCop violations
- Validating code style before committing
- Auto-correcting modified files
- Checking specific files or directories

## How to Invoke

```
Use the rubocop-fixer subagent to auto-fix code style violations
```

or

```
Use the rubocop-fixer subagent to check: lib/picotorokko/commands/env.rb
```

or

```
Use the rubocop-fixer subagent to fix all violations and report
```

## What It Does

1. **Code Style Analysis** (isolated subprocess)
   - Runs `bundle exec rubocop` on project
   - Captures violations and offense types
   - Reports file-by-file breakdown
   - Never modifies Claude Code session

2. **Auto-Correction**
   - Applies `--auto-correct-all` flag
   - Fixes style issues automatically
   - Reports what was corrected
   - Shows remaining manual fixes (if any)

3. **Violation Diagnosis**
   - Identifies violation type and location
   - Suggests manual fixes when auto-fix unavailable
   - Links to RuboCop rule documentation
   - Guides code refactoring approach

4. **Code Quality Gates**
   - Validates no `# rubocop:disable` comments exist
   - Reports copyrighted formatting issues
   - Ensures code readability standards
   - Prepares for clean git commits

## RuboCop Quick Reference

```
Auto-fix all violations:
Use the rubocop-fixer subagent to auto-fix code style violations

Check specific file:
Use the rubocop-fixer subagent to check: lib/picotorokko/commands/new.rb

Check directory:
Use the rubocop-fixer subagent to check: test/unit/commands/

Full check (no auto-fix):
Use the rubocop-fixer subagent to report all violations
```

## picotorokko RuboCop Configuration

**Location**: `.rubocop.yml`

**Key Rules for picotorokko**:
- **Ruby version**: 3.4+ (no frozen_string_literal pragma needed)
- **Line length**: 120 characters (flexible for readability)
- **Method length**: Shorter for memory efficiency
- **Empty lines**: Proper spacing between methods
- **Comments**: Descriptive, not redundant
- **Variable naming**: Clear, avoiding single letters except in blocks

## Code Style Principles

1. **NO `# rubocop:disable` comments**
   - Refactor code instead of disabling rules
   - Find cleaner solution that passes linting
   - Use temporary `# todo` comments instead

2. **Simple, Linear Code**
   - Avoid unnecessary complexity
   - Use guard clauses early returns
   - Keep methods focused and small
   - Use meaningful variable names

3. **Avoid Over-Engineering**
   - Don't add error handling for impossible scenarios
   - Trust internal code and framework guarantees
   - Only validate at system boundaries (user input, APIs)
   - Use feature flags only when necessary

4. **Documentation Standards**
   - Code comments: Japanese, noun-ending form (体言止め)
   - Git commits: English, imperative form
   - Documentation files: English only
   - No emojis unless explicitly requested

## Integration with Development Workflow

**Step-by-Step**:
1. Make code changes
2. Use test-runner to verify tests pass
3. Use rubocop-fixer to auto-fix violations
4. Review any remaining manual fixes
5. Use git-helper to commit changes

**Before Pushing**:
```
Use the rubocop-fixer subagent to auto-fix code style violations
```

**Quality Gate**:
- ✅ All tests passing
- ✅ RuboCop clean (0 violations)
- ✅ Code is simple and readable
- ✅ Comments are clear and helpful

## Common Violations & Fixes

| Violation | Example | Fix |
|-----------|---------|-----|
| Line too long | 150 character line | Split into multiple lines |
| Method too long | 25+ lines | Extract helper methods |
| Too many parameters | `def foo(a, b, c, d, e)` | Use options hash or builder |
| Missing blank line | Methods back-to-back | Add blank line between methods |
| Unused variable | `_unused = value` | Remove assignment or use variable |
| Multiple assignments | `a = b = c = 0` | Use separate assignments |

## Tools & Dependencies

**RuboCop**: v1.81.7
- Core linting
- Auto-correction with `--auto-correct-all`
- Configuration via `.rubocop.yml`

**RuboCop Plugins**:
- `rubocop-rake`: Rakefile validation
- `rubocop-performance`: Performance anti-patterns
- `rbs-inline`: Type annotation support

## Safety Guarantees

- ✅ Only modifies files with violations
- ✅ Always auto-fixes when possible
- ✅ Reports remaining manual fixes
- ✅ Never disables rules
- ✅ Integrates with test and git workflows
- ✅ Isolated from Claude Code session (subprocess)
