# TODO: Project Maintenance Tasks

## Naming Convention Note

**Current name**: `pap` = **P**icoRuby **A**pplication **P**latform
**Desired name**: `pra` = **P**ico**R**uby **A**pplication

The command should be renamed from `pap` to `pra` to better reflect the project's focus on PicoRuby applications.

## Critical Issues

- [ ] **[BUG] Fix `pap build` command name collision** (lib/pap/cli.rb)
  - Problem: `pap build` has two conflicting definitions:
    1. Build Environment Management: `pap build setup/clean/list` (line 25)
    2. R2P2-ESP32 Task Delegation: `pap build [ENV_NAME]` (line 32-39)
  - Impact: `pap build --help` fails, treating `--help` as environment name
  - Discrepancy: SPEC.md defines both, README.md only defines Build Environment Management
  - Solution options:
    - Option A: Remove R2P2 `build` from top-level, keep only `pap flash` and `pap monitor`
    - Option B: Rename R2P2 build to `pap compile [ENV_NAME]`
    - Option C: Move R2P2 tasks to subcommand `pap r2p2 build/flash/monitor`
  - Recommended: **Option A** - matches README.md and avoids confusion

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
  - Current state: test/pap_test.rb has only placeholder tests (line 12-14)
  - Line 13: `assert_equal("expected", "actual")` is a failing placeholder test
  - Required tests:
    - Env commands: show, set, latest
    - Cache commands: list, fetch, clean, prune
    - Build commands: setup, clean, list
    - Patch commands: export, apply, diff
    - R2P2 commands: flash, monitor (build is in conflict, see Critical Issues)

## Documentation

- [ ] Fix SPEC.md and README.md inconsistencies
  - ✓ SPEC.md already has Changelog section (line 642-646)
  - [ ] Update SPEC.md: Remove or clarify R2P2 `pap build` command (line 492-510)
  - [ ] Ensure README.md and SPEC.md align on all command definitions
  - [ ] Add missing command descriptions if any
  - [ ] Document the resolution of `pap build` name collision
  - Note: CHANGELOG.md (line 20) correctly lists only `flash` and `monitor`, not `build`

- [ ] Update documentation after fixing `pap build` collision
  - Update SPEC.md Section 5 (R2P2-ESP32 Task Delegation)
  - Update README.md if needed
  - Update any workflow examples that use conflicting commands

- [ ] Fix CHANGELOG.md URL placeholders (line 27-28)
  - Current: `https://github.com/yourusername/pap/...`
  - Should be: `https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/...`

- [ ] Consider adding example .picoruby-env.yml file
  - SPEC.md (line 131-163) provides sample configuration
  - No example file exists in repository for users to reference
  - Could add `.picoruby-env.yml.example` or document in README

## Future Enhancements (Optional)

- [ ] キャッシュ圧縮機能
  - `tar.gz` で`.cache/`を圧縮
  - S3/Cloud ストレージへのバックアップ

- [ ] CI/CD 統合
  - GitHub Actions でキャッシュの自動更新
  - 自動テストとリリース
