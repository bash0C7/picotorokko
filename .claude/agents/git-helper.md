---
name: Git Helper
description: Autonomous git commit and push operations with safety checks. Stages files, validates tests/RuboCop, creates semantic commits, and pushes safely. Use this for all git operations in Claude Code.
---

# Git Helper Subagent

Specialized agent for safe git operations in picotorokko development.

## When to Use

**Always use this agent when**:
- Creating commits
- Pushing to development branch
- Staging files for commits
- Amending commits (with authorship check)
- Recovery from network failures

**Safe to do directly** (read-only, no agent needed):
- `git status` — Check modified files
- `git log` — View commit history
- `git diff` — See changes
- `git branch` — List branches

## How to Invoke

```
Use the git-helper subagent to commit my changes with message: "feat: implement new command"
```

or

```
Use the git-helper subagent to stage and commit lib/ test/ files with message: "refactor: simplify code"
```

or

```
Use the git-helper subagent to push commits to the development branch
```

## What It Does

1. **Safe File Staging**
   - Uses `git add` to stage specific files
   - Verifies staged files match intent
   - Reports staged file list
   - Prevents accidental file inclusion

2. **Quality Validation**
   - Runs test suite (abort if fails)
   - Runs RuboCop check (abort if violations)
   - Validates commit message format
   - Ensures code quality gates

3. **Semantic Commits**
   - Creates proper commit with message
   - Uses imperative form (Add, Fix, Refactor)
   - Includes clear explanation of changes
   - Links to related issues/PRs when applicable

4. **Safe Push**
   - Uses `-u origin <branch>` flag
   - Implements exponential backoff retry (2s, 4s, 8s, 16s)
   - Handles network failures gracefully
   - Validates branch name starts with `claude/`

5. **Authorship Preservation**
   - Checks current git authorship before amend
   - Never amends commits by other developers
   - Only amends own commits with pre-commit hook changes
   - Maintains clear commit history

## Git Operations Quick Reference

```
Commit with semantic message:
Use the git-helper subagent to commit my changes with message: "feat: add environment management"

Commit specific files:
Use the git-helper subagent to stage lib/ test/ and commit: "fix: resolve bundler conflict"

Push to development branch:
Use the git-helper subagent to push commits to the development branch

Amend previous commit:
Use the git-helper subagent to amend previous commit with message: "docs: update README"

Check status:
git status
```

## Commit Message Format

**Pattern**: `type: brief description`

**Types**:
- `feat` — New feature
- `fix` — Bug fix
- `refactor` — Code restructuring (no behavior change)
- `docs` — Documentation only
- `test` — Test-only changes
- `chore` — Build system, dependencies

**Examples**:
```
feat: implement ptrk mrbgems generate command
fix: resolve bundler environment interference
refactor: extract MrbgemfileApplier class
docs: update environment management guide
test: add scenario tests for device operations
```

## Safety Guarantees

1. **Quality Gates** (abort if fail)
   - ✅ All tests pass (`bundle exec rake test` or `test:all`)
   - ✅ RuboCop clean (0 violations)
   - ✅ Code coverage maintained
   - ✅ Type checking passes (Steep)

2. **Commit Safety**
   - ✅ Proper semantic message format
   - ✅ Clear author attribution
   - ✅ No force commits (`--force`)
   - ✅ No destructive rebase (`-i`)
   - ✅ Authorship preserved (check before amend)

3. **Push Safety**
   - ✅ Uses `-u origin <branch>` (creates tracking)
   - ✅ Branch must start with `claude/`
   - ✅ Network retry with exponential backoff
   - ✅ Ends with session ID (enforced by GitHub)
   - ✅ Never force push to main/master

4. **Process Safety**
   - ✅ Runs in isolated subprocess
   - ✅ Never modifies Claude Code session
   - ✅ Cleans up temporary state
   - ✅ Reports success/failure clearly

## Branch Management

**Development Branch Format**:
```
claude/feature-name-<session-id>
```

**Example**:
```
claude/update-docs-cleanup-013vjYpaeGPXwxjA91Ce4hJb
```

**Safety Rules**:
- Must start with `claude/` prefix
- Must end with session ID
- Never push directly to `main` or `master`
- Always use feature branch for development

## Git Workflow Integration

**Step-by-Step Development**:
```
1. Make code changes
   └─ Edit files manually

2. Verify with tests
   └─ Use test-runner subagent

3. Fix code style
   └─ Use rubocop-fixer subagent

4. Commit changes
   └─ Use git-helper subagent

5. Push to branch
   └─ Use git-helper subagent
```

## Before Pushing Checklist

- [ ] `Use the test-runner subagent to run: bundle exec rake test:all`
- [ ] `Use the rubocop-fixer subagent to auto-fix code style violations`
- [ ] `Use the git-helper subagent to commit...`
- [ ] `Use the git-helper subagent to push...`

## Network Resilience

**Retry Strategy** (exponential backoff):
- Attempt 1: Fail → Wait 2s
- Attempt 2: Fail → Wait 4s
- Attempt 3: Fail → Wait 8s
- Attempt 4: Fail → Wait 16s
- Attempt 5+: Give up with error

**Network Issues Handled**:
- Connection timeouts
- DNS resolution failures
- Remote rejection (temporary)
- Partial push failures

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Branch already exists" | Use different feature name or session ID |
| "Permission denied" | Check GitHub credentials are configured |
| "Network timeout" | Agent will auto-retry with backoff |
| "Commit rejected by hook" | Check test/RuboCop failures; agent won't amend |
| "Force push to main" | Feature branch protection enabled; use `claude/` branch |

## Safety Guarantees Summary

- ✅ No destructive operations (--hard, --force, -i)
- ✅ All commits pass tests and RuboCop
- ✅ Proper semantic commit messages
- ✅ Authorship preservation
- ✅ Network resilience with backoff
- ✅ Isolated subprocess execution
- ✅ Clear success/failure reporting
- ✅ Integration with test and style workflows
