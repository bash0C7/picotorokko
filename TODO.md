# TODO: Project Maintenance Tasks

> **TODO Management Methodology**: See `.claude/skills/project-workflow/SKILL.md` and `CLAUDE.md` ## TODO Management section for task management rules and workflow.

---

## 🔮 Future Enhancements (Phase 5+)

For detailed implementation guide and architecture design of the PicoRuby RuboCop Custom Cop, see [docs/RUBOCOP_PICORUBY_GUIDE.md](docs/RUBOCOP_PICORUBY_GUIDE.md).

---

## 🔴 技術的負債（Technical Debt）

---

## Future Enhancements (Optional)

### CLI Command Structure Refactoring

- [ ] Consider renaming commands in future if needed (e.g., `pra build-env` or `pra workspace`)

---

## 🔧 Code Quality Improvements

### Refactor Test Temporary File Handling

- [x] **Completed Phase 1: Migrate 3 files to block-based temp file creation**
  - [x] `test/commands/rubocop_test.rb` - 11 tests refactored
  - [x] `test/commands/build_test.rb` - 9 tests refactored
  - [x] `test/commands/mrbgems_test.rb` - 10 tests refactored
  - [x] Updated `.rubocop.yml`: Excluded test files from BlockLength metric (needed for nested blocks)
  - **Pattern Used**: `Dir.mktmpdir` with block for directory structures (Ruby standard pattern)

- [ ] **Phase 2: Migrate remaining 5 test files**
  - [ ] `test/commands/device_test.rb` - ~11 tests
  - [ ] `test/commands/ci_test.rb` - ~5 tests
  - [ ] `test/commands/patch_test.rb` - ~9 tests
  - [ ] `test/commands/cache_test.rb` - ~9 tests
  - [ ] `test/commands/env_test.rb` - ~12 tests
  - **Pattern**: Same as Phase 1 (`Dir.mktmpdir` with block)
  - **Benefit**: Automatic cleanup on block exit, better test isolation
  - **Security**: Implicit: `Dir.mktmpdir` uses secure temporary directory creation

- **Design Decision**: Chose direct `Dir.mktmpdir { ... }` pattern over helper method
  - Pro: Standard Ruby knowledge, no project-specific complexity
  - Con: Repeat pattern in each test (~6 lines per test)
  - Rationale: Simplicity wins over DRY when readability is maintained

---

## 🟡 Medium Priority (Code Quality & Documentation)

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
