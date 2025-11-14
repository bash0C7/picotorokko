# picotorokko (ptrk)

**picotorokko** — [PicoRuby](https://github.com/picoruby) Application on [R2P2-ESP32](https://github.com/picoruby/R2P2-ESP32) Development Kit — is a modern build system CLI for ESP32 + PicoRuby development.

The name "picotorokko" draws inspiration from **torokko** (トロッコ), a simple lightweight railway system in Japan. Just as "Rails" in Ruby on Rails evokes railways, the "torokko" in picotorokko represents a simplified development framework that provides structure and conventions without heavyweight complexity. It manages multiple versions of R2P2-ESP32 and its nested submodules (picoruby-esp32 → picoruby) in parallel, enabling seamless environment switching and validation across versions.

[![Ruby](https://github.com/bash0C7/picotorokko/actions/workflows/main.yml/badge.svg)](https://github.com/bash0C7/picotorokko/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/bash0C7/picotorokko/branch/main/graph/badge.svg)](https://codecov.io/gh/bash0C7/picotorokko)

## Features

- **Environment Management**: Define, list, and manage multiple PicoRuby build environments with version control
- **Centralized Directory Structure**: All environment data stored in `ptrk_env/` for clean project organization
- **Git Integration**: Clone and manage repositories with automatic submodule handling
- **Patch Management**: Export, apply, and diff patches across environments
- **Task Delegation**: Build/flash/monitor tasks transparently delegated to R2P2-ESP32's Rakefile
- **Executor Abstraction**: Clean dependency injection for testable command execution with Open3 integration
- **Template Engines**: AST-based template generation for Ruby, YAML, and C code

## Development Status

### ✅ Complete Infrastructure

**Core Components**:
- Executor abstraction (ProductionExecutor for production, MockExecutor for testing)
- AST-based template engines supporting Ruby, YAML, and C templates
- Project initialization with `ptrk init` command (Phase 1-3 complete)
- Device test framework fully integrated with 199 total tests passing
- Clean code quality: RuboCop validated, 88.69% line coverage, 66.67% branch coverage

**Test Suite**:
- Main suite: 185 tests
- Device suite: 14 tests
- Total: 199 tests, all passing ✓

**Development Workflow**:
- Simplified Rake tasks for CI and development use
- Test isolation via MockExecutor for system commands
- Cumulative coverage tracking across all test suites

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'picotorokko'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install picotorokko
```

## For PicoRuby Application Users

### Quick Start

#### 1. Initialize a new project

**Always specify a project name** to avoid initializing in the current directory:

```bash
ptrk init my-project
cd my-project
```

**Optional flags**:
- `--author "Your Name"` — Set project author (default: auto-detected from git config)
- `--path /path/to/dir` — Create project in specified directory (if omitted, uses current directory as base)
- `--with-ci` — Include GitHub Actions workflow for CI/CD

**Common usage patterns**:

Default behavior (creates `./my-project/`):
```bash
ptrk init my-project
cd my-project
```

Create in a specific directory:
```bash
ptrk init my-project --path /home/user/projects
cd /home/user/projects/my-project
```

Create with CI/CD and custom author:
```bash
ptrk init my-project --with-ci --author "Alice"
cd my-project
```

**Creating additional mrbgems** (after project initialization):
```bash
ptrk mrbgems generate MySensor
ptrk mrbgems generate MyDisplay --author "Alice"
```

⚠️ **Important**: Always specify PROJECT_NAME. Running `ptrk init` without a name will initialize the current directory, not create a subdirectory.

#### 2. Declare gem dependencies (Mrbgemfile)

Create a `Mrbgemfile` in your project root to declare mrbgem dependencies:

```ruby
# Mrbgemfile - Declare mrbgem dependencies for your project
mrbgems do |conf|
  # Core mrbgems (always included)
  conf.gem core: "sprintf"
  conf.gem core: "fiber"

  # Essential libraries from GitHub
  conf.gem github: "picoruby/picoruby-json", branch: "main"
  conf.gem github: "picoruby/picoruby-yaml"

  # Platform-specific gems based on build target
  if conf.build_config_files.include?("xtensa-esp")
    conf.gem github: "picoruby/picoruby-esp32-gpio"
    conf.gem github: "picoruby/picoruby-esp32-nvs"
  elsif conf.build_config_files.include?("rp2040")
    conf.gem github: "picoruby/picoruby-rp2040-gpio"
  end

  # Local custom gems
  conf.gem path: "./mrbgems/app"
end
```

The `Mrbgemfile` is automatically applied when you build your project. It supports:
- **GitHub gems**: `github: "org/repo"` with optional `branch:` or `ref:` parameters
- **Core mrbgems**: `core: "sprintf"`
- **Local paths**: `path: "./local-gems/my-gem"`
- **Git URLs**: `git: "https://..."` with `branch:` or `ref:`
- **Conditional logic**: Include gems based on build target with `if/unless`

For complete Mrbgemfile documentation, see [docs/MRBGEMS_GUIDE.md](docs/MRBGEMS_GUIDE.md) and [SPEC.md](SPEC.md#-mrbgemfile-configuration).

#### 3. Create a new environment

```bash
ptrk env set development
```

This automatically fetches the latest versions of all repositories and stores them in `.picoruby-env.yml`.

#### 4. List all environments

```bash
ptrk env list
```

#### 5. View environment details

```bash
ptrk env show development
```

#### 6. Build, flash, and monitor

```bash
ptrk device flash --env development
ptrk device monitor --env development
ptrk device build --env development
```

### Commands Reference

#### Project Initialization

- `ptrk init [PROJECT_NAME]` - Initialize a new PicoRuby project
  - **[PROJECT_NAME]** — (Required) Name of the project. If omitted, shows usage guide
  - `--author "Name"` — Set author name (default: auto-detected from git config)
  - `--path /dir` — Create project in specified directory (default: current directory)
  - `--with-ci` — Include GitHub Actions workflow template for CI/CD

  **Default mrbgem "app"**: Every project automatically includes a default `app` mrbgem for device-specific C functions. Use this for performance tuning — implement hot paths in C while keeping most code in Ruby.

  **Creating additional mrbgems**: Use the dedicated command for more gems:
  ```bash
  ptrk mrbgems generate MySensor
  ptrk mrbgems generate MyDisplay --author "Your Name"
  ```

  **Local Development**: If developing ptrk locally, edit the generated `Gemfile` to use path reference:
  ```ruby
  gem "picotorokko", path: "../path/to/picotorokko"
  ```

  **Note**: Always provide PROJECT_NAME to create a project in a subdirectory.

#### Environment Management

- `ptrk env list` - List all environments in `ptrk_env/`
- `ptrk env set <NAME> [--commit <SHA>] [--branch <BRANCH>]` - Create or update an environment
- `ptrk env reset <NAME>` - Reset an environment by removing and recreating it
- `ptrk env show [NAME]` - Show details of a specific environment

#### Patch Management

- `ptrk env patch_export <NAME>` - Export uncommitted changes from environment to local patch directory
- `ptrk env patch_apply <NAME>` - Apply stored patches to environment
- `ptrk env patch_diff <NAME>` - Display differences between working changes and stored patches

#### Application-Specific mrbgem Management

- `ptrk mrbgems generate [NAME]` - Generate application-specific mrbgem template (default: App)
  - Creates `mrbgems/{NAME}/` with Ruby code and C extension template
  - Use `--author` option to specify author name: `ptrk mrbgems generate --author "Your Name"`

#### Mrbgemfile Configuration

The `Mrbgemfile` at your project root declares mrbgem dependencies using a Ruby DSL. It's automatically applied during `ptrk device build`.

**Gem Sources**:
- `github: "org/repo"` — GitHub repository (with optional `branch:` or `ref:`)
- `core: "sprintf"` — Core mrbgem from mruby
- `path: "./local"` — Local path (relative or absolute)
- `git: "https://..."` — Custom Git URL (with optional `branch:` or `ref:`)

**Example**:
```ruby
mrbgems do |conf|
  conf.gem core: "sprintf"
  conf.gem github: "picoruby/picoruby-json", branch: "main"

  # Platform-specific: only for ESP32
  if conf.build_config_files.include?("xtensa-esp")
    conf.gem github: "picoruby/picoruby-esp32-gpio"
  end

  conf.gem path: "./mrbgems/app"
end
```

For complete documentation and examples, see [SPEC.md#-mrbgemfile-configuration](SPEC.md#-mrbgemfile-configuration) and [docs/MRBGEMS_GUIDE.md](docs/MRBGEMS_GUIDE.md).

#### PicoRuby RuboCop Configuration

- `ptrk rubocop setup` - Setup RuboCop configuration for PicoRuby development
- `ptrk rubocop update` - Update PicoRuby method database from latest definitions

For detailed guide, see [docs/RUBOCOP_PICORUBY_GUIDE.md](docs/RUBOCOP_PICORUBY_GUIDE.md).

#### Device Operations

- `ptrk device flash --env <NAME>` - Flash firmware to ESP32
- `ptrk device monitor --env <NAME>` - Monitor ESP32 serial output
- `ptrk device build --env <NAME>` - Build firmware for ESP32
- `ptrk device setup_esp32 --env <NAME>` - Setup ESP32 build environment
- `ptrk device help --env <NAME>` - Show available R2P2-ESP32 tasks

The `ptrk device` command transparently delegates tasks to R2P2-ESP32's Rakefile:

```bash
# Run any Rake task defined in R2P2-ESP32
bundle exec ptrk device <task_name> --env <NAME>

# Examples (assuming these tasks exist in R2P2-ESP32):
bundle exec ptrk device custom_task --env development
bundle exec ptrk device build_app --env development
```

#### Other

- `ptrk version` or `ptrk -v` - Show ptrk version

### Requirements

- Ruby 3.0 or higher
- Bundler
- Git
- ESP-IDF (for build/flash/monitor tasks)

### Configuration

Environment metadata is stored in `ptrk_env/.picoruby-env.yml`. Each environment definition includes:
- Environment name (lowercase alphanumeric, hyphens, underscores: `/^[a-z0-9_-]+$/`)
- Repository paths for R2P2-ESP32, picoruby-esp32, and picoruby
- Optional: Commit SHA and branch information

### Documentation

For detailed specifications, see [SPEC.md](SPEC.md).

### CI/CD Integration

For PicoRuby application developers using GitHub Actions for automated builds, see [docs/CI_CD_GUIDE.md](docs/CI_CD_GUIDE.md).

For picotorokko gem developers releasing to RubyGems, see [CONTRIBUTING.md](CONTRIBUTING.md).

## For picotorokko Gem Developers

### Documentation

#### API Documentation

- [**RubyDoc.info**](https://rubydoc.info/gems/picotorokko/) - Generated from RBS type definitions
- [Type System & Annotations](docs/type-annotation-guide.md) - How we use rbs-inline annotations and Steep type checking

#### Architecture & Design

- [Executor Abstraction](docs/architecture/executor-abstraction-design.md) - Dependency injection pattern for system command testing with ProductionExecutor and MockExecutor
- [Prism Rakefile Parser](docs/architecture/prism-rakefile-parser-design.md) - AST-based static analysis for dynamic Rake task extraction and whitelist validation

See [docs/architecture/](docs/architecture/) for complete architecture documentation index.

#### User & Developer Guides

- [SPEC.md](SPEC.md) - Complete specification of ptrk commands and behavior
- [CI/CD Integration Guide](docs/CI_CD_GUIDE.md) - GitHub Actions workflows for PicoRuby application users
- [mrbgems Development Guide](docs/MRBGEMS_GUIDE.md) - Creating application-specific mrbgems
- [RuboCop Integration Guide](docs/RUBOCOP_PICORUBY_GUIDE.md) - RuboCop setup for PicoRuby development

### Development

After checking out the repo:

#### 1. Install dependencies

```bash
bundle install
```

#### 2. Run tests

```bash
# Run all tests (183 main + 14 device)
bundle exec rake

# Or run specific test suites
bundle exec rake test          # Main test suite only (183 tests)
```

#### 3. Development workflow: RuboCop auto-fix + tests + coverage

```bash
bundle exec rake dev
```

This runs RuboCop auto-correction, all tests, and validates coverage in one command.

#### 4. CI validation (RuboCop check + tests + coverage, no auto-fix)

```bash
bundle exec rake ci
```

This runs the complete CI checks without auto-correction (for CI/CD pipelines).

#### 5. Build the gem

```bash
bundle exec gem build picotorokko.gemspec
```

#### 6. Test CLI locally

```bash
bundle exec exe/ptrk --help
```

#### 7. Type checking with Steep (optional)

The gem includes rbs-inline type annotations for all public and private methods, enabling static type checking:

```bash
# Run Steep type checker (requires steep gem)
bundle exec steep check

# Generate RBS signatures from rbs-inline annotations
bundle exec rake rbs:generate
```

**Type Annotation Coverage**: 93.2% (165 of 177 methods)

All command classes and core modules include complete type signatures using rbs-inline format:
- **Template Engines** (19 methods): Engine, RubyTemplateEngine, StringTemplateEngine, YamlTemplateEngine, CTemplateEngine
- **Core Modules** (16 methods): Executor, PatchApplier, MrbgemsDSL, BuildConfigApplier
- **Commands** (42 methods): Device, Env, Mrbgems, Rubocop, Init

Example type annotation:

```ruby
# lib/picotorokko/commands/device.rb
class Device < Thor
  # @rbs (String) -> String
  private def resolve_env_name(env_name)
    # implementation
  end
end
```

Refer to `.claude/docs/testing-guidelines.md` for TDD + RuboCop integration workflow details.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
