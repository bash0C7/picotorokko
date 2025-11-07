# TODO: Project Maintenance Tasks

> **TODO Management Methodology**: See `.claude/skills/project-workflow/SKILL.md` and `CLAUDE.md` ## TODO Management section for task management rules and workflow.

## Future Enhancements (Optional)

### CLI Command Structure Refactoring

- [ ] Consider renaming commands in future if needed (e.g., `pra build-env` or `pra workspace`)

- [ ] Enhance `pra build setup` for complete build preparation
  - [ ] Add PicoRuby build step (call `rake setup_esp32` via ESP-IDF env)
  - [ ] Ensure `pra build setup` handles all pre-build requirements
  - [ ] Update documentation to reflect `pra build setup` capabilities
  - **Status**: `pra build setup` already implemented in `lib/pra/commands/build.rb`, but may need PicoRuby build step integration

- [ ] Update esp32-build.yml template for correct pra command flow
  - [ ] Ensure workflow uses: `pra cache fetch` → `pra build setup` → `pra device build`
  - [ ] Remove internal path exposure (`.cache/*/R2P2-ESP32`)
  - [ ] Remove redundant `pra patch apply` (already done in `pra build setup`)
  - [ ] Validate workflow aligns with local development workflow
  - **Status**: Template exists at `docs/github-actions/esp32-build.yml` (135 lines)
  - **Current Issues**:
    - Uses `idf.py build` directly (line 74-76) instead of `pra device build`
    - Redundant `pra patch apply` call (line 67-71)
    - Internal cache path exposed (`.cache/*/r2p2-esp32`)
  - **Solution**: Update template to use `pra device build` and remove redundant steps

- [ ] Add CI/CD update command
  - [ ] Implement `pra ci update` to refresh workflow template
  - **Location**: `lib/pra/commands/ci.rb` (currently has only `setup` subcommand)
  - **Implementation Plan**: Add `update` subcommand that:
    1. Copies updated template from `docs/github-actions/esp32-build.yml` to `.github/workflows/`
    2. Asks user confirmation before overwriting existing workflow
    3. Displays version/update information
  - **Testing**: Add test cases to `test/commands/ci_test.rb` for `update` subcommand
