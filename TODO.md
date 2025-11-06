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

- [ ] Add comprehensive unit tests for all commands
  - Progress: 41 tests, 112 assertions, 100% passing
  - Remaining tests needed:
    - Cache commands: fetch (requires network/git mocking)
    - Build commands: setup (complex, requires git repo setup)
    - Patch commands: export, apply, diff (requires git repo setup)
    - R2P2 commands: flash, monitor (delegates to Rakefile, complex to test)

## Future Enhancements (Optional)

- [ ] キャッシュ圧縮機能
  - `tar.gz` で`.cache/`を圧縮
  - S3/Cloud ストレージへのバックアップ

- [ ] CI/CD 統合
  - GitHub Actions でキャッシュの自動更新
  - 自動テストとリリース
