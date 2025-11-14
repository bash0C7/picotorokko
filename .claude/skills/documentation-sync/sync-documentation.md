# Skill: Analyze and Suggest Documentation Updates

## Overview

This skill analyzes git changes and suggests which documentation files need updating based on the file mapping in `.claude/docs/documentation-structure.md`.

**Input**: Optional file path or branch name
**Output**: Structured documentation update checklist with priorities

## Execution Steps

### Step 1: Detect Changed Files

```bash
# Default: uncommitted changes
git diff --name-only

# If argument provided (branch or file):
# Branch: git diff --name-only main...HEAD
# File: git show <file>
```

Analyze output to extract:
- Modified files
- New files
- Deleted files

### Step 2: Load Documentation Mapping

Read `.claude/docs/documentation-structure.md` section "File Change → Documentation Mapping" (lines 201-256).

Build mapping table:
```
lib/picotorokko/commands/*.rb      → SPEC.md, README.md (MUST)
lib/picotorokko/env.rb             → SPEC.md, README.md (MUST)
lib/picotorokko/template/*.rb      → docs/MRBGEMS_GUIDE.md (SHOULD)
docs/github-actions/*.yml          → docs/CI_CD_GUIDE.md (MUST)
Any public method (lib/)            → rbs-inline annotations (MUST Priority 1+)
test/**/*_test.rb                  → None (OPTIONAL)
```

### Step 3: Cross-Reference Changes

For each changed file:
1. Check if it matches mapping patterns
2. If match found: add target documents to checklist
3. Track priority level (MUST / SHOULD / OPTIONAL)
4. Collect by category

### Step 4: Generate Output

Format as structured checklist:

```markdown
# 📊 Documentation Sync Analysis

## Changed Files (git diff summary)
- [Category] filename (MODIFIED/ADDED/DELETED)

## Documentation Mapping Results

### 🔴 MUST Update (Required)
- Document A: Description
- Document B: Description

### 🟡 SHOULD Update (Recommended)
- Document C: Description

### ⚪ OPTIONAL (No docs needed)
- Category: Files that don't require docs

## Checklist

- [ ] Review changed files above
- [ ] Update MUST documents
  - [ ] Specific action for doc A
  - [ ] Specific action for doc B
- [ ] Consider SHOULD documents
  - [ ] Specific action for doc C
- [ ] Run type system checks (if code changed):
  - [ ] bundle exec rbs-inline --output sig lib
  - [ ] bundle exec steep check
- [ ] Run quality gates:
  - [ ] bundle exec rake ci
- [ ] Include doc updates in same commit

## Actionable Guidance

[Specific instructions based on detected changes]

## Integration

- Workflow: See CLAUDE.md "Before every commit" (lines 281-286)
- Mapping: See documentation-structure.md (lines 201-256)
```

### Step 5: Add Integration Hints

Reference appropriate sections:
- **If command changed**: "See SPEC.md Commands Reference section"
- **If workflow changed**: "See CI_CD_GUIDE.md Workflows section"
- **If public API changed**: "See CLAUDE.md Before every commit - Documentation Check"

## Special Cases

### Type System Changes (Priority 1)
If any `lib/picotorokko/*.rb` file with public methods changed:
- **Must add**: rbs-inline annotations
- **Must run**: `bundle exec rbs-inline --output sig lib`
- **Must run**: `bundle exec steep check`

### Test-Only Changes
If only `test/*_test.rb` changed:
- Mark as OPTIONAL (no documentation update needed)
- But mention: "Consider if test coverage indicates gap in user docs"

### Multiple Categories
If changes span multiple categories:
- List all affected docs
- Group by priority
- Show combined checklist

## Implementation Guidelines

1. **Be Specific**: Don't just say "Update SPEC.md" - say which section
2. **Be Actionable**: Include concrete steps the developer should take
3. **Reference**: Always link to CLAUDE.md and documentation-structure.md
4. **Integrate**: Show how this fits into "Before every commit" workflow
5. **Encourage**: Emphasize that co-locating docs with code reduces mistakes

## Example Scenarios

### Scenario 1: Added New Command

Changed file: `lib/picotorokko/commands/cache.rb`

Output:
```
MUST Update:
- SPEC.md: Add new command to "Cache Management" section
- README.md: Add to "Commands Reference" with usage example
- Include rbs-inline annotations (Priority 1+)

Checklist:
- [ ] Document new command signature in SPEC.md
- [ ] Add usage example to README.md
- [ ] Add @rbs annotations above method definition
- [ ] Run: bundle exec rbs-inline --output sig lib
- [ ] Run: bundle exec steep check
- [ ] Run: bundle exec rake ci
```

### Scenario 2: Template Engine Change

Changed file: `lib/picotorokko/template/ruby_engine.rb`

Output:
```
SHOULD Update:
- docs/MRBGEMS_GUIDE.md: Verify template examples still match

OPTIONAL:
- Internal refactoring doesn't require docs if behavior unchanged

Checklist:
- [ ] Review MRBGEMS_GUIDE.md templates
- [ ] If examples changed: update guide
- [ ] Run: bundle exec rake ci
```

### Scenario 3: Test-Only Changes

Changed file: `test/commands/env_test.rb`

Output:
```
OPTIONAL:
- Test-only changes don't require documentation
- But consider: Do tests reveal gaps in user documentation?

Checklist:
- [ ] Review if new test scenarios suggest missing user docs
- [ ] Run: bundle exec rake ci
```

## Error Handling

- **No git repository**: Explain requirement and skip analysis
- **No mapping table**: Show file detection anyway, note mapping lookup issue
- **Invalid file path**: Show available files and ask for clarification
- **No changes detected**: Explain this is good (keep code and docs in sync)

## Success Criteria

✅ Checklist is actionable and specific
✅ All MUST updates are listed
✅ References point to correct sections
✅ Developer can immediately act on guidance
✅ Effort is < 5 minutes to review and apply

---

**Skill Type**: Documentation Analysis Agent
**Input**: Optional (git branch/file path)
**Output**: Structured markdown checklist
**Integration**: CLAUDE.md Priority 3 Phase 1 workflow
**Status**: Phase 2 Implementation
