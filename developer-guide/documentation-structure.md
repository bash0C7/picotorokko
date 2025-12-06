# Documentation Structure & Role Clarity

## Overview

The picotorokko project serves **two distinct audiences**:

1. **ptrk Gem Developers** — Those developing the gem itself
2. **ptrk Users** — PicoRuby application developers who install and use the gem

This document clarifies which documentation is for whom and how to maintain consistency.

---

## Audience Definition

### ptrk Gem Developer

**Who**: You (Claude Code in this project)

**What you do**:
- Develop the `ptrk` command and infrastructure
- Write/test code in `lib/picotorokko/`, `test/`
- Manage gem configuration (gemspec, Gemfile, `.ruby-version`)
- Design user-facing features and guides
- Release new gem versions to RubyGems

**Files you read/write**:
- `lib/picotorokko/` — Source code
- `test/` — Test suite
- `.claude/` — Internal design and development guides
- `CLAUDE.md` — Your development guidelines
- Configuration: `pra.gemspec`, `Gemfile`, `.rubocop.yml`, etc.

### ptrk User (PicoRuby Application Developer)

**Who**: Someone who runs `gem install picotorokko`

**What they do**:
- Use the `ptrk` command to develop PicoRuby applications
- Run workflows: `ptrk env show`, `ptrk build setup`, `ptrk device flash`
- Customize configuration: `.picoruby-env.yml`, `mrbgems/`, patches
- Set up GitHub Actions CI/CD
- Build custom mrbgems

**Files they read/write**:
- `README.md` — "For PicoRuby Application Users" section
- `SPEC.md` — Complete CLI specification
- `docs/` — User guides and tutorials
- `docs/github-actions/` — Workflow templates
- `.picoruby-env.yml` — Environment configuration (they create this)

---

## Documentation Locations

### For gem Developers Only

These documents are **internal to gem development** and not part of the installed gem:

```
.claude/
├── docs/
│   ├── output-style.md           # Response format guidelines for Claude
│   ├── git-safety.md              # Git safety protocols
│   ├── testing-guidelines.md       # Test coverage standards
│   ├── tdd-rubocop-cycle.md        # Development workflow pattern
│   ├── documentation-structure.md  # This file
│   └── spec/
│       ├── architecture.md         # Build system design
│       ├── build-environment.md    # Build directory structure
│       ├── cache-management.md     # Cache operations (detailed)
│       ├── cli-reference.md        # Internal CLI development notes
│       └── patch-system.md         # Patch system details
└── skills/                         # Agent workflow definitions
    └── *.md                        # Agent tasks

CLAUDE.md                           # Your development guidelines
TODO.md                             # Project task tracking

lib/picotorokko/                           # Source code
test/                              # Test suite
```

### For pra Users Only

These documents are **installed as part of the gem** or available on GitHub:

```
README.md
├── ## For PicoRuby Application Users
│   ├── ### Quick Start
│   ├── ### Commands Reference
│   ├── ### Requirements
│   ├── ### Configuration File
│   ├── ### Documentation
│   └── ### CI/CD Integration

SPEC.md                            # User-facing specification (complete)

docs/
├── CI_CD_GUIDE.md                 # CI/CD for application developers
├── MRBGEMS_GUIDE.md               # Custom mrbgem development
├── RUBOCOP_PICORUBY_GUIDE.md      # RuboCop setup guide
└── github-actions/
    └── esp32-build.yml            # Workflow template

.picoruby-env.yml                  # User's environment config (created by user)
```

### For Both Audiences (Dual-Purpose)

These documents address **both audiences but with distinct sections**:

```
README.md
├── ## For PicoRuby Application Users       [Lines 49-171]
├── ## For pra Gem Developers               [Lines 172-end]
└── ## License                              [Both read]

CONTRIBUTING.md                    # Release/contribution guide (dual-purpose)
CHANGELOG.md                        # Version history (both read)
```

---

## Documentation Management Rules

### Adding New Documentation

1. **Is this for gem developers or users?**
   - **Users**: Place in `docs/`, add reference in `SPEC.md` and `README.md`
   - **Developers**: Place in `.claude/docs/`, add reference in `CLAUDE.md`
   - **Both**: Create dual-section in existing docs (like `README.md`)

