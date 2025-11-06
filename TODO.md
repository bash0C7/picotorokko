# TODO: Project Maintenance Tasks

## Naming Convention Note

**Current name**: `pra` = **P**icoRuby **A**pplication **P**latform
**Desired name**: `pra` = **P**ico**R**uby **A**pplication

The command should be renamed from `pra` to `pra` to better reflect the project's focus on PicoRuby applications.

## High Priority

- [x] Rename command from `pra` to `pra`
  - Directory: `lib/pra/` → `lib/pra/`
  - Executable: `exe/pra` → `exe/pra`
  - Gemspec: `pra.gemspec` → `pra.gemspec`
  - Module name: `Pra` → `Pra` (all Ruby files)
  - Documentation: README.md, SPEC.md, SETUP.md, etc.
  - Test files: test/pra_test.rb → test/pra_test.rb

- [x] Add comprehensive unit tests for all commands
  - Final: 59 tests, 154 assertions, 100% passing
  - Completed tests:
    - [x] Cache commands: fetch (with mocking)
    - [x] Build commands: setup (with git repo setup)
    - [x] Patch commands: export, apply, diff (with git repo setup)
    - [x] R2P2 commands: flash, monitor (with env stubs)
  - Note: All core command functionality is tested; tests validate happy path and error handling

## Future Enhancements (Optional)

### CI/CD Integration

Implementation order: Developer features first → User features second

#### A. For Gem Developers (this repository)

- [x] Test & Coverage Automation
  - [x] Add SimpleCov for coverage measurement (target: 90%)
  - [x] Extend `.github/workflows/main.yml` with Ruby matrix testing (3.1, 3.2, 3.3, 3.4)
  - [x] Add coverage badge to README.md
  - [x] Upload coverage reports to Codecov
  - [x] Fail CI if coverage drops below threshold

- [x] Manual Release Workflow (workflow_dispatch trigger)
  - [x] Create `.github/workflows/release.yml`
  - [x] Implement version bump automation
  - [x] Build and publish gem to RubyGems.org (manual trigger only)
  - [x] Create GitHub Release with auto-generated notes
  - [x] Document release process in CONTRIBUTING.md
  - [x] Setup: Requires `RUBYGEMS_API_KEY` in GitHub Secrets

#### B. For Gem Users (pra command users - PicoRuby developers)

- [x] ESP32 Firmware Build CI Template
  - [x] Create example workflow: `docs/github-actions/esp32-build.yml`
  - [x] Use `espressif/esp-idf-ci-action` for ESP-IDF builds
  - [x] Upload firmware artifacts (bootloader.bin, partition-table.bin, app.bin)
  - [x] Document flash process after downloading artifacts:
    ```bash
    esptool.py --chip esp32 write_flash \
      0x1000 bootloader.bin \
      0x8000 partition-table.bin \
      0x10000 app.bin
    ```

- [x] CI/CD Documentation for Users
  - [x] Add "CI/CD Integration" section to README.md
  - [x] Create docs/CI_CD_GUIDE.md with step-by-step setup
  - [x] Explain firmware build artifacts and flash process
  - [x] (Optional) Consider `pra init --ci` command to auto-generate workflow
    - Implemented as `pra ci setup` instead (object-first command structure)

#### C. Shared/Common Features

- [x] Best Practices Documentation
  - [x] Document gem development CI/CD workflow
  - [x] Document user's PicoRuby project CI/CD workflow
  - [x] Add troubleshooting guide for CI failures

- [ ] Branch Protection Rules (Local execution with gh CLI)
  - [ ] Configure branch protection for `main` branch
  - [ ] Require status checks: `test` job must pass
  - [ ] Require branches to be up to date before merging
  - [ ] Optional: Require pull request reviews
  - [ ] Prevent force pushes and deletions

### CLI Command Structure Refactoring

- [ ] Clarify "environment" terminology
  - [ ] `pra env` → Manages environment definitions (`.picoruby-env.yml`)
  - [ ] `pra build` → Manages build environments (`.cache/*/r2p2-esp32/`)
  - [ ] Consider renaming to avoid confusion (e.g., `pra build-env` or `pra workspace`)

- [ ] Reorganize R2P2 device tasks under `pra device` namespace
  - [ ] Move `flash`, `monitor` to `pra device flash`, `pra device monitor`
  - [ ] Add `pra device build` command (delegates to `rake build`)
  - [ ] Add `pra device setup_esp32` command (delegates to `rake setup_esp32`)
  - [ ] Use metaprogramming to transparently delegate all R2P2-ESP32 Rake tasks
  - [ ] Avoid manual decoration for each task

- [ ] Enhance `pra build setup` for complete build preparation
  - [ ] Add PicoRuby build step (call `rake setup_esp32` via ESP-IDF env)
  - [ ] Ensure `pra build setup` handles all pre-build requirements
  - [ ] Update documentation to reflect `pra build setup` capabilities

- [ ] Update esp32-build.yml template for correct pra command flow
  - [ ] Ensure workflow uses: `pra cache fetch` → `pra build setup` → `pra device build`
  - [ ] Remove internal path exposure (`.cache/*/R2P2-ESP32`)
  - [ ] Remove redundant `pra patch apply` (already done in `pra build setup`)
  - [ ] Validate workflow aligns with local development workflow

- [x] Add CI/CD setup command
  - [x] Implement `pra ci setup` to auto-generate GitHub Actions workflow
  - [x] Copy `docs/github-actions/esp32-build.yml` to `.github/workflows/`
  - [x] Handle existing file conflicts (prompt for overwrite)
  - [ ] Optional: `pra ci update` to refresh workflow template
