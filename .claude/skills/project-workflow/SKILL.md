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

## Session Flow: Tidy First + TDD + RuboCop

### Micro-Cycle (1-5 minutes per iteration)

**Goal**: Complete one Red-Green-Refactor cycle with RuboCop integration

```
1. RED: Write one failing test
   bundle exec rake test → Verify failure ❌

2. GREEN: Write minimal code to pass test
   bundle exec rake test → Verify pass ✅
   bundle exec rubocop -A → Auto-fix violations

3. REFACTOR: Improve code quality
   - Apply Tidy First principles (guard clauses, symmetry, clarity)
   - Fix remaining RuboCop violations manually
   - Understand WHY each violation exists
   - bundle exec rubocop → Verify 0 violations

4. VERIFY & COMMIT: All quality gates must pass
   bundle exec rake ci → Tests + RuboCop + Coverage ✅
   Use `commit` subagent with clear, imperative message
```

### Quality Gates (ALL must pass before commit)

```bash
# Gate 1: Tests pass
bundle exec rake test
✅ Expected: All tests pass

# Gate 2: RuboCop: 0 violations
bundle exec rubocop
✅ Expected: "26 files inspected, 0 offenses"

# Gate 3: Coverage (CI mode)
bundle exec rake ci
✅ Expected: Line: ≥ 80%, Branch: ≥ 50%
```

### Macro-Cycle (Task completion)

```
1. Check TODO.md for ongoing tasks and priorities
   (See CLAUDE.md ## TODO Management for task management rules)

2. Use explore agent to review relevant code/structure

3. Repeat Micro-Cycle multiple times until task complete
   - Each micro-cycle is 1-5 minutes
   - Keep changes small and meaningful
   - Commit frequently (small, focused commits)
   - Never accumulate multiple changes before committing

4. Update TODO.md
   - Remove completed task immediately
   - Add new tasks only if they emerge during implementation

5. User verifies
   - Full test suite passes: `rake ci`
   - Manual testing if needed
   - Code review if applicable
```

### Key Principles

**Tidy First (Kent Beck)**
- Small refactoring steps (1-5 minutes each)
- Each step improves code understanding
- Changes compound into massive improvements without risk
- Example: Extract constant, rename variable, simplify guard clause

**t-wada style TDD**
- One test at a time
- Minimal code to pass (no gold-plating)
- Red-Green-Refactor cycle is fast
- Test is always green after Refactor phase

**RuboCop as Quality Gate**
- ✅ Auto-fix violations automatically (`rubocop -A`)
- ✅ Understand and fix remaining violations manually
- 🚫 NEVER add `# rubocop:disable` comments
- 🚫 NEVER commit with RuboCop violations

### Absolutely Forbidden

- 🚫 Committing with RuboCop violations
- 🚫 Adding `# rubocop:disable` comments
- 🚫 Writing fake/trivial tests
- 🚫 Lowering coverage thresholds
- 🚫 Large, multi-function changes per commit

### When to Ask User

**MUST ask in these scenarios**:
1. Refactoring direction unclear (how to split method?)
2. Test strategy controversial (what should we test?)
3. Trade-off between simplicity and completeness
4. RuboCop violation needs architectural decision

See `.claude/docs/testing-guidelines.md` for detailed examples.
