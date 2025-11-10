# TODO: Project Maintenance Tasks

## 📋 Outstanding Issues

### [TODO-INFRASTRUCTURE-DEVICE-TEST-FRAMEWORK]
**Status**: ROOT CAUSE IDENTIFIED - device_test.rb uses global singleton method mocking
**Problem**: Including device_test.rb in Rake::TestTask causes test framework interaction due to global state pollution
- When device_test.rb excluded: 148 tests load and pass
- When device_test.rb included: Only 59 tests load (test framework interference)
- Device tests pass independently: All 17 tests pass when run separately
- Impact: Cannot run full device test coverage in CI pipeline

**Root Cause**:
- device_test.rb uses `Pra::Env.define_singleton_method(:execute_with_esp_env)` to mock system commands
- Singleton method redefinition causes **global state pollution** across test files
- This interferes with test-unit's file loading mechanism in Rake::TestTask

**Solution**: Refactor device_test.rb to use **Refinements-based system() mocking**
1. Follow pattern in `test/commands/env_test.rb:SystemCommandMocking` module
2. Create `DeviceCommandMocking` module with `SystemRefinement`
3. Mock `system()` calls instead of `Pra::Env.execute_with_esp_env`
4. Use thread-local storage (`Thread.current[:system_mock_context]`) for mock state
5. Apply refinement with `using DeviceCommandMocking::SystemRefinement`

**Benefits**:
- No global state pollution (refinements are lexically scoped)
- CI-compatible (no test framework interference)
- Can verify exact commands being executed (better test coverage)
- Consistent with env_test.rb mocking strategy

**Priority**: HIGH - Blocks device.rb coverage expansion (currently 51.35%)

---

## 🔮 Post-Refactoring Enhancements

### AST-Based Template Engine ✅ APPROVED

**Status**: Approved for Implementation (Execute AFTER picotorokko refactoring)

**Full Specification**: [docs/PICOTOROKKO_REFACTORING_SPEC.md#template-strategy-ast-based-template-engine](docs/PICOTOROKKO_REFACTORING_SPEC.md#template-strategy-ast-based-template-engine)

**Overview**: Replace ERB-based template generation with AST-based approach (Parse → Modify → Dump)

**Key Components**:
- `Ptrk::Template::Engine` - Unified template interface
- `RubyTemplateEngine` - Prism-based (Visitor pattern)
- `YamlTemplateEngine` - Psych-based (recursive placeholder replacement)
- `CTemplateEngine` - String gsub-based

**Estimated Effort**: 8-12 days

**Priority**: High (approved, post-picotorokko)

---

## 🔬 Code Quality

### Test Coverage Targets (Low Priority)
- Current: 85.55% line, 64.85% branch (exceeds minimum thresholds)
- Ideal targets: 90% line, 70% branch
- Status: Optional enhancement, not required for release

---

## ✅ Recently Completed

### Phase 5: Device Command Refactoring (Sessions N)
- ✅ Refactored device command to use explicit `--env` flag
- ✅ Updated all device command methods: flash, monitor, build, setup_esp32, tasks, help
- ✅ Implemented `--env` option parsing for method_missing Rake task delegation
- ✅ Updated device_test.rb to use `--env` syntax (19 tests pass)
- ✅ Fixed resolve_env_name to handle new ptrk_env directory structure
- ✅ Coverage: 85.55% line, 64.85% branch
- ⚠️ Device tests excluded due to test framework interaction (documented)

**Commits**:
- `bf2bb53` - refactor: device command uses explicit --env flag
- `0a9f9cf` - fix: resolve build environment issues in device command
- `c6fe5de` - fix: validate_and_get_r2p2_path should use env_name not env_hash
- `1de99ce` - test: document device_test.rb exclusion and test framework interaction

---

## 📝 Notes for Future Sessions

- All Phases 0-4 completed successfully
- Phase 5 refactoring complete with high code quality
- Device_test.rb issue requires infrastructure investigation (may need test framework refactoring)
- Main test suite stable: 148 tests, 100% pass, 85.55% line coverage
- Ready for Phase 6+ enhancements and template engine migration
