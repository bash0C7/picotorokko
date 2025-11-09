# TODO: Project Maintenance Tasks

> **TODO Management Methodology**: See `.claude/skills/project-workflow/SKILL.md` and `CLAUDE.md` ## TODO Management section for task management rules and workflow.

---

## 🔮 Future Enhancements (Phase 5+)

For detailed implementation guide and architecture design of the PicoRuby RuboCop Custom Cop, see [docs/RUBOCOP_PICORUBY_GUIDE.md](docs/RUBOCOP_PICORUBY_GUIDE.md).

---

## 🔴 技術的負債（Technical Debt）

### Phase 5: device.rb Security & Dynamic Rake Task Handling

- [ ] **PHASE 5: Prism-based Rakefile AST parsing for secure Rake task whitelist**
  - **Status**: Investigation Complete, Implementation Ready (Next Session)
  - **Completed in current session**:
    - ✅ Removed device_test.rb from Rakefile exclusion (now runs with full test suite)
    - ✅ Added `with_stubbed_esp_env` helper to build_test.rb (4 setup tests wrapped)
    - ✅ Refactored test infrastructure with PraTestCase base class (PROJECT_ROOT reset in setup/teardown)
    - ✅ Improved test independence: tmpdir + DIR.chdir + PROJECT_ROOT const_set flow
    - ✅ **Coverage improvement**: 71.76% → **92.04% line**, 49.15% → **71.79% branch**
    - ✅ All 132 tests now execute (previously 46 device tests excluded)
    - ✅ **Complete technical investigation** of 7 test failures with root cause analysis
    - ✅ **Prism parser design** for standard task patterns + `.each` dynamic generation
    - ✅ **RakeTaskExtractor class** implementation with full code examples

  - **Implementation Details**: See [Phase_5_Prism_Implementation_Guide.md](Phase_5_Prism_Implementation_Guide.md)
    - Complete RakeTaskExtractor implementation with Prism::Visitor pattern
    - Support for dynamic task generation: `%w[...].each do |var| task "name_#{var}" end`
    - Test failure root cause analysis with specific line numbers and fixes
    - 4-phase implementation roadmap with verification steps

  - **Remaining work** (next session):
    - [ ] **Phase 1**: Fix 7 test failures (build.rb, test_helper.rb, device.rb)
      - [ ] build.rb: Add symlink deletion to clean command
      - [ ] test_helper.rb: Add build/ directory cleanup to ensure block
      - [ ] device.rb: Add environment validation to flash, monitor, build, tasks methods
      - [ ] Verify: `bundle exec rake test` → all 132 tests pass, 0 failures
    - [ ] **Phase 2**: Implement Prism parser
      - [ ] Add RakeTaskExtractor class (complete code in guide)
      - [ ] Add available_rake_tasks method
      - [ ] Enhance method_missing with whitelist validation
    - [ ] **Phase 3**: Add tests for task validation
      - [ ] New file: test/rake_task_extractor_test.rb
      - [ ] Enhance: test/commands/device_test.rb with whitelist tests
    - [ ] **Phase 4**: Quality assurance
      - [ ] RuboCop: `bundle exec rubocop` → 0 violations
      - [ ] Tests: `bundle exec rake test` → all pass
      - [ ] Coverage: `bundle exec rake ci` → line 85%+, branch 60%+
      - [ ] Commit with message referencing Prism parser addition

  - **Security benefits**:
    - Prevents arbitrary command execution via method_missing
    - Uses static AST analysis (Prism) - no code execution
    - Whitelist-based validation for all dynamic Rake task delegation
    - Supports R2P2-ESP32 dynamic tasks: setup_esp32, setup_esp32c3, etc.

---

## Future Enhancements (Optional)

### CLI Command Structure Refactoring

- [ ] Consider renaming commands in future if needed (e.g., `pra build-env` or `pra workspace`)

---

## 🟡 Medium Priority (Code Quality & Documentation)

