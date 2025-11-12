# TODO: Project Maintenance Tasks

## Current Status

- ✅ **device_test.rb fully integrated**: All 14 device tests passing
- ✅ **Main test suite**: 183 tests passing
- ✅ **Total coverage**: 197 tests across all suites
- ✅ **Quality**: RuboCop clean (except non-critical metrics), coverage ≥ 85% line / 60% branch

---

## ✅ Completed & Archived

### ✅ Phase 0 Session 7: Command Name Refactoring (pra → picotorokko)

Complete migration of gem name from `pra` → `picotorokko` across 46 files.

**Results**:
- All 197 tests passing (183 main + 14 device)
- Coverage: 87.14% line, 65.37% branch
- RuboCop: Clean (non-critical metrics only)

**Cleanup**: Removed all diagnostic test tasks and experimental files from previous sessions.

### ✅ Previous Sessions: Executor Abstraction & Template Engine

- Executor pattern for test isolation (ProductionExecutor, MockExecutor)
- AST-based template engine (Ruby/YAML/C support)
- Device test framework integration

---

## Test Execution

**Quick Reference**:
```bash
rake                    # Default: All 197 tests (183 main + 14 device)
rake test              # Main suite: 183 tests
rake test:device       # Device suite: 14 tests
rake test:all          # All tests with cumulative coverage
rake ci                # CI: tests + RuboCop + coverage validation
```

**Quality Metrics**:
- Tests: 197 total, all passing ✓
- Coverage: 87.14% line, 65.37% branch (minimum: 85%/60%)
- RuboCop: Clean (11 non-critical metrics)

---

## Documentation

- `CLAUDE.md` - Project instructions & development guide
- `.claude/docs/` - Internal architecture & guidelines
- `docs/` - User guides & specifications
- `README.md` - Installation & quick start
