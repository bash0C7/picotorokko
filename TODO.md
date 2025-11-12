# TODO: Project Maintenance Tasks

## Current Status

- ✅ **All Tests**: 197 tests passing (183 main + 14 device)
- ✅ **Quality**: RuboCop clean, coverage 87.14% line / 65.37% branch
- ✅ **Infrastructure**: Executor abstraction, Template engines, Device test framework complete

---

## Test Execution

**Quick Reference**:
```bash
rake              # Default: Run all tests (183 main + 14 device)
rake test         # Run main test suite (183 tests)
rake ci           # CI checks: tests + RuboCop + coverage validation
rake dev          # Development: RuboCop auto-fix + tests + coverage
```

**Quality Metrics**:
- Tests: 197 total, all passing ✓
- Coverage: 87.14% line, 65.37% branch (minimum: 85%/60%)
- RuboCop: 0 violations

---

## ⚠️ Known Issues (Unresolved)

### [TODO-INFRASTRUCTURE-DEVICE-TEST] Thor help command breaks test-unit registration

**Status**: Omitted (low priority)

**Verification**: Commit 64df24f - Confirmed that Thor help command breaks test-unit registration:
- Mixed device_test with main tests (removed delete_if)
- Enabled help test (removed omit)
- **Result**: Only 65/197 tests registered (132+ tests fail to register)
- **Impact**: Help command cannot be tested alongside main test suite
- **Current solution**: Keep device tests isolated via `test:device_internal` task

**Reason for omit**:
- Display-only feature (non-critical)
- `help` command works manually
- No user-facing impact (CI/CD unaffected)

**Next steps if needed**:
- Investigate test-unit + Thor hook interaction
- Consider alternative testing strategy for device commands
- May require refactoring test infrastructure

---

## Completed Infrastructure

- ✅ Executor abstraction (ProductionExecutor, MockExecutor)
- ✅ AST-based template engines (Ruby, YAML, C)
- ✅ Device test framework integration
- ✅ Command name refactoring (pra → picotorokko)
- ✅ Rake task simplification (CI vs development)
- ✅ Documentation structure cleanup (obsolete docs removed, architecture docs organized)

---

## Planned Features

### 🎯 Priority 1: Type System Integration (rbs-inline + Steep)

**Goal**: Add type annotations and static type checking to improve code quality and IDE support

**Strategy**: Use **rbs-inline annotations** (becoming Ruby standard) as primary annotation method. Auto-generate .rbs files. Use Steep for type checking. NO YARD.

**Reference Documentation** (Design & Implementation Guides):
- **Investigation**: [`.claude/docs/rbs-inline-research.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/rbs-inline-research.md) — Deep analysis of rbs-inline (Ruby standard candidate)
- **Strategy**: [`.claude/docs/type-system-strategy.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/type-system-strategy.md) — Overall type system integration plan (Phases 2-5)
- **Phase 2+**: [`.claude/docs/type-annotation-guide.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/type-annotation-guide.md) — Annotation patterns, examples, workflow
- **TDD Workflow**: [`.claude/docs/t-wada-style-tdd-guide.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/t-wada-style-tdd-guide.md) — How RBS integrates into t-wada style TDD

**Status**: Phase 1 design complete. Phase 2+ implementation pending.

---

### 📚 Priority 2: Gem Documentation Generation

**Goal**: Generate comprehensive documentation from RBS type definitions

**Strategy**: Rely on RubyDoc.info for Phase 2 (zero config). Evaluate rbs-doc/Steep docs for Phase 3 local generation.

**CRITICAL**: Priority 1 decision (rbs-inline only, NO YARD) means documentation comes from auto-generated .rbs files only.

**Reference Documentation** (Design & Implementation):
- **Design**: [`.claude/docs/documentation-generation.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/documentation-generation.md) — RBS-only documentation strategy (Phases 1-3)
- **Phase 2 goal**: Commit .rbs files, let RubyDoc.info auto-generate docs on gem publish

**Status**: Phase 1 design complete. Waiting for Priority 1 Phase 2 completion (.rbs files in sig/)

---

### 🔄 Priority 3: Documentation Update Automation

**Goal**: Ensure implementation changes always trigger documentation updates

**Strategy**: Integrate documentation checks into dev workflow (CLAUDE.md + Quality Gates). Escalate to Claude Skill (Phase 2) and CI validation (Phase 4) later.

**Reference Documentation** (Design & Implementation):
- **Design**: [`.claude/docs/documentation-automation-design.md`](https://github.com/picoruby/picotorokko/blob/main/.claude/docs/documentation-automation-design.md) — File change → doc mapping (Phases 1-4)
- **Phase 1 (COMPLETE)**: Documentation Check added to CLAUDE.md ("Before every commit" + "Quality Gates")
  - File change mapping: lib/picotorokko/commands/ → SPEC.md + README.md, etc.
  - Reference: `.claude/docs/documentation-automation-design.md` for full mapping

**Status**: Phase 1 complete (CLAUDE.md integration). Phases 2-4 pending (Skill, Hook, CI validation)

---

## Quality Gates

All features must meet these criteria before merging:

### Pre-Commit Checks (Local Development)

- ✅ All tests passing (197+ tests): `bundle exec rake test`
- ✅ RuboCop: 0 violations: `bundle exec rubocop`
- ✅ Coverage: ≥85% line, ≥60% branch: `bundle exec rake ci`
- ✅ **rbs-inline annotations added** (Priority 1+): Inline annotations for all new/modified public methods
- ✅ **RBS files generated** (Priority 1+): `rake rbs:generate` creates/updates .rbs files in sig/
- ✅ **Steep check passing** (Priority 1+): `steep check` returns no errors on generated .rbs
- ✅ **RBS/YARD synchronization** (Priority 1+2, if using YARD): `scripts/check_rbs_yard_sync.rb` passes

### Pre-Push Checks (Final Verification)

- ✅ Documentation updated (SPEC.md, README.md, relevant guides)
- ✅ YARD comments added for public methods (Priority 2+)
- ✅ Architecture docs updated if design changed (docs/architecture/)
- ✅ TODO.md updated (completed tasks removed, new issues added)

### Commit Message Quality

- ✅ Imperative mood ("Add feature" not "Added feature")
- ✅ Concise first line (<50 chars)
- ✅ Detailed body if needed (wrap at 72 chars)
- ✅ References related issues/PRs if applicable
