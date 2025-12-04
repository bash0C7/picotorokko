# Git Safety Protocols

## Commits

- ⚠️ MUST use `commit` subagent (never raw `git` commands)
- ⚠️ MUST run `git add` BEFORE committing - do not accumulate uncommitted changes
- Execute commits incrementally: commit each logical change immediately, not at end of session
- Format: English, imperative mood
- Title: 50 chars max ("Add", "Fix", "Refactor")
- Body: Explain *why* the change matters

## Forbidden Commands

- 🚫 `git push`, `git push --force`
- 🚫 `git reset --hard`
- 🚫 `git rebase -i`
- 🚫 `rake init`, `rake update`, `rake buildall` (contain destructive git operations)

## Safe Commands

- ✅ `git status`, `git log`, `git diff`
- ✅ `git add`
- ✅ `commit` subagent for commits
- ✅ `rake monitor`, `rake check_env`