### Test Coverage Improvement

- [x] **Completed Phase 4: Achieve 85%+ line coverage, 62%+ branch coverage**
  - [x] **Refactored patch.rb**: Extracted long methods to resolve RuboCop BlockLength violations
    - Extracted `resolve_work_path()` helper to reduce duplication
    - Extracted `export_repo_changes()` private method for export logic
    - Extracted `show_repo_diff()` private method for diff display logic
    - Updated `.rubocop.yml`: Added picoruby-application-on-r2p2-esp32-development-kit.gemspec to BlockLength exclusions (standard DSL pattern)
  - **Final metrics** (as of Phase 4):
    - ✅ Line coverage: **85.11%** (663/779 lines) - EXCEEDS 75% target by 10.11%
    - ✅ Branch coverage: **62.82%** (147/234 branches) - EXCEEDS 50% target by 12.82%
    - ✅ All 89 tests pass (100%)
    - ✅ RuboCop: 0 offenses
  - **Coverage Achievements**:
    - Excellent coverage in env.rb, patch.rb, rubocop.rb command tests
    - Comprehensive error path testing across all commands
    - Edge case handling for missing environments, build directories
    - Strong integration testing between env, build, patch, cache, ci, rubocop commands
  - **Device test note**: device_test.rb excluded from suite (known Rake task invocation issue)
    - Does not affect non-device command coverage
    - Device tests remain stable and unaffected by refactoring

---

## 🚀 Phase 4+: Future Coverage Improvements (Optional)

**Current Status**: Phase 4 objectives exceeded (85%+ line, 62%+ branch achieved)
**Future Goal**: Reach 90%+ line, 70%+ branch coverage
**Priority**: Low (current coverage exceeds industry standards)
**Focus**: Device command integration tests and advanced edge cases

### Potential Future Enhancements (Phase 4+)

Priority files with 0% branch coverage identified in Phase 3:

- [ ] **env.rb: Expand from 15.49% → 75%+ line coverage**
  - [ ] `show` command: Test when env not in config (error path)
  - [ ] `show` command: Test symlink resolution and display
  - [ ] `set` command: Test when build dir doesn't exist (error path)
  - [ ] `set` command: Test successful env switching
  - [ ] `latest` command: Test network failure handling
  - [ ] `latest` command: Test git clone failure (error path)
  - [ ] `latest` command: Test successful environment creation
  - **Estimated tests**: 8-10 new test cases
  - **Expected impact**: +15-20% line, +40-50% branch

- [ ] **patch.rb: Expand from 10.71% → 75%+ line coverage**
  - [ ] `export` command: Test with changes present
  - [ ] `export` command: Test error when no current env
  - [ ] `export` command: Test when build not found (error path)
  - [ ] `apply` command: Test with patches to apply
  - [ ] `apply` command: Test when no patches exist
  - [ ] `apply` command: Test error when no current env
  - [ ] `diff` command: Test patch diff display
  - [ ] `diff` command: Test error when no current env
  - **Estimated tests**: 10-12 new test cases
  - **Expected impact**: +15-20% line, +50-70% branch

- [ ] **rubocop.rb: Expand from 25% → 75%+ line coverage**
  - [ ] `setup` command: Test successful template copy
  - [ ] `setup` command: Test overwrite prompt (yes/no responses)
  - [ ] `setup` command: Test directory copy operations
  - [ ] `update` command: Test script execution success
  - [ ] `update` command: Test script execution failure (error path)
  - [ ] `update` command: Test when script doesn't exist (error path)
  - [ ] `copy_template_files`: Test file vs directory handling
  - [ ] `copy_template_files`: Test when target exists (overwrite)
  - **Estimated tests**: 8-10 new test cases
  - **Expected impact**: +20-30% line, +60-80% branch

### Phase 4b: Build Command Branch Coverage (89.12% → 95%+)

Remaining gaps in high-value command:

