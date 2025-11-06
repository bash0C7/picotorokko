# Project Workflow & Build System

Development workflow, build system permissions, and git safety protocols for PicoRuby development.

## Your Role

**You are the developer of the `pra` gem** — a CLI tool for PicoRuby application development on ESP32.

- **Primary role**: Implement and maintain the `pra` gem itself
- **User perspective**: Temporarily adopt when designing user-facing features (commands, templates, documentation)
- **Key distinction**:
  - Files in `lib/pra/`, `test/`, gem configuration → You develop these
  - Files in `docs/github-actions/`, templates → These are for `pra` users (not executed during gem development)
  - When `pra` commands are incomplete, add to TODO.md — don't rush implementation unless explicitly required

## Directory Structure

```
.
├── lib/pra/                   # Gem implementation
├── test/                      # Test suite
├── docs/github-actions/       # User-facing templates
├── storage/home/              # Example application code
├── patch/                     # Repository patches
├── .cache/                    # Cached repositories (git-ignored)
├── build/                     # Build environments (git-ignored)
└── TODO.md                    # Task tracking
```

## Rake Commands Permissions

### ✅ Always Allowed (Safe, Read-Only)

```bash
rake monitor      # Watch UART output in real-time
rake check_env    # Verify ESP32 and build environment
```

### ❓ Ask First (Time-Consuming)

```bash
rake build        # Compile firmware (2-5 min)
rake cleanbuild   # Clean + rebuild
rake flash        # Upload to hardware (requires device)
```

### 🚫 Never Execute (Destructive)

```bash
rake init         # Contains git reset --hard
rake update       # Destructive git operations
rake buildall     # Combines destructive ops
```

**Rationale**: Protect work-in-progress from accidental `git reset --hard`.

## Git Safety Protocol

- ✅ Use `commit` subagent for all commits
- ❌ Never: `git push`, `git push --force`, raw `git commit`
- ❌ Never: `git reset --hard`, `git rebase -i`
- ✅ Safe: `git status`, `git log`, `git diff`

## Session Flow

```
1. Check TODO.md for ongoing tasks and priorities
   (See CLAUDE.md ## TODO Management for task management rules)
2. Use explore agent to review relevant code/structure
3. Make targeted edits (small, focused)
4. Commit with clear message via `commit` subagent
5. User verifies with `rake test` or builds firmware
```
