# TODO: Project Maintenance Tasks

> **TODO Management Methodology**: See `.claude/skills/project-workflow/SKILL.md` and `CLAUDE.md` ## TODO Management section for task management rules and workflow.

## 🟢 mrbgems Support Feature (Large Feature)

See **[TODO_mrbgems.md](TODO_mrbgems.md)** for comprehensive implementation plan.

**Summary**: Implement `pra mrbgems generate` command and app setup flow to allow users to create application-specific mrbgems (like `App`) with C language code integration. Includes template system, build_config registration, and CMakeLists.txt integration.

---

## Future Enhancements (Optional)

### CLI Command Structure Refactoring

- [ ] Consider renaming commands in future if needed (e.g., `pra build-env` or `pra workspace`)

---

### ⚠️ pra ci: --force Option (Implementation Forbidden)

**Status**: `pra ci setup` already implemented. The `--force` option is **forbidden** unless explicitly requested.

- 🚫 **Do not implement** `pra ci setup --force` option
  - **Current behavior**: Interactive prompt "Overwrite? (y/N)" if file exists
  - **Reason forbidden**: CI templates follow "fork and customize" model; users should own and edit templates directly
  - **Permitted**: Modify CI templates and documentation in `docs/`

---

## 🔴 High Priority (CI/Testing Strategy)

### CI Test Execution Strategy - ESP-IDF Dependency Issue

