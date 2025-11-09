# TODO: Project Maintenance Tasks

> **TODO Management Methodology**: See `.claude/skills/project-workflow/SKILL.md` and `CLAUDE.md` ## TODO Management section for task management rules and workflow.

---

## 🔮 Future Enhancements (Phase 5+)

For detailed implementation guide and architecture design of the PicoRuby RuboCop Custom Cop, see [docs/RUBOCOP_PICORUBY_GUIDE.md](docs/RUBOCOP_PICORUBY_GUIDE.md).

---

## 🔴 技術的負債（Technical Debt）

✅ **Phase 5: device.rb Security & Dynamic Rake Task Handling** — COMPLETED
- Prism-based Rakefile AST parsing with whitelist validation
- RakeTaskExtractor class with Prism::Visitor pattern
- All 130 tests passing, 88.0% line coverage, 60.47% branch coverage
- See [Phase_5_Prism_Implementation_Guide.md](Phase_5_Prism_Implementation_Guide.md) for details

### Test Infrastructure Issues

- [ ] **Investigate `bundle exec rake test` test count discrepancy**
  - **Issue**: When running tests via `bundle exec rake test`, test count drops from ~130 (individual test runs) to ~62
  - **Current Status**: All tests pass individually when run via `bundle exec ruby -I lib:test test/**/*_test.rb`
  - **Impact**: Test artifacts (build/, patch/, .cache/, .picoruby-env.yml) are properly cleaned up by PraTestCase.teardown
  - **Action**: Investigate why Rake test loader loads fewer tests; may be related to test discovery or suite filtering
  - **Priority**: Low (all tests pass, cleanup is working)

- [ ] **Fix SimpleCov exit code issue in CI**
  - **Issue**: `bundle exec rake test` returns exit code 1 even though all tests pass (0 failures, 0 errors)
  - **Root Cause**: SimpleCov error: "Stopped processing SimpleCov as a previous error not related to SimpleCov has been detected"
  - **Impact**: CI pipeline fails due to non-zero exit code despite test success
  - **Action**: Investigate SimpleCov configuration and fix error handling
  - **Priority**: Medium (blocking CI/CD automation)

- [ ] **Prevent tests from modifying git-managed files**
  - **Issue**: Test execution modifies `.picoruby-env.yml.example` (git-managed template file)
  - **Root Cause**: Test cleanup may be incomplete; tests interact with .example file during setup/teardown
  - **Impact**: Git working directory becomes dirty after test runs; violates test isolation principle
  - **Problem**: This is a fundamental test design failure - tests should never modify repository resources
  - **Action**:
    1. Investigate why `.example` file is being modified during test execution
    2. Ensure test isolation uses temporary directories completely separate from repo
    3. Add pre-test verification: `git status` must be clean before tests
    4. Add post-test verification: `git status` must be clean after tests
  - **Priority**: High (critical for test reliability and CI/CD safety)

### Development Workflow Standardization

- [ ] **Enforce RuboCop auto-correction in TDD cycle**
  - **Objective**: Eliminate manual RuboCop violation fixes by making auto-correction a standard step in Red-Green-Refactor cycle
  - **Implementation**: Update CLAUDE.md development guidelines with strict requirements:
    1. **After every RED/GREEN transition**: Run `bundle exec rubocop -A` immediately
    2. **After test code reaches GREEN**: Run `bundle exec rubocop -A` on test files before commit
    3. **Before every commit**: Verify `bundle exec rubocop` returns 0 violations
    4. **Rationale**: Prevents violations from accumulating and ensures code style consistency without manual effort
  - **Success Criteria**: All commits pass RuboCop without violations; no `# rubocop:disable` comments in codebase
  - **Priority**: Medium (improves code quality and developer workflow)

---

## Future Enhancements (Optional)

### CLI Command Structure Refactoring

- [ ] Consider renaming commands in future if needed (e.g., `pra build-env` or `pra workspace`)

---

## 🔒 Security Enhancements (Do not implement without explicit request)

All security enhancements below do not change behavior and should only be implemented with explicit user request.

### Symbolic Link Race Condition Prevention

- [ ] Add race condition protection to symbolic link checks
  - **Where**: Symbolic link validation in `lib/pra/commands/build.rb`
  - **Problem**: TOCTOU (Time-of-check to time-of-use) vulnerability between check and usage
  - **Solution**: Use File.stat with follow_symlinks: false instead of File.symlink?
  - **Note**: Limited real-world risk, low priority

### Path Traversal Input Validation

- [ ] Add path traversal validation for user inputs (env_name, etc.)
  - **Where**: All command files in `lib/pra/commands/`
  - **Problem**: User inputs like env_name could contain `../../` without validation
  - **Checks needed**:
    - Reject paths containing `..`
    - Reject absolute paths
    - Allow only alphanumeric, hyphen, underscore
  - **Solution**: Create `lib/pra/validator.rb` for centralized validation
  - **Testing**: Add path traversal attack test cases
  - **Note**: Current codebase is developer-facing tool with limited attack surface
