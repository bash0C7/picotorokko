# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Priority 2: Documentation Generation**
  - RubyDoc.info integration for automatic API documentation from RBS type definitions
  - `rake doc:generate` task for documentation generation workflow
  - README.md documentation section with RubyDoc.info links
  - Type annotations guide referencing rbs-inline usage

### Planned

- **Priority 3: Documentation Update Automation**
  - Automated documentation update checks in development workflow
  - Documentation validation in CI pipeline

## [0.2.0] - Planned

### Planned Features

- Enhanced Mrbgemfile features (dependency resolution, version constraints)
- Local documentation generation (rbs-doc or Steep RBS docs)
- Additional device commands and workflows
- Extended CI/CD templates for GitHub Actions
- Improved error messages and user guidance

## [0.1.0] - 2025-11-14

### Added

#### Project Initialization
- `ptrk init` command for new PicoRuby project setup
- Project scaffolding with directory structure and metadata
- GitHub Actions CI/CD workflow template support (`--with-ci` flag)
- Custom author and path options
- Automatic README generation with project metadata

#### Mrbgemfile DSL (Phase 1-4)
- Ruby DSL for declaring mrbgem dependencies in `Mrbgemfile`
- Support for core mrbgems (`core: "sprintf"`)
- GitHub repository gems (`github: "org/repo"` with branch/ref support)
- Local path gems (`path: "./local-gems"`)
- Git URL gems (`git: "https://..."` with branch/ref support)
- Conditional gem inclusion based on build target
- BuildConfigApplier for inserting gems into `build_config/*.rb`
- CMakeApplier for inserting gems into CMakeLists.txt
- Integration with `ptrk device build` command
- Comprehensive error handling with Fail Fast semantics

#### Type System Integration (Priority 1)
- rbs-inline annotations across all public commands (25+ methods)
- RBS file generation from source code annotations (`rake rbs:generate`)
- Steep type checking integration (`rake steep`)
- RBS Collection with 54 external gems
- Comprehensive sig/generated/ directory structure with 5 compiled .rbs files
- Zero type check errors in production code

#### Environment Management
- List environments: `ptrk env list`
- Create/update environments: `ptrk env set <NAME> [--commit <SHA>] [--branch <BRANCH>]`
- Reset environments: `ptrk env reset`
- Show environment details: `ptrk env show [NAME]`
- Patch management: `ptrk env patch_export`, `patch_apply`, `patch_diff`
- Environment isolation with multiple coexisting build environments

#### mrbgem Generation
- Create application-specific mrbgems: `ptrk mrbgems generate [NAME]`
- Ruby code and C extension templates
- Author specification support

#### Device Operations
- Build: `ptrk device build --env <NAME>`
- Flash: `ptrk device flash --env <NAME>`
- Monitor: `ptrk device monitor --env <NAME>`
- Setup: `ptrk device setup_esp32 --env <NAME>`
- Task delegation to R2P2-ESP32 Rakefile
- Mrbgemfile DSL application to build process

#### RuboCop Integration
- Setup: `ptrk rubocop setup`
- Update: `ptrk rubocop update`
- PicoRuby method database management

#### Infrastructure
- Executor abstraction with ProductionExecutor and MockExecutor
- AST-based template engines for Ruby, YAML, C
- Device test framework integration
- Comprehensive test suite (221 tests, 100% passing)
- RuboCop validation (0 violations)
- SimpleCov coverage reporting (86.32% line, 65.12% branch)
- Pre-push hook for automated quality validation

#### Documentation
- README.md with quick start guide and command reference
- SPEC.md with complete specification of all commands
- Project Initialization Guide (docs/PROJECT_INITIALIZATION_GUIDE.md)
- mrbgems Development Guide (docs/MRBGEMS_GUIDE.md)
- CI/CD Integration Guide (docs/CI_CD_GUIDE.md)
- RuboCop Integration Guide (docs/RUBOCOP_PICORUBY_GUIDE.md)
- Architecture documentation (docs/architecture/)
- Type System documentation (.claude/docs/)

### Quality Assurance
- 221 comprehensive tests (100% passing)
- RuboCop configuration with zero violations
- SimpleCov coverage thresholds (≥85% line, ≥60% branch)
- Steep type checking with zero errors
- Pre-push validation hook

[Unreleased]: https://github.com/bash0C7/picotorokko/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bash0C7/picotorokko/releases/tag/v0.1.0