- [ ] **Resolve: Tests fail in CI due to ESP-IDF environment missing**
  - **Problem**:
    - CI workflow executes `bundle exec rake ci`, which runs all tests
    - Tests like `device_test.rb` call `execute_with_esp_env`, which tries to source `$IDF_PATH/export.sh`
    - CI environment doesn't have ESP-IDF installed → `export.sh` not found → bash fails
    - Although test code has stubs for `execute_with_esp_env`, the test loading/setup phase still triggers actual bash execution
  - **Root Cause**:
    - User's `~/.bashrc` or shell profile auto-activates ESP-IDF on all shell invocations
    - Local dev environment: works fine (ESP-IDF installed, `export.sh` exists)
    - CI environment: fails (no ESP-IDF, `export.sh` doesn't exist)
  - **Temporary Fix** (current branch fix_ci):
    - Reduce CI test scope to minimal, safe tests
    - Modify `.github/workflows/main.yml` to run only `test/pra_test.rb`
    - This runs version check only (no external dependencies)
    - Reduce SimpleCov minimum coverage to line: 1, branch: 1 (temporary)
    - Goal: Get CI green while planning long-term solution
  - **Long-term Solution** (future task):
    - Separate tests into layers:
      1. **Unit tests** (no external tools): YAML parsing, env management, git operations
      2. **Integration tests** (require ESP-IDF): device commands, build setup
    - Create separate CI job for integration tests (only run on demand or main branch)
    - Or mock `execute_with_esp_env` at module load time (not in individual tests)
    - Or wrap `execute_with_esp_env` to detect CI environment and skip ESP-IDF execution
  - **Files to Update**:
    - `.github/workflows/main.yml` (line 26): Change `bundle exec rake ci` to `bundle exec rake test TEST=test/pra_test.rb`
    - `test/test_helper.rb`: Restore coverage requirements (line: 80, branch: 50) once test scope expands
  - **Related Issues**:
    - PR #30 failing CI checks
    - Need to ensure other test files work before expanding test scope

### Setup Git Hooks for Local RuboCop & Test Execution

- [ ] **Add git hooks to run RuboCop and tests before commit**
  - **Problem**:
    - RuboCop violations and test failures are only caught in CI
    - Developers may commit code that fails CI checks
    - Wastes CI time on fixes that could be caught locally
  - **Solution**:
    - Setup husky + pre-commit hooks (or custom git hooks)
    - Run on `git commit`:
      1. `bundle exec rubocop --autocorrect-all` (auto-fix style)
      2. `bundle exec rake test` (run full test suite)
      3. Block commit if tests fail
    - Alternative: Add rake task `rake pre-commit` and document in CONTRIBUTING.md
  - **Implementation Options**:
    1. **Husky + lint-staged** (recommended for Node.js projects, but Ruby also works)
    2. **Direct git hooks** (.git/hooks/pre-commit script)
    3. **Rake task + documentation** (simplest for Ruby projects)
  - **Related Files**:
    - `.git/hooks/pre-commit` (to create or document)
    - `CONTRIBUTING.md` (to add developer setup instructions)
    - `Rakefile` (if adding pre-commit task)

### Restore SimpleCov Coverage Requirements

- [ ] **Restore: Increase SimpleCov minimum coverage back to line: 80, branch: 50**
  - **Current State** (temporary fix):
    - `test/test_helper.rb` has minimum_coverage line: 1, branch: 1
    - This allows CI to pass with minimal test scope
  - **Problem**:
    - Current minimum (1%) is too low for production code quality
    - Allows untested code to merge without warning
  - **Solution** (when expanding test scope):
    1. Expand test suite to cover more code paths
    2. Run full test suite: `bundle exec rake ci` (all test files)
    3. Restore `test/test_helper.rb` line 11:
       ```ruby
       minimum_coverage line: 80, branch: 50 if ENV["CI"]
       ```
  - **Prerequisite**:
    - Must fix ESP-IDF dependency issue first (see "CI Test Execution Strategy" above)
    - All test files must pass in CI without ESP-IDF environment
  - **Related Files**:
    - `test/test_helper.rb` (line 11)
    - `.github/workflows/main.yml` (line 26) - will change from `TEST=test/pra_test.rb` back to `ci` task
    - `.codecov.yml` - Change `informational: true` back to `informational: false` when coverage requirements are restored

---

## 🟡 Medium Priority (Code Quality & Documentation)

### README.md Documentation Updates

- [ ] Update README.md with current command structure
  - **Fix incorrect command examples**:
    - `pra flash` → `pra device flash`
    - `pra monitor` → `pra device monitor`
    - `pra r2p2 flash` → `pra device flash` (or remove if obsolete)
  - **Add `pra device` command section** documenting:
    - Explicit subcommands: `flash`, `monitor`, `build`, `setup_esp32`
    - Dynamic Rake task delegation via method_missing
    - Examples: `pra device <custom_rake_task>`
    - **Implement `pra device help` command**: Execute `rake -T` in R2P2-ESP32 directory and display available tasks
      - **Files to Update**: `lib/pra/commands/device.rb`, `test/commands/device_test.rb`
      - **Implementation**: Add `help` method that resolves environment, builds R2P2-ESP32 path, executes `Pra::Env.execute_with_esp_env("rake -T", r2p2_path)`, and displays output

### Refactor Duplicate Patch Application Logic

- [ ] Consolidate patch application logic in `lib/pra/commands/build.rb` and `lib/pra/commands/patch.rb`
  - **Problem**: Identical FileUtils.cp_r + Dir.glob pattern repeated in two files
  - **Solution**: Extract to `lib/pra/patch_applier.rb` shared module
  - **Testing**: Verify existing tests pass; add tests for refactored logic

### Refactor Duplicate Environment Hash Generation

- [ ] Centralize environment hash generation logic across commands
  - **Where**: Duplicated in `lib/pra/commands/device.rb`, `lib/pra/commands/build.rb`, `lib/pra/commands/cache.rb`
  - **Problem**: SHA256 hash calculation repeated 5+ times; hard to maintain if algorithm changes
  - **Solution**: Add `compute_env_hash(env_name)` method to `lib/pra/env.rb` and call from all commands
  - **Testing**: Verify existing tests pass

### CI_CD_GUIDE.md YAML Schema Alignment

- [ ] Verify CI_CD_GUIDE.md examples match actual .picoruby-env.yml schema
  - **Problem**: YAML example structure may not match actual schema in `lib/pra/env.rb`
  - **Fix**: Ensure documentation examples are consistent with schema implementation

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
