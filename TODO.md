# TODO: Project Maintenance Tasks

## Naming Convention Note

**Current name**: `pap` = **P**icoRuby **A**pplication **P**latform
**Desired name**: `pra` = **P**ico**R**uby **A**pplication

The command should be renamed from `pap` to `pra` to better reflect the project's focus on PicoRuby applications.

## Critical Issues

- [x] **[BUG] Fix `pap build` command name collision** (lib/pap/cli.rb)
  - ✓ **Resolved with Option A**: Removed R2P2 `build` from top-level
  - Changes:
    - lib/pap/cli.rb: Excluded `build` from R2P2 task delegation (line 34)
    - lib/pap/commands/r2p2.rb: Removed `build` method
    - SPEC.md: Updated documentation and workflow examples
  - **Result**: Only `pap flash` and `pap monitor` available as R2P2 delegation commands
  - **Build workflow**: Use `rake build` directly in R2P2-ESP32 directory

## High Priority

- [ ] Rename command from `pap` to `pra`
  - Directory: `lib/pap/` → `lib/pra/`
  - Executable: `exe/pap` → `exe/pra`
  - Gemspec: `pap.gemspec` → `pra.gemspec`
  - Module name: `Pap` → `Pra` (all Ruby files)
  - Documentation: README.md, SPEC.md, SETUP.md, etc.
  - Test files: test/pap_test.rb → test/pra_test.rb

- [x] `pap env latest` の実装 (lib/pap/commands/env.rb:71)
  - ✓ GitHub API または `git ls-remote` で最新コミット取得
  - ✓ 自動的に .picoruby-env.yml に追記
  - Note: キャッシュ取得は別コマンドとして実装済み
  - TODO: ユニットテストの追加

- [ ] Add comprehensive unit tests for all commands
  - Progress: 38 tests, 93 assertions, 100% passing
  - ✓ Basic tests: VERSION constant, CLI version command (test/pap_test.rb)
  - ✓ Env module tests: YAML operations, environment management, symlinks (test/env_test.rb)
  - ✓ Env commands: show, set (test/commands/env_test.rb)
  - ✓ Cache commands: list, clean, prune (test/commands/cache_test.rb)
  - ✓ Build commands: clean, list (test/commands/build_test.rb)
  - Remaining tests needed:
    - Env commands: latest (requires network/git mocking)
    - Cache commands: fetch (requires network/git mocking)
    - Build commands: setup (complex, requires git repo setup)
    - Patch commands: export, apply, diff (requires git repo setup)
    - R2P2 commands: flash, monitor (delegates to Rakefile, complex to test)

## Documentation

- [x] Fix SPEC.md and README.md inconsistencies
  - ✓ SPEC.md already has Changelog section (line 642-646)
  - ✓ Updated SPEC.md: Removed R2P2 `pap build` command documentation
  - ✓ README.md and SPEC.md now align on all command definitions
  - ✓ Documented the resolution of `pap build` name collision
  - Note: CHANGELOG.md (line 20) correctly lists only `flash` and `monitor`, not `build`

- [x] Update documentation after fixing `pap build` collision
  - ✓ Updated SPEC.md Section 5 (R2P2-ESP32 Task Delegation)
  - ✓ Updated all workflow examples (Scenario 1, 2, 3) to use `rake build` directly
  - README.md already correct (no changes needed)

- [x] Fix CHANGELOG.md URL placeholders (line 27-28)
  - ✓ Updated to: `https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/...`

- [x] Consider adding example .picoruby-env.yml file
  - ✓ Added `.picoruby-env.yml.example` with sample configuration
  - ✓ Based on SPEC.md (line 131-163) sample
  - ✓ Includes usage instructions and two example environments

## Future Enhancements (Optional)

- [ ] キャッシュ圧縮機能
  - `tar.gz` で`.cache/`を圧縮
  - S3/Cloud ストレージへのバックアップ

- [ ] CI/CD 統合
  - GitHub Actions でキャッシュの自動更新
  - 自動テストとリリース
