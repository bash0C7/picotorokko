---
name: Documentation Sync
description: Analyzes code changes and suggests corresponding documentation updates based on file-to-doc mappings. Use this when implementing features or fixing bugs to ensure documentation stays synchronized with code changes.
---

# Documentation Sync Skill

**Purpose**: Analyze code changes and suggest corresponding documentation updates

## When to Use This Skill

Use this skill when:
- You've modified source files and need to know which docs to update
- You're implementing a new feature that affects user-facing behavior
- You're fixing a bug that changes command behavior or API
- You need to verify documentation is synchronized with code

## How It Works

### Step 1: Detect Changed Files

Uses `git diff` to identify modified files:
```bash
git diff --name-only [branch] [commit]
```

### Step 2: Map to Documentation

Consults `.claude/docs/documentation-structure.md` for file-to-doc mapping:

```
lib/picotorokko/commands/*.rb  → docs/SPECIFICATION.md + README.md
lib/picotorokko/env.rb         → docs/SPECIFICATION.md + README.md
docs/github-actions/*.yml      → docs/CI_CD_GUIDE.md
lib/picotorokko/template/*.rb  → docs/MRBGEMS_GUIDE.md
Any public method (Priority 1+) → rbs-inline annotations + steep check
```

### Step 3: Generate Checklist

Creates structured checklist with:
- ✅ Changed files
- ✅ Documents requiring updates
- ✅ Priority (MUST / SHOULD / OPTIONAL)
- ✅ Actionable steps

## Example Output

```
📊 Documentation Sync Analysis

Changed Files:
- lib/picotorokko/commands/env.rb (MODIFIED)
- test/commands/env_test.rb (MODIFIED)

Documentation Mapping:
┌─ MUST Update:
│  ├─ docs/SPECIFICATION.md (Environment Management section)
│  └─ README.md (Commands Reference section)
│
└─ OPTIONAL:
   └─ test files (no documentation needed)

Checklist:
- [ ] Review docs/SPECIFICATION.md environment management documentation
- [ ] Update README.md command examples
- [ ] Run: bundle exec rbs-inline --output sig lib
- [ ] Run: bundle exec steep check
- [ ] Run: bundle exec rake ci

Next Steps:
1. Update docs/SPECIFICATION.md with new/changed behaviors
2. Include documentation updates in same commit
3. Run quality gates before pushing
```

## Related Documentation

- **Design**: `.claude/docs/documentation-automation-design.md`
- **Mapping Table**: `.claude/docs/documentation-structure.md`
- **Workflow**: See `.claude/skills/documentation-standards/`
