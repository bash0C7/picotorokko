# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-11-05

### Added

- Initial release of pap RubyGem with Thor CLI
- Multi-version build system for ESP32 + PicoRuby development
- Environment management commands (`env show`, `env set`, `env latest`)
- Cache management commands (`cache list`, `cache fetch`, `cache clean`, `cache prune`)
- Build environment management commands (`build setup`, `build clean`, `build list`)
- Patch management commands (`patch export`, `patch apply`, `patch diff`)
- R2P2-ESP32 task delegation commands (`flash`, `monitor`)
- Immutable cache system with commit hash + timestamp identification
- Environment isolation with multiple coexisting build environments
- Patch persistence with automatic application
- SPEC.md with detailed English specification
- README.md with installation and usage guide

[Unreleased]: https://github.com/yourusername/pap/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourusername/pap/releases/tag/v0.1.0
