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

- [ ] Test & Coverage Automation
  - [ ] Add SimpleCov for coverage measurement (target: 90%)
  - [ ] Extend `.github/workflows/main.yml` with Ruby matrix testing (3.1, 3.2, 3.3, 3.4)
  - [ ] Add coverage badge to README.md
  - [ ] Upload coverage reports to Codecov
  - [ ] Fail CI if coverage drops below threshold

- [ ] Manual Release Workflow (workflow_dispatch trigger)
  - [ ] Create `.github/workflows/release.yml`
  - [ ] Implement version bump automation
  - [ ] Build and publish gem to RubyGems.org (manual trigger only)
  - [ ] Create GitHub Release with auto-generated notes
  - [ ] Document release process in CONTRIBUTING.md
  - [ ] Setup: Requires `RUBYGEMS_API_KEY` in GitHub Secrets

#### B. For Gem Users (pra command users - PicoRuby developers)

- [ ] ESP32 Firmware Build CI Template
  - [ ] Create example workflow: `docs/github-actions/esp32-build.yml`
  - [ ] Use `espressif/esp-idf-ci-action` for ESP-IDF builds
  - [ ] Upload firmware artifacts (bootloader.bin, partition-table.bin, app.bin)
  - [ ] Document flash process after downloading artifacts:
    ```bash
    esptool.py --chip esp32 write_flash \
      0x1000 bootloader.bin \
      0x8000 partition-table.bin \
      0x10000 app.bin
    ```

- [ ] CI/CD Documentation for Users
  - [ ] Add "CI/CD Integration" section to README.md
  - [ ] Create docs/CI_CD_GUIDE.md with step-by-step setup
  - [ ] Explain firmware build artifacts and flash process
  - [ ] (Optional) Consider `pra init --ci` command to auto-generate workflow

#### C. Shared/Common Features

- [ ] Best Practices Documentation
  - [ ] Document gem development CI/CD workflow
  - [ ] Document user's PicoRuby project CI/CD workflow
  - [ ] Add troubleshooting guide for CI failures