2. **Update role-aware section headers**:
   ```markdown
   ## For PicoRuby Application Users
   ### User-specific content here

   ## For pra Gem Developers
   ### Developer-specific content here
   ```

3. **Cross-reference appropriately**:
   - User docs → Link to `SPEC.md`, `docs/`, workflow templates
   - Dev docs → Link to `.claude/docs/`, architecture, implementation
   - Keep them separate; users shouldn't see `.claude/`

### Parallel Documentation (SPEC.md vs .claude/docs/spec/)

These documents mirror the same concepts at different abstraction levels:

| Level | For Audience | Document | Purpose |
|-------|--------------|----------|---------|
| **User-Facing** | pra Users | `SPEC.md` | "What can the system do?" |
| **Implementation** | Gem Developers | `.claude/docs/spec/*.md` | "How is it built?" |

**Consistency rule**:
- When updating `SPEC.md` user behavior → Update implementation docs in `.claude/docs/spec/`
- When discovering implementation quirk → Document in `.claude/docs/spec/`, update `SPEC.md` if user-visible

### Workflow Templates (docs/github-actions/)

These are **user-facing templates** with gem developer annotations:

```yaml
# Template for: PicoRuby application developers
# Customized by: `ptrk ci setup` (gem command)
#
# Users should:
# - Modify environment names
# - Adjust ESP-IDF versions
# - Customize build targets
#
# Gem developers:
# - Update template structure only if CLI spec changes
```

---

## Role-Aware Writing Guidelines

### For User-Facing Docs (docs/, SPEC.md)

- Use **second person**: "You can run...", "Configure your..."
- Assume user has **pra installed**: "Run `ptrk env show`"
- **Hide implementation**: Don't explain how caching works internally
- **Explain user workflows**: "First, define an environment → fetch repositories → setup build"
- **Provide examples**: Show `ptrk` command usage with realistic scenarios

### For Gem Developer Docs (.claude/docs/)

- Use **first person**: "We implement...", "Our cache strategy..."
- Assume **code context**: Reference `lib/picotorokko/cache.rb:42`
- **Explain design decisions**: "Why we chose immutable caches"
- **Document trade-offs**: "Cache immutability prevents corruption but requires manual cleanup"
- **Link to source**: "`Pra::Cache#fetch` in lib/picotorokko/cache.rb"

---

## File Change → Documentation Mapping (Priority 3 Phase 1)

When code changes, use this table to identify which documents must be updated:

### Quick Reference Table

| Trigger File(s) | Priority | Target Documents | Condition |
|-----------------|----------|------------------|-----------|
| `lib/picotorokko/commands/*.rb` | **MUST** | `SPEC.md`, `README.md` | Command behavior changed |
| `lib/picotorokko/env.rb` | **MUST** | `SPEC.md`, `README.md` | Environment management changed |
| `lib/picotorokko/template/*.rb` | SHOULD | `docs/MRBGEMS_GUIDE.md` | Template generation logic changed |
| `docs/github-actions/*.yml` | **MUST** | `docs/CI_CD_GUIDE.md` | Workflow template structure changed |
| Any public method in `lib/picotorokko/` | **MUST** (Priority 1+) | rbs-inline annotations | Public API signature changed |
| `test/**/*_test.rb` | OPTIONAL | None | Test-only changes (no docs needed) |

### Priority Levels Explained

- **MUST** (必須): User-facing changes that require documentation updates in the same commit
- **SHOULD** (推奨): Important internal changes that should update documentation when possible
- **OPTIONAL** (任意): Changes that don't require documentation updates

### Implementation Examples

**Example 1: Command Behavior Changed**
```ruby
# File: lib/picotorokko/commands/env.rb
# Changed: Added new --validate flag to show command

# Action Required:
# 1. Update SPEC.md: Add --validate to env show documentation
# 2. Update README.md: Add example of ptrk env show --validate
# 3. Update annotation (Priority 1+): Add #@rbs comment for new parameter
```

