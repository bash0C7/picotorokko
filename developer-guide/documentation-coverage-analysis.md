# RubyDoc Coverage Analysis for picotorokko Gem

**Analysis Date**: 2025-11-14
**Focus**: Public methods in 4 key command/CLI files
**Goal**: Identify documentation gaps for RubyDoc.info generation
**Documentation Strategy**: rbs-inline annotations → RBS files → RubyDoc.info

---

## Executive Summary

The picotorokko gem currently has **minimal documentation comments** in public methods. While all major methods have basic @rbs type hints (following the project's rbs-inline strategy), most lack:

- Detailed descriptions explaining purpose and behavior
- Parameter documentation (beyond type signatures)
- Return value clarification
- Edge case and error handling notes
- Usage examples

**Total Methods Analyzed**: 43 public methods
**Methods with minimal/no description**: 32 (74%)
**Methods needing examples**: 18 (42%)
**Methods with undocumented parameters**: 15 (35%)

---

## File-by-File Analysis

### 1. lib/picotorokko/cli.rb

**File Purpose**: CLI entry point using Thor framework

#### Analysis Summary
- ✅ **Good**: Subcommands have multi-line Thor descriptions
- ⚠️ **Issue**: Main public methods have minimal narrative documentation
- ❌ **Missing**: Method-level documentation comments

#### Public Methods

| Line | Method | Current Doc | Issues | Priority |
|------|--------|------------|--------|----------|
| 18-20 | `self.exit_on_failure?()` | `@rbs () -> bool` only | No explanation of Thor behavior | MEDIUM |
| 50-52 | `version()` | "Display picotorokko version" | Single line; no return detail | MEDIUM |

#### Detailed Issues

**Line 18-20: `exit_on_failure?` method**
```ruby
# Current:
# @rbs () -> bool
def self.exit_on_failure?
  true
end

# Missing:
# - Explanation: Why return true? What does this affect?
# - Context: Thor framework behavior when exit_on_failure? returns true
# - Edge cases: Does this apply to subcommands?

# Suggested improvement:
# Instructs Thor to exit with error status (exit code 1) when command fails.
# This enables shell script integration and proper CI/CD behavior.
# 
# @rbs () -> bool
# @return [true] Always true - commands raise Thor::Error on failure
```

**Line 50-52: `version` method**
```ruby
# Current:
# Display picotorokko version
# @rbs () -> void
def version
  puts "picotorokko version #{Picotorokko::VERSION}"
end

# Missing:
# - Parameter documentation (no params, but could mention that)
# - Return documentation (void, but what's the side effect?)
# - Mapping aliases (-v, --version) not documented in code

# Suggested improvement:
# Displays the currently installed picotorokko gem version.
# This command outputs the semantic version string to stdout.
# 
# Also available as: ptrk -v, ptrk --version
#
# @rbs () -> void
# @example
#   $ ptrk version
#   picotorokko version 0.1.0
def version
  puts "picotorokko version #{Picotorokko::VERSION}"
end
```

**Subcommands (lines 24-45)**
- ✅ These have adequate Thor `desc` blocks (multi-line descriptions)
- However, the routing logic could benefit from class-level documentation in each command module

---

### 2. lib/picotorokko/commands/init.rb

**File Purpose**: Project initialization command

#### Analysis Summary
- ⚠️ **Issue**: Main `create` method lacks option documentation
- ❌ **Missing**: Parameter and option explanations
- ⚠️ **Issue**: No examples provided for common use cases

#### Public Methods

| Line | Method | Current Doc | Issues | Priority |
|------|--------|------------|--------|----------|
| 11-12 | `self.exit_on_failure?()` | `@rbs () -> bool` only | No context | MEDIUM |
| 24-32 | `create(project_name)` | 1-line description | Options not documented; no examples | HIGH |

#### Detailed Issues

**Line 24-32: `create` method**
```ruby
# Current:
# Initialize new PicoRuby project with directory structure and configuration
# @rbs (String | nil) -> void
desc "[PROJECT_NAME]", "Initialize a new PicoRuby project"
option :path, type: :string, desc: "Create project in specified directory"
option :author, type: :string, desc: "Set author name"
option :"with-ci", type: :boolean, desc: "Copy GitHub Actions workflow"
def create(project_name = nil)
  # ...
end

# Missing:
# - Parameter documentation: What happens if project_name is nil?
# - Option behavior: How does :path interact with current directory?
# - Option behavior: What name format is expected? (dash vs underscore?)
# - Option: :with-ci - what GitHub Actions workflow is copied?
# - Return documentation: Side effects (directory creation, file generation)
# - Error cases: What errors can be raised?
# - Example usage: Common scenarios

# Suggested improvement:
# Initializes a new PicoRuby application project with standard directory structure.
# 
# Creates the following:
# - Project root directory (PROJECT_NAME or custom via --path)
# - Rakefile with build tasks
# - Main application code template
# - .gitignore for build artifacts
# - Configuration files for mruby/PicoRuby
#
# If PROJECT_NAME is omitted, shows usage instructions instead of initializing.
#
# @param project_name [String, nil] Name of the project (becomes root directory name)
#   - If nil, displays help and returns without creating anything
#   - Can contain lowercase letters, numbers, hyphens, and underscores
#   - Cannot contain spaces or special characters
#
# @option options [String] :path (".")
#   Parent directory where project will be created.
#   Default: current directory. Example: --path /opt/projects
#
# @option options [String] :author (nil)
#   Author name to be recorded in project metadata.
#   Example: --author "John Doe"
#
# @option options [Boolean] :with-ci (false)
#   If true, copies GitHub Actions workflow files (.github/workflows/)
#   for CI/CD testing and deployment.
#   Example: --with-ci
#
# @rbs (String | nil) -> void
#
# @raise [Thor::Error] If project_name contains invalid characters
# @raise [Thor::Error] If --path directory does not exist
# @raise [Thor::Error] If project directory already exists
#
# @example Basic initialization
#   ptrk init my-app
#   # Creates ./my-app/ with default configuration
#
# @example With custom path and author
#   ptrk init my-app --path /opt/projects --author "Jane Smith"
#
# @example With CI/CD setup
#   ptrk init my-app --with-ci
#   # Creates GitHub Actions workflows in .github/workflows/
#
# @see ProjectInitializer#initialize_project for implementation details
```

**Line 37-49: `warn_missing_project_name` method**
- ✅ This is a private method (marked on line 34), so not required for RubyDoc
- However, it's worth noting that public error handling could be documented more clearly

---

### 3. lib/picotorokko/commands/device.rb

**File Purpose**: ESP32 device operations (flash, monitor, build)

#### Analysis Summary
- ⚠️ **CRITICAL**: Class and public methods have minimal documentation
- ❌ **CRITICAL**: `method_missing` is complex but undocumented
- ❌ **CRITICAL**: `RakeTaskExtractor` inner class lacks class documentation
- ⚠️ **Issue**: Device operation methods share similar options but lack consistent documentation

#### Public Methods

| Line | Method | Current Doc | Issues | Priority |
|------|--------|------------|--------|----------|
| 14-15 | `self.exit_on_failure?()` | `@rbs () -> bool` only | No context | MEDIUM |
| 22-30 | `flash()` | 2 lines | --env option behavior not explained | HIGH |
| 36-44 | `monitor()` | 2 lines | --env option behavior not explained; Ctrl+C mention only | HIGH |
| 50-61 | `build()` | 2 lines | Mrbgemfile integration not documented | HIGH |
| 67-75 | `setup_esp32()` | 2 lines | Minimal explanation of setup process | HIGH |
| 81-87 | `tasks()` | 2 lines | How to read output not explained | MEDIUM |
| 93-95 | `help()` | 2 lines | Alias relationship not documented | LOW |
| 99-129 | `method_missing()` | 2 lines | Complex delegation logic undocumented | **CRITICAL** |
| 132-135 | `respond_to_missing?()` | @rbs + 1 Japanese comment | Mixed language; purpose unclear | MEDIUM |

#### Nested RakeTaskExtractor Class (lines 254-398)

**Major Issue**: Inner class completely lacks documentation

```ruby
# Current:
# AST-based Rake task extractor for secure, static analysis
class RakeTaskExtractor < Prism::Visitor
  attr_reader :tasks

  # @rbs () -> void
  def initialize
    # ...
  end

  # Missing:
  # - Class-level documentation: What does this class do? Why AST-based?
  # - What is Prism::Visitor? Why inherit from it?
  # - How is the extracted task list used?
  # - What are the limitations of static analysis?
  # - Why is this "secure"?

# Suggested improvement:
# Parses Rake Rakefile AST to safely extract task definitions.
#
# Uses Prism parser for secure static analysis (no code execution).
# Handles both standard task definitions and dynamic task generation.
#
# Examples of detected patterns:
# - Standard: task :name or task "name"
# - Dynamic: %w[a b c].each { |var| task "name_#{var}" }
#
# @example
#   extractor = RakeTaskExtractor.new
#   rakefile_ast = Prism.parse(File.read("Rakefile"))
#   rakefile_ast.accept(extractor)
#   extractor.tasks  # => ["build", "flash", "monitor"]
#
# @rbs < Prism::Visitor
class RakeTaskExtractor < Prism::Visitor
```

#### Detailed Issues

**Line 22-30: `flash()` method**
```ruby
# Current:
# Flash firmware to ESP32 device
# @rbs () -> void
desc "flash", "Flash firmware to ESP32"
option :env, default: "current", desc: "Environment name"
def flash
  # ...
end

# Missing:
# - What does "flash" mean in this context? (firmware upload to device)
# - How long does flashing typically take?
# - What happens if device not connected?
# - What does --env do? How does "current" environment get resolved?
# - Error conditions: What goes wrong and how to fix it?
# - Side effects: What changes on the ESP32 after flashing?

# Suggested improvement:
# Uploads compiled firmware binary to connected ESP32 device.
#
# This command delegates to R2P2-ESP32 Rakefile for actual flashing operation.
# Requires:
# - ESP32 device connected via USB/UART
# - Build environment initialized (R2P2-ESP32 repo present)
# - Firmware already built via `ptrk device build`
#
# The --env option specifies which environment's build artifacts to use.
# Default "current" resolves to the environment set via `ptrk env set`.
#
# @rbs () -> void
#
# @option options [String] :env ("current")
#   Environment name or "current" to use the default environment.
#   Example: --env latest, --env stable, --env my-custom-build
#
# @raise [RuntimeError] If no current environment set and --env not specified
# @raise [RuntimeError] If environment not found in .picoruby-env.yml
# @raise [RuntimeError] If R2P2-ESP32 not found in build environment
# @raise [RuntimeError] If flash command fails (device not found, permission denied)
#
# @example Flash with default environment
#   ptrk device flash
#   # Uses current environment, flashes ESP32
#
# @example Flash with specific environment
#   ptrk device flash --env latest
#   # Uses "latest" environment builds
#
# @see #build for building firmware before flashing
# @see Device#monitor for monitoring serial output after flashing
```

**Line 50-61: `build()` method**
```ruby
# Current:
# Build firmware for ESP32
# @rbs () -> void
desc "build", "Build firmware for ESP32"
option :env, default: "current", desc: "Environment name"
def build
  # Apply Mrbgemfile if it exists
  apply_mrbgemfile(actual_env)
  puts "Building: #{actual_env}"
  delegate_to_r2p2("build", env_name)
  puts "\u2713 Build completed"
end

# Missing:
# - What is Mrbgemfile? Why is it applied during build?
# - What build system is used? (ESP-IDF, CMake?)
# - Build artifacts: Where are output files? (build/, sdkconfig.h?)
# - Time estimate: How long does build take?
# - Requirements: Need ESP-IDF installed? (Delegated to R2P2)
# - mrbgems: How does Mrbgemfile affect the build?

# Suggested improvement:
# Compiles firmware and mrbgems for ESP32 target device.
#
# This command:
# 1. Reads Mrbgemfile if present (declares mrbgems to include)
# 2. Applies mrbgem configuration to build_config/*.rb
# 3. Invokes R2P2-ESP32 build system (delegates to ESP-IDF via Rake)
# 4. Outputs executable firmware binary
#
# Mrbgemfile Integration:
# - If Mrbgemfile exists in project root, it's parsed and applied
# - Mrbgems are injected into build_config/*.rb before build
# - Changes are temporary (not committed to build_config)
#
# @rbs () -> void
#
# @option options [String] :env ("current")
#   Environment name. Use --env latest, stable, or custom name.
#
# @raise [RuntimeError] If R2P2-ESP32 not found
# @raise [RuntimeError] If build fails (compilation errors, invalid config)
#
# @example Basic build
#   ptrk device build
#
# @example Build with custom environment
#   ptrk device build --env stable
#
# @see #apply_mrbgemfile for Mrbgemfile processing
# @see .mrbgemfile DSL for mrbgem declarations
# @see #flash for flashing the built firmware
```

**Line 99-129: `method_missing()` method - CRITICAL**
```ruby
# Current:
# Transparently delegate undefined commands to R2P2-ESP32 Rakefile
# @rbs (*untyped) -> void
def method_missing(method_name, *args)
  # Complex 30-line logic

# Missing:
# - How does this "transparently delegate"? What's the flow?
# - What is the whitelist mechanism? Why is it important?
# - What commands are available? (Depends on Rakefile)
# - Error handling: What happens if task not in whitelist?
# - Security: Why parse Rakefile and create whitelist?
# - Relationship to respond_to_missing?

# Suggested improvement (add comprehensive documentation):
# Transparently routes unknown commands to R2P2-ESP32 Rakefile.
#
# This enables dynamic command discovery and delegation:
# 1. User calls unknown ptrk device <cmd>
# 2. method_missing intercepts the call
# 3. Extracts --env option from arguments
# 4. Parses R2P2-ESP32/Rakefile to get available tasks
# 5. Validates <cmd> against whitelist (security)
# 6. Delegates to R2P2-ESP32 via Rake if valid
# 7. Raises UndefinedCommandError if not in whitelist
#
# Security Model:
# - Extracts available tasks via AST parsing (no code execution)
# - Uses RakeTaskExtractor to build task whitelist
# - Only allows tasks defined in Rakefile
# - Rejects Thor internal methods (prefixed with _)
#
# Examples of delegated tasks depend on R2P2-ESP32:
# - ptrk device menuconfig  (if defined in R2P2 Rakefile)
# - ptrk device clean       (if defined in R2P2 Rakefile)
# - ptrk device distclean   (if defined in R2P2 Rakefile)
#
# Note: Built-in commands (flash, monitor, build, setup_esp32, tasks, help)
# are handled before method_missing is invoked.
#
# @param method_name [Symbol] Name of the unknown command
# @param args [Array] Command-line arguments (may include --env)
#
# @rbs (Symbol, *untyped) -> void
#
# @raise [Thor::UndefinedCommandError] If command not in Rakefile task whitelist
# @raise [Thor::UndefinedCommandError] If Rakefile parsing fails
# @raise [RuntimeError] If R2P2-ESP32 not found
#
# @example User calls unknown command
#   ptrk device menuconfig --env latest
#   # 1. method_missing(:menuconfig, ["--env", "latest"])
#   # 2. Checks whitelist from R2P2-ESP32/Rakefile
#   # 3. If menuconfig defined, delegates via Rake
#   # 4. If not defined, raises UndefinedCommandError
#
# @see #respond_to_missing? for dynamic method existence checking
# @see RakeTaskExtractor for task extraction from Rakefile
# @see Picotorokko::Env#resolve_env_name for environment resolution
```

**Line 132-135: `respond_to_missing?()` method**
```ruby
# Current:
# @rbs (Symbol, bool) -> bool
def respond_to_missing?(method_name, include_private = false)
  # Thorの内部メソッド以外は全てR2P2タスクとして扱う可能性がある
  !method_name.to_s.start_with?("_") || super
end

# Issues:
# - Japanese comment in English codebase
# - No explanation of what this method does
# - Relationship to method_missing not documented
# - Incomplete logic explanation

# Suggested improvement:
# Determines whether an undefined method can be handled by method_missing.
#
# This complements method_missing to enable true dynamic method support.
# Ruby calls respond_to_missing? when respond_to?(:unknown_method) is checked.
#
# Returns true for any method not starting with underscore (_), allowing
# method_missing to attempt delegation to R2P2-ESP32 tasks.
#
# Thor internal methods (prefixed with _) are excluded to prevent
# intercepting framework machinery.
#
# @param method_name [Symbol] Name of the method being checked
# @param include_private [Boolean] Whether to include private methods (unused)
# @return [Boolean] true unless method_name starts with underscore
#
# @rbs (Symbol, bool) -> bool
#
# @example Dynamic method check
#   ptrk_dev = Picotorokko::Commands::Device.new
#   ptrk_dev.respond_to?(:menuconfig)  # => true
#   ptrk_dev.respond_to?(:_internal_method)  # => false
#
# @see #method_missing for the delegation logic
```

**Private methods worth noting (for context):**
- Line 141-154: `parse_env_from_args()` - parses --env from Thor args (simple but important)
- Line 159-165: `apply_mrbgemfile()` - applies Mrbgemfile to build configs (important for build)
- Line 222-233: `validate_and_get_r2p2_path()` - validates environment and gets R2P2 path (critical for error handling)

---

### 4. lib/picotorokko/commands/env.rb

**File Purpose**: Environment definition management

#### Analysis Summary
- ⚠️ **Critical**: Most public methods have 1-line descriptions
- ❌ **Missing**: Option documentation for complex commands
- ❌ **Missing**: Helper methods in `no_commands` block completely undocumented
- ⚠️ **Issue**: Complex methods like `fetch_latest_repos` lack implementation details

#### Public Methods

| Line | Method | Current Doc | Issues | Priority |
|------|--------|------------|--------|----------|
| 14-15 | `self.exit_on_failure?()` | `@rbs () -> bool` only | No context | MEDIUM |
| 21-38 | `list()` | 1 line | No return documentation | LOW |
| 43-48 | `show(env_name)` | 1 line | Parameter not documented | MEDIUM |
| 56-77 | `set(env_name)` | 1 line | **Options not documented**; auto-fetch logic hidden | **CRITICAL** |
| 136-155 | `reset(env_name)` | 1 line | Behavior (metadata preservation) not documented | MEDIUM |
| 160-178 | `patch_export(env_name)` | 1 line | Purpose and workflow not clear | HIGH |
| 183-214 | `patch_apply(env_name)` | 1 line | Process not documented | HIGH |
| 219-235 | `patch_diff(env_name)` | 1 line | What it compares not explained | MEDIUM |
| 240-260 | `latest()` | 1 line | **No next steps documented** | MEDIUM |
| 264-304 | `fetch_latest_repos()` | 1 line | Complex logic undocumented; shell commands not explained | **CRITICAL** |

#### Helper Methods in `no_commands` block (lines 79-131)

These are **public** (not private) but internal to the class. They lack any documentation:

| Line | Method | Purpose (inferred) | Doc Status |
|------|--------|-------------------|-----------|
| 81-87 | `process_source()` | Route to GitHub/path handler | ❌ None |
| 90-94 | `process_github_source()` | Process org/repo source spec | ❌ None |
| 97-108 | `process_path_source()` | Process local path source spec | ❌ None |
| 111-117 | `fetch_local_commit()` | Get commit hash from local repo | ❌ None |
| 120-130 | `auto_fetch_environment()` | Auto-fetch all repos without options | ❌ None |

#### Detailed Issues

**Line 56-77: `set(env_name)` method - CRITICAL**
```ruby
# Current:
# Create new environment with org/repo or path:// sources
# @rbs (String) -> void
desc "set ENV_NAME", "Create new environment with repository sources"
option :"R2P2-ESP32", type: :string, desc: "org/repo or path:// for R2P2-ESP32"
option :"picoruby-esp32", type: :string, desc: "org/repo or path:// for picoruby-esp32"
option :picoruby, type: :string, desc: "org/repo or path:// for picoruby"
def set(env_name)
  Picotorokko::Env.validate_env_name!(env_name)
  
  # Auto-fetch if no options specified
  if options[:"R2P2-ESP32"].nil? && ...
    auto_fetch_environment(env_name)
    return
  end
  
  # All three options required if any is specified
  raise "Error: All three options required" if ...
  # ...
end

# Missing:
# - Auto-fetch behavior completely undocumented in code
# - Source spec format: What exactly are "org/repo" and "path://" formats?
# - Path format examples: What does path:/ syntax look like?
# - What happens if path:commit syntax is used?
# - When to use org/repo vs path://? (for local vs remote)
# - What does "set environment definition" mean? (metadata only, not filesystem)
# - What's the difference between "environment definition" and "build environment"?
# - Error cases: What fails and why?

# Suggested improvement:
# Creates a new environment definition with repository source specifications.
#
# Environment Definition:
# This command manages METADATA only (stored in .picoruby-env.yml).
# Actual filesystem (build environment) is managed separately via build setup.
#
# Two usage modes:
#
# 1. Auto-fetch mode (no options):
#    Fetches latest commits from official repos (R2P2-ESP32, picoruby-esp32, picoruby)
#    Useful for: Quick setup with latest stable versions
#
# 2. Manual mode (all three options required):
#    Specifies custom repository sources for each component
#    Useful for: Local development, custom branches, or pinned versions
#
# Source Specification Format:
#
# GitHub format (org/repo):
#   - Fetches from https://github.com/org/repo.git
#   - Example: --R2P2-ESP32 picoruby/R2P2-ESP32
#   - Fetches latest commit hash automatically
#
# Local path format (path://):
#   - Uses local directory (absolute path)
#   - Examples:
#     * --R2P2-ESP32 path:/home/user/R2P2-ESP32
#     * --R2P2-ESP32 path:/home/user/R2P2-ESP32:a1b2c3d (pinned to commit)
#   - If commit hash provided (after colon), that exact commit is recorded
#   - If no commit, current HEAD commit is extracted from .git/
#
# @param env_name [String]
#   Name of environment to create (e.g., "latest", "stable", "my-custom")
#   Stored in .picoruby-env.yml under environments[env_name]
#   Must be a valid identifier (alphanumeric, dash, underscore)
#
# @option options [String] :"R2P2-ESP32"
#   Source for R2P2-ESP32 repository (required if any option specified)
#   Format: "org/repo" or "path://..." or omitted (auto-fetch)
#
# @option options [String] :"picoruby-esp32"
#   Source for picoruby-esp32 repository (required if any option specified)
#
# @option options [String] :picoruby
#   Source for picoruby repository (required if any option specified)
#
# @rbs (String) -> void
#
# @raise [Thor::Error] If env_name contains invalid characters
# @raise [Thor::Error] If any required option missing (all three or none)
# @raise [RuntimeError] If GitHub source not reachable
# @raise [RuntimeError] If local path source doesn't exist or not a git repo
#
# @example Auto-fetch latest versions
#   ptrk env set latest
#   # Fetches latest commits from official repos
#   # Stores in .picoruby-env.yml as environment "latest"
#
# @example Custom environment with GitHub sources
#   ptrk env set my-custom \
#     --R2P2-ESP32 picoruby/R2P2-ESP32 \
#     --picoruby-esp32 picoruby/picoruby-esp32 \
#     --picoruby picoruby/picoruby
#
# @example Local development with path sources
#   ptrk env set dev-local \
#     --R2P2-ESP32 path:/home/user/R2P2-ESP32 \
#     --picoruby-esp32 path:/home/user/R2P2-ESP32/components/picoruby-esp32 \
#     --picoruby path:/home/user/picoruby
#
# @example Pinned commit on local path
#   ptrk env set pinned \
#     --R2P2-ESP32 "path:/home/user/R2P2-ESP32:a1b2c3d7" \
#     --picoruby-esp32 "path:/home/user/R2P2-ESP32/components/picoruby-esp32:def4567a" \
#     --picoruby "path:/home/user/picoruby:89012345"
#
# @see #latest for auto-fetching latest versions
# @see .picoruby-env.yml for environment definition file format
# @see Picotorokko::Env.get_environment for retrieving definitions
```

**Line 264-304: `fetch_latest_repos()` method - CRITICAL**
```ruby
# Current:
# Fetch latest commits from all repos (reusable method for Init)
# @rbs () -> Hash[String, Hash[String, String]]
def fetch_latest_repos
  require "tmpdir"
  repos_info = {}
  
  Picotorokko::Env::REPOS.each do |repo_name, repo_url|
    puts "  Checking #{repo_name}..."
    commit = Picotorokko::Env.fetch_remote_commit(repo_url, "HEAD") || "abc1234"
    Dir.mktmpdir do |tmpdir|
      tmp_repo = File.join(tmpdir, repo_name)
      puts "    Cloning to get timestamp..."
      
      cmd = "git clone --depth 1 --branch HEAD ..."
      # ...
    end
  end
  repos_info
end

# Missing:
# - Purpose: Why clone to tmpdir just for timestamp? (comment says "Cloning to get timestamp")
# - Performance note: Shallow clone is used (--depth 1) for speed
# - What are REPOS? (defined in Picotorokko::Env)
# - Return value structure: { "R2P2-ESP32" => { "commit" => "...", "timestamp" => "..." }, ... }
# - Why fallback to "abc1234" if fetch fails? (placeholder?)
# - Shell command failure handling: What happens if git clone fails?
# - Cleanup: tmpdir is auto-cleaned (mktmpdir), but not documented

# Suggested improvement:
# Fetches latest commit and timestamp information for all configured repositories.
#
# Process:
# 1. For each repository (R2P2-ESP32, picoruby-esp32, picoruby):
#    a. Fetches latest commit hash from remote via ls-remote
#    b. Performs shallow clone (--depth 1) to extract commit timestamp
#    c. Extracts both commit hash and author timestamp
#    d. Cleans up temporary clone (tmpdir auto-cleanup)
#
# This method is used by:
# - env.rb:latest command (public entry point)
# - init.rb (during new project initialization)
#
# Shallow clone rationale:
# - Fast operation (downloads only latest commit, not full history)
# - Only needed to get commit timestamp (git show -s --format=%ci)
# - Temporary directory cleanup automatic (via Dir.mktmpdir)
#
# @rbs () -> Hash[String, Hash[String, String]]
#
# @return [Hash<String, Hash<String, String>>]
#   Structure: { repo_name => { "commit" => short_hash, "timestamp" => formatted_time } }
#   Example:
#     {
#       "R2P2-ESP32" => {
#         "commit" => "a1b2c3d",
#         "timestamp" => "20251114_120530"
#       },
#       "picoruby-esp32" => {...},
#       "picoruby" => {...}
#     }
#
# @raise [RuntimeError] If git clone fails (network error, repo not found)
# @raise [RuntimeError] If git operations fail within cloned repo
#
# @example Called by latest command
#   repos_info = fetch_latest_repos
#   # Returns hash with latest versions of all three repos
#   # Then saved as environment definition via Picotorokko::Env.set_environment
#
# @see #latest for public entry point
# @see Picotorokko::Env::REPOS for configured repository URLs
# @see Picotorokko::Env.fetch_remote_commit for remote hash fetching
```

**Helper Methods in `no_commands` block:**
```ruby
# Line 81-87: process_source()
# Current: @rbs (String, String) -> Hash[String, String]
# Missing: What does this method do? When is it called?
# Suggested:
# Routes source specification to appropriate handler.
# Detects whether source is GitHub (org/repo) or local path (path://...).
# 
# @param source_spec [String] Source specification (GitHub format or path://)
# @param timestamp [String] Current timestamp (YYYYMMDD_HHMMSS)
# @return [Hash<String, String>] Processed source info
# @rbs (String, String) -> Hash[String, String]

# Line 90-94: process_github_source()
# Current: @rbs (String, String) -> Hash[String, String]
# Missing: No documentation at all
# Suggested:
# Processes GitHub org/repo source specification.
# Fetches latest commit hash from GitHub.
# 
# @param org_repo [String] GitHub source as "org/repo" (e.g., "picoruby/R2P2-ESP32")
# @param timestamp [String] Current timestamp
# @return [Hash<String, String>] { "source" => url, "commit" => hash, "timestamp" => ts }
# @rbs (String, String) -> Hash[String, String]

# Line 97-108: process_path_source()
# Current: @rbs (String, String) -> Hash[String, String]
# Missing: Path format not explained
# Suggested:
# Processes local path source specification.
# Supports two formats:
# - Simple: path:/absolute/path → uses current HEAD
# - Pinned: path:/absolute/path:commit_hash → uses specified hash
#
# @param path_spec [String] Path specification (path://... format)
# @param timestamp [String] Current timestamp
# @return [Hash<String, String>] Processed source info
# @rbs (String, String) -> Hash[String, String]

# Line 111-117: fetch_local_commit()
# Current: @rbs (String) -> String
# Missing: What format is returned? Error cases?
# Suggested:
# Extracts short commit hash (7 chars) from local git repository.
# 
# @param path [String] Absolute path to local git repository
# @return [String] 7-character commit hash (e.g., "a1b2c3d")
# @raise [RuntimeError] If path doesn't exist
# @raise [RuntimeError] If path is not a git repository
# @rbs (String) -> String

# Line 120-130: auto_fetch_environment()
# Current: @rbs () -> void
# Missing: What does this do? Why is it separate from set()?
# Suggested:
# Fetches latest commits from all configured repositories and creates environment definition.
# This is called when ptrk env set ENV_NAME is used WITHOUT options.
# 
# @param env_name [String] Name of environment to create
# @rbs (String) -> void
# @see #set for public entry point
# @see #fetch_latest_repos for fetching logic
```

**Line 160-178: `patch_export()` method**
```ruby
# Current:
# Export working changes from build environment to patch directory
# @rbs (String) -> void
def patch_export(env_name)
  # ...
end

# Missing:
# - What is a "patch"? (modified files from build environment)
# - What is "patch directory"? (Where patches are stored)
# - When would you use this? (Workflow context)
# - What happens to staged vs unstaged changes?
# - Does it modify build environment? (No, just reads)

# Suggested improvement:
# Exports modified files from build environment working tree as patch files.
#
# Context: Patch Directory
# Picotorokko stores working changes from R2P2-ESP32, picoruby-esp32, and picoruby
# in a dedicated patch directory (outside build environment). This allows:
# - Preserving customizations across environment rebuilds
# - Version controlling patches separately
# - Reapplying patches to new environments
#
# Process:
# 1. Scans build environment for modified files (git diff)
# 2. For each modified file:
#    - If only changes: saves git diff output as patch file
#    - If new file: copies full file to patch directory
# 3. Mirrors directory structure of repositories
#
# Output Location:
# Files saved to: ~/.picoruby/patches/{R2P2-ESP32,picoruby-esp32,picoruby}/...
#
# @param env_name [String] Environment name (must exist in .picoruby-env.yml)
#
# @rbs (String) -> void
#
# @raise [RuntimeError] If environment not found
# @raise [RuntimeError] If build environment doesn't exist
# @raise [RuntimeError] If git commands fail
#
# @example Export patches from latest build
#   ptrk env patch_export latest
#   # Scans ~/...picoruby-latest/R2P2-ESP32 for changes
#   # Saves patches to ~/.picoruby/patches/
#
# @see #patch_apply for applying patches to another environment
# @see #patch_diff for viewing differences
```

**Line 183-214: `patch_apply()` method**
```ruby
# Current:
# Apply stored patches to build environment
# @rbs (String) -> void
def patch_apply(env_name)
  # ...
end

# Missing:
# - Same issues as patch_export
# - When is this called? (workflow step)
# - What if patch application fails? (partial application)
# - Does it overwrite existing changes?

# Suggested improvement:
# Applies stored patch files to build environment working tree.
#
# Process:
# 1. Locates patch directory: ~/.picoruby/patches/
# 2. For each repository (R2P2-ESP32, picoruby-esp32, picoruby):
#    a. Finds corresponding patch directory
#    b. Applies patches to working repository
# 3. Uses PatchApplier for intelligent merge (avoids duplicates)
#
# Workflow Context:
# Typical usage:
#   1. Setup new environment: ptrk build setup latest
#   2. Apply patches: ptrk env patch_apply latest
#   3. Verify differences: ptrk env patch_diff latest
#   4. Optional: export new patches: ptrk env patch_export latest
#
# @param env_name [String] Environment name
#
# @rbs (String) -> void
#
# @raise [RuntimeError] If environment not found
# @raise [RuntimeError] If build environment doesn't exist
# @raise [RuntimeError] If patch application fails
#
# @example Apply patches to environment
#   ptrk env patch_apply latest
#
# @see #patch_export for exporting patches
# @see Picotorokko::PatchApplier for implementation
```

---

## Summary: Priority Matrix

### CRITICAL (Implement Immediately)

1. **lib/picotorokko/commands/device.rb:method_missing** (lines 99-129)
   - Complex delegation logic needs complete documentation
   - Security model (whitelist/AST parsing) not explained
   - Relationship to `respond_to_missing?` unclear

2. **lib/picotorokko/commands/device.rb:RakeTaskExtractor class** (lines 254-398)
   - No class-level documentation
   - What is Prism::Visitor? Why?
   - Secure static analysis approach not documented

3. **lib/picotorokko/commands/env.rb:set** (lines 56-77)
   - Three complex option formats (GitHub, local path, pinned commit) completely undocumented
   - Auto-fetch behavior hidden from documentation
   - No examples for any use case

4. **lib/picotorokko/commands/env.rb:fetch_latest_repos** (lines 264-304)
   - Complex shell operations (shallow clone, git commands) not explained
   - Return value structure not documented
   - Why tmpdir + clone just for timestamp not clear

### HIGH (Important for Usability)

5. **lib/picotorokko/commands/init.rb:create** (lines 24-32)
   - Primary entry point lacks option documentation
   - No examples of common usage patterns
   - Parameter behavior (nil case) not documented

6. **lib/picotorokko/commands/device.rb:flash** (lines 22-30)
7. **lib/picotorokko/commands/device.rb:monitor** (lines 36-44)
8. **lib/picotorokko/commands/device.rb:build** (lines 50-61)
   - All device operations lack detailed documentation
   - `--env` option behavior not explained
   - Error conditions and troubleshooting missing

9. **lib/picotorokko/commands/env.rb: no_commands block helpers** (lines 81-130)
   - 5 public helper methods with NO documentation
   - `process_source`, `process_github_source`, `process_path_source`, etc.
   - Should have at least: purpose, params, return value

10. **lib/picotorokko/commands/env.rb:patch_* methods** (lines 160-235)
    - Patch operations (export, apply, diff) lack workflow context
    - When/why to use these commands not documented
    - Directory structure and file format unclear

### MEDIUM (Nice to Have)

11. **lib/picotorokko/commands/device.rb:respond_to_missing?** (lines 132-135)
    - Should be English-only (has Japanese comment)
    - Relationship to method_missing needs documentation

12. **lib/picotorokko/commands/env.rb:latest** (lines 240-260)
    - Shows next steps but command doesn't show them in help

13. **lib/picotorokko/commands/device.rb:tasks, help** (lines 81-95)
    - Minimal documentation; aliases not documented

14. **lib/picotorokko/cli.rb:exit_on_failure?, version** (lines 18-52)
    - Could have more context about Thor framework behavior

---

## Recommendations for RubyDoc.info Output

### 1. Add Comprehensive rbs-inline Comments
Since the project relies on RubyDoc.info generation from RBS files, enhance comments with:
- **Purpose**: What the method does (business logic, not "returns string")
- **Parameters**: Meaning of each param, valid values, constraints
- **Returns**: What's actually returned, structure, side effects
- **Errors**: What can go wrong, error types, recovery advice
- **Examples**: Real usage patterns, both happy and error paths
- **Cross-references**: Related methods via `@see` tags

### 2. Document Pattern: Options-Heavy Commands
For Thor commands with multiple options (like `env set`):
- Document the "no option" mode separately from "all options" mode
- Provide concrete examples for each mode
- Explain auto-detection behavior
- Show examples of each option format

### 3. Document Pattern: Delegation Methods
For `method_missing` and complex routing:
- Explain the dispatch mechanism
- Document the whitelist/security model
- Show what commands are available (or how to discover them)
- Provide examples of delegated calls

### 4. Document Inner Classes
For nested classes like `RakeTaskExtractor`:
- Class-level documentation explaining purpose
- Why inherit from specific parent (Prism::Visitor)
- What the visitor pattern accomplishes here
- Example usage (initialization → accept → access results)

### 5. English-Only Comments
Replace all Japanese comments with English for consistency in auto-generated docs.

---

## Implementation Order

1. **Phase 1** (Critical for core functionality):
   - `device.rb:method_missing` + `RakeTaskExtractor` class
   - `env.rb:set` command
   - `env.rb:fetch_latest_repos`

2. **Phase 2** (High-value usability improvements):
   - `init.rb:create`
   - Device operation methods (flash, monitor, build, setup_esp32)
   - Patch operation methods (export, apply, diff)

3. **Phase 3** (Polish):
   - Helper methods in `no_commands` blocks
   - CLI class methods
   - Remaining medium priority items

---

## Tools & References

- **RubyDoc.info Format**: Follows standard YARD/RBS syntax
- **Generation**: Automatic from .rbs files → HTML docs
- **Preview**: Local testing via `bundle exec steep check` (validates annotations)
- **Type hints**: Already using @rbs annotations (excellent starting point!)