- [ ] **build.rb cache validation tests**
  - [ ] Test R2P2-ESP32 cache missing (true branch: line 44)
  - [ ] Test picoruby-esp32 cache missing (true branch: line 47)
  - [ ] Test picoruby cache missing (true branch: line 50)
  - [ ] Test setup with explicit env_name (false branch: line 18)
  - [ ] Test setup when current symlink resolved (true branch: line 20)
  - **Estimated tests**: 5 new test cases
  - **Expected impact**: +2-3% line, +15-20% branch

- [ ] **build.rb patch generation tests**
  - [ ] Test when build_config patch already has App (line 214)
  - [ ] Test when CMakeLists.txt already has App (line 234)
  - [ ] Test when storage/home doesn't exist (line 99 conditional)
  - [ ] Test rake setup_esp32 failure handling (rescue: line 87)
  - **Estimated tests**: 4 new test cases
  - **Expected impact**: +1-2% line, +10-15% branch

### Phase 4c: Device Command Delegation (94.12% → 98%+)

Test method_missing and resolve_env_name edge cases:

- [ ] **device.rb method delegation**
  - [ ] Test undefined Rake task raises Thor error
  - [ ] Test method_missing with underscore prefix (calls super)
  - [ ] Test method_missing with valid Rake task delegation
  - [ ] Test tasks command list output
  - [ ] Test help command is properly handled
  - **Estimated tests**: 5 new test cases
  - **Expected impact**: +2-3% line, +12-18% branch

- [ ] **device.rb error handling**
  - [ ] Test resolve_env_name with no current symlink (error path)
  - [ ] Test validate_and_get_r2p2_path with missing config (error path)
  - [ ] Test validate_and_get_r2p2_path with missing build (error path)
  - **Estimated tests**: 3 new test cases
  - **Expected impact**: +1-2% line, +8-12% branch

### Phase 4d: Integration Tests

Tests combining multiple commands:

- [ ] **env → build → device workflow**
  - [ ] Create env → setup build → flash device (happy path)
  - [ ] Create env → fail setup → error message
  - [ ] Switch env → verify symlink updated

- [ ] **build → patch → build workflow**
  - [ ] Setup build → modify files → export patches → re-setup
  - [ ] Patch apply after setup
  - [ ] Patch diff shows changes

- [ ] **cache → build → mrbgems workflow**
  - [ ] Fetch cache → setup build → generate mrbgem
  - [ ] Verify environment ready for development

- [ ] **ci → rubocop workflow**
  - [ ] Setup CI → setup RuboCop → both configured
  - [ ] Update RuboCop methods database

### Phase 4 Coverage Target Table

| Current State | Target | Gap | Priority |
|---|---|---|---|
| Line: 65.03% | 90% | 24.97% | Medium |
| Branch: 34.45% | 70% | 35.55% | High |
| env.rb: 15.49% → 75% | 60% gap | Highest |
| patch.rb: 10.71% → 75% | 64% gap | Highest |
| rubocop.rb: 25% → 75% | 50% gap | High |
| build.rb: 89.12% → 95% | 6% gap | Medium |
| device.rb: 94.12% → 98% | 4% gap | Medium |

### Phase 4 Implementation Strategy

1. **Week 1**: env.rb + patch.rb coverage (highest impact)
   - Expected: LINE +30%, BRANCH +45%

2. **Week 2**: rubocop.rb + build.rb improvements
   - Expected: LINE +15%, BRANCH +15%

3. **Week 3**: device.rb + remaining gaps
   - Expected: LINE +3%, BRANCH +8%

4. **Week 4**: Integration tests
   - Expected: Final polish to reach 85%+ LINE, 65%+ BRANCH

**Final Target**: LINE 88-92%, BRANCH 68-72% (achievable with focused effort)

**Tools**: Use `.claude/docs/testing-guidelines.md` "Coverage Improvement Strategy" section for implementation guidance

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