**Example 2: Public API Method Added**
```ruby
# File: lib/picotorokko/env.rb
# Added: New method Env.fetch_remote_repo(url)

# Action Required (Priority 1+):
# 1. Add rbs-inline annotation:
#    # @rbs (String) -> Hash[String, untyped]
#    def self.fetch_remote_repo(url)
# 2. Run: bundle exec rbs-inline --output sig lib
# 3. Run: bundle exec steep check
```

**Example 3: Internal Implementation Changed**
```ruby
# File: lib/picotorokko/template/ruby_engine.rb
# Changed: Refactored template rendering logic

# Action: Optional
# - If behavior changed for users: Update docs/MRBGEMS_GUIDE.md
# - If behavior unchanged: No documentation update required
```

---

## Maintenance Checklist

When making changes that affect documentation:

- [ ] **Modified gem behavior?** → Update both `SPEC.md` (user) and `.claude/docs/spec/*.md` (dev)
- [ ] **Added new command?** → Update `lib/picotorokko/cli.rb`, `SPEC.md`, `README.md` (user section)
- [ ] **Changed workflow template?** → Update `docs/github-actions/*.yml` + README.md (user section)
- [ ] **Fixed implementation bug?** → Add to `TODO.md` if doc-related, update CHANGELOG.md
- [ ] **Updated docs?** → Verify section headers match audience (see "Role-Aware Section Headers" above)
- [ ] **Added to .claude/docs/?** → Reference it in `CLAUDE.md` "Your Role" section if relevant
- [ ] **Public API changed?** (Priority 1+) → Add rbs-inline annotations + run `bundle exec rbs-inline --output sig lib` + `bundle exec steep check`

---

## Quick Reference: Who Reads What?

```
┌─────────────────────────────────────────────┬────────────────┬─────────────┐
│ Document                                    │ Gem Developer  │ pra User    │
├─────────────────────────────────────────────┼────────────────┼─────────────┤
│ README.md (Full)                            │ ✅              │ ✅          │
│ README.md ("For Users" section)             │ (skip)         │ ✅          │
│ README.md ("For Developers" section)        │ ✅              │ (skip)      │
│ SPEC.md                                     │ ✅              │ ✅          │
│ .claude/docs/spec/                          │ ✅              │ ❌          │
│ .claude/docs/ (general)                     │ ✅              │ ❌          │
│ docs/CI_CD_GUIDE.md                         │ ✅ (dev section)│ ✅          │
│ docs/MRBGEMS_GUIDE.md                       │ ✅ (context)   │ ✅          │
│ docs/RUBOCOP_PICORUBY_GUIDE.md              │ ✅              │ (context)   │
│ docs/github-actions/esp32-build.yml         │ ✅ (maintain)  │ ✅ (use)    │
│ CLAUDE.md                                   │ ✅              │ ❌          │
│ CONTRIBUTING.md                             │ ✅              │ ✅          │
│ CHANGELOG.md                                │ ✅              │ ✅          │
│ lib/picotorokko/                                    │ ✅ (develop)   │ ❌          │
│ test/                                       │ ✅ (test)      │ ❌          │
└─────────────────────────────────────────────┴────────────────┴─────────────┘
```

---

## Example: Adding a New Feature

**Scenario**: You're implementing a new `ptrk config` command.

**Steps**:

1. **Develop gem code** (`lib/picotorokko/commands/config.rb`)
2. **Write tests** (`test/commands/config_test.rb`)
3. **Add to spec** (`SPEC.md`):
   - Section: "### Config Management"
   - Show user-facing behavior: "Show and validate configuration"
   - Example: `ptrk config show`, `ptrk config validate`
4. **Add implementation notes** (`.claude/docs/spec/config-management.md`):
   - Design decisions
   - Edge cases
   - Performance considerations
5. **Update README.md** user section:
   - Add to "### Commands Reference" → "#### Config Management"
   - Show example commands
   - Link to detailed docs if needed
6. **Update CLAUDE.md** if the development process is noteworthy
7. **Update TODO.md** if related tasks remain

---

## See Also

- [CLAUDE.md](../CLAUDE.md) — "Your Role" section for detailed role definition
- [README.md](../../README.md) — User vs developer sections
- [SPEC.md](../../SPEC.md) — User-facing specification
