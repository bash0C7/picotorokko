# documentation-sync Skill

**Purpose**: Analyze code changes and suggest corresponding documentation updates

## Overview

This Claude Skill implements Priority 3 Phase 2: automated detection of which documents need updating based on code changes.

**Workflow Integration**:
- Used during development to ensure documentation stays synchronized with code
- Integrates with `.claude/docs/documentation-structure.md` file mapping
- Generates actionable checklist for developer

## Usage

```bash
/documentation-sync [optional: file path or branch name]
```

**Examples**:

```bash
# Analyze current uncommitted changes
/documentation-sync

# Analyze changes in specific file
/documentation-sync lib/picotorokko/commands/env.rb

# Analyze changes against main branch
/documentation-sync main
```

## How It Works

### Step 1: Detect Changed Files

Uses `git diff` to identify which files have been modified:
```bash
git diff --name-only [branch] [commit]
```

### Step 2: Map to Documentation

Consults `.claude/docs/documentation-structure.md` (lines 201-256) for file-to-doc mapping:

```
lib/picotorokko/commands/*.rb  → SPEC.md + README.md
lib/picotorokko/env.rb          → SPEC.md + README.md
docs/github-actions/*.yml       → docs/CI_CD_GUIDE.md
lib/picotorokko/template/*.rb   → docs/MRBGEMS_GUIDE.md
Any public method (Priority 1+) → rbs-inline annotations + steep check
```

### Step 3: Generate Checklist

Creates structured checklist:
- ✅ Files changed
- ✅ Documents requiring updates
- ✅ Priority (MUST / SHOULD / OPTIONAL)
- ✅ Actionable steps

### Step 4: Integration Hints

Provides reference to:
- CLAUDE.md "Before every commit" workflow (lines 281-286)
- tdd-rubocop-cycle.md Phase 4 Documentation (lines 172+)

## Example Output

```
📊 Documentation Sync Analysis

Changed Files:
- lib/picotorokko/commands/env.rb (MODIFIED)
- test/commands/env_test.rb (MODIFIED)

Documentation Mapping:
┌─ MUST Update:
│  ├─ SPEC.md (Environment Management section)
│  └─ README.md (Commands Reference section)
│
└─ OPTIONAL:
   └─ test files (no documentation needed)

Checklist:
- [ ] Review SPEC.md environment management documentation
  → Verify env.rb behavior changes are documented
- [ ] Update README.md command examples
  → Add/update env commands if signature changed
- [ ] Run: bundle exec rbs-inline --output sig lib
- [ ] Run: bundle exec steep check
- [ ] Run: bundle exec rake ci

Next Steps:
1. Update SPEC.md with new/changed behaviors
2. Include documentation updates in same commit
3. Run quality gates before pushing
```

## Implementation Notes

### Files This Skill Reads

- `.claude/docs/documentation-structure.md` - File mapping table
- `SPEC.md` - User-facing specification
- `README.md` - Quick start and reference
- `lib/picotorokko/` - Source code structure
- `docs/` - User guides

### Limitations

- Does not auto-update documentation (human judgment required)
- Requires local git repository
- Mapping table must be manually maintained in documentation-structure.md

### Future Enhancements

- Integration with GitHub Actions for PR validation
- Auto-comment on PRs with documentation checklist
- Validation that documentation actually matches code changes
- YARD documentation coverage analysis

## Related Documentation

- **Design**: `.claude/docs/documentation-automation-design.md`
- **Mapping Table**: `.claude/docs/documentation-structure.md` (lines 201-256)
- **Workflow**: CLAUDE.md "Before every commit" section
- **Phase**: Priority 3 Phase 2 in TODO.md

---

**Created**: 2025-11-14
**Status**: Phase 2 Implementation (Session 3)
