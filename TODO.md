# TODO: Project Maintenance Tasks

## Future Enhancements (Optional)

### CI/CD Integration

- [ ] Branch Protection Rules (Local execution with gh CLI)
  - [ ] Configure branch protection for `main` branch
  - [ ] Require status checks: `test` job must pass
  - [ ] Require branches to be up to date before merging
  - [ ] Optional: Require pull request reviews
  - [ ] Prevent force pushes and deletions

### CLI Command Structure Refactoring

- [x] Clarify "environment" terminology
  - [x] `pra env` → Manages environment definitions (`.picoruby-env.yml`)
  - [x] `pra build` → Manages build environments (`build/` directories)
  - [x] Added terminology documentation and clarified code comments/messages
  - [ ] Consider renaming commands in future if needed (e.g., `pra build-env` or `pra workspace`)

- [x] Reorganize R2P2 device tasks under `pra device` namespace
  - [x] Move `flash`, `monitor` to `pra device flash`, `pra device monitor`
  - [x] Add `pra device build` command (delegates to `rake build`)
  - [x] Add `pra device setup_esp32` command (delegates to `rake setup_esp32`)
  - [x] Use metaprogramming to transparently delegate all R2P2-ESP32 Rake tasks
  - [x] Avoid manual decoration for each task

- [ ] Enhance `pra build setup` for complete build preparation
  - [ ] Add PicoRuby build step (call `rake setup_esp32` via ESP-IDF env)
  - [ ] Ensure `pra build setup` handles all pre-build requirements
  - [ ] Update documentation to reflect `pra build setup` capabilities

- [ ] Update esp32-build.yml template for correct pra command flow
  - [ ] Ensure workflow uses: `pra cache fetch` → `pra build setup` → `pra device build`
  - [ ] Remove internal path exposure (`.cache/*/R2P2-ESP32`)
  - [ ] Remove redundant `pra patch apply` (already done in `pra build setup`)
  - [ ] Validate workflow aligns with local development workflow

- [ ] Add CI/CD update command
  - [ ] Implement `pra ci update` to refresh workflow template
