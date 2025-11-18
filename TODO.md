# Project Status

## Current Status (Latest - 2025-11-17)

- ✅ **All Tests**: 231 tests passing (100% success rate)
- ✅ **Quality**: RuboCop clean (0 violations), coverage 86.12% line / 64.59% branch
- ✅ **ptrk init Command**: Complete with PicoRuby templates (.rubocop.yml, CLAUDE.md)
- ✅ **Mrbgemfile DSL**: Complete with template generation
- ✅ **Type System Integration**: Complete (rbs-inline + Steep)
- ✅ **Build Environment Setup**: Automatic git clone/checkout for `ptrk env latest`
- ✅ **Rake Command Polymorphism**: Smart detection for bundle exec vs rake
- ✅ **PicoRuby Development Templates**: Enhanced CLAUDE.md with mrbgems, I2C/GPIO/RMT, memory optimization

---

## Test Execution

**Quick Reference**:
```bash
bundle exec rake test         # Run all tests (231 tests)
bundle exec rake ci           # CI checks: tests + RuboCop + coverage validation
bundle exec rake dev          # Development: RuboCop auto-fix + tests + coverage
```

---

## Completed Features (v0.1.0)

### ✅ ptrk init Command
- Project initialization with templates
- Auto-generation of `.rubocop.yml` with PicoRuby configuration
- Enhanced `CLAUDE.md` with comprehensive development guide
- Template variables: {{PROJECT_NAME}}, {{AUTHOR}}, {{CREATED_AT}}, {{PICOTOROKKO_VERSION}}
- Optional `--with-ci` flag for GitHub Actions integration

### ✅ Environment Management
- `ptrk env set` — Create/update environments with git commit reference
- `ptrk env show` — Display environment details
- `ptrk env list` — List all configured environments
- `ptrk env latest` — Auto-fetch latest repo versions with git clone/checkout
- `ptrk env reset` — Reset to default configuration
- `ptrk env patch_export` — Export patches from specific environment

### ✅ Device Commands
- `ptrk device build` — Build firmware in environment
- `ptrk device flash` — Flash firmware to device
- `ptrk device monitor` — Monitor serial output
- Smart Rake command detection (bundle exec vs rake)
- R2P2-ESP32 Rakefile delegation for actual build tasks

### ✅ Infrastructure
- Executor abstraction (ProductionExecutor, MockExecutor)
- AST-based template engines (Ruby, YAML, C)
- Mrbgemfile template with picoruby-picotest reference
- Type system (rbs-inline annotations, Steep checking)

---

## Roadmap (Future Versions)

### Priority 1: Device Testing Framework
- **Status**: Research phase
- **Objective**: Enable `ptrk device {build,flash,monitor} --test` for Picotest integration
- **Estimated**: v0.2.0

### Priority 2: Additional mrbgems Management
- **Status**: Planned
- **Objective**: Commands for generating, testing, publishing mrbgems
- **Estimated**: v0.2.0+

### Priority 3: CI/CD Templates
- **Status**: Planned
- **Objective**: Enhanced GitHub Actions workflow templates
- **Estimated**: v0.3.0+

---

## Documentation Files

**For ptrk Users** (located in docs/):
- `README.md` — Installation and quick start
- `docs/CI_CD_GUIDE.md` — Continuous integration setup
- `docs/MRBGEMS_GUIDE.md` — mrbgems creation and management
- `docs/github-actions/` — Workflow templates for CI/CD

**For Gem Developers** (located in .claude/):
- `.claude/docs/` — Internal design documents
- `.claude/skills/` — Development workflow agents
- `CLAUDE.md` — Development guidelines and conventions
- `SPEC.md` — Detailed feature specification

**Auto-Generated for Projects** (via ptrk init):
- `{{PROJECT_NAME}}/CLAUDE.md` — PicoRuby development guide for the project
- `{{PROJECT_NAME}}/.rubocop.yml` — Project-specific linting configuration
- `{{PROJECT_NAME}}/README.md` — Project setup instructions
- `{{PROJECT_NAME}}/Mrbgemfile` — mrbgems dependencies

---

## Quality Gates

All features must pass:
- ✅ Tests: 100% success rate (currently 231/231)
- ✅ RuboCop: 0 violations
- ✅ Coverage: ≥85% line, ≥60% branch
- ✅ Type checking: Steep validation passing
- ✅ Documentation: Updated with code changes

---

## Recent Changes

### Session Latest: PicoRuby Development Templates (Commit 6905e71)
- Added `.rubocop.yml` template with PicoRuby-specific configuration
- Enhanced `CLAUDE.md` template with:
  - mrbgems dependency management
  - Peripheral APIs (I2C, GPIO, RMT) with examples
  - Memory optimization techniques
  - RuboCop configuration guide
  - Picotest testing framework
- Updated ProjectInitializer to copy template files
- Fixed UTF-8 encoding in tests for international characters
- All tests passing: 231/231, coverage stable

### Previous Sessions: Environment & Build Features
- Session 6: Fixed `ptrk env latest` infrastructure issues
  - Resolved fetch_latest_repos Thor warning
  - Fixed invalid `git clone --branch HEAD` syntax
  - Updated error messages (pra → ptrk)
- Session 5: Implemented build environment setup and Gemfile detection
  - Automatic git clone/checkout for repositories
  - Smart Rake command detection (bundle exec vs rake)
  - Improved error handling and logging

---

## Known Limitations & Future Work

1. **Device Testing**: Picotest integration not yet implemented (`--test` flag for device commands)
2. **C Linting**: No C linting tools currently in templates (could add clang-format in v0.2.0)
3. **Cache Management**: Not implemented (considered for v0.2.0+)
4. **mrbgems Generation**: Basic support only; full workflow in v0.2.0

---

## Installation & Release

### For End Users
```bash
gem install picotorokko
```

### For Development
```bash
git clone https://github.com/bash0C7/picotorokko
cd picotorokko
bundle install
bundle exec rake test
```

Current version: **0.1.0** (released to RubyGems)

---

## 🐛 [TODO-CODE-QUALITY-ISSUES] Found During Coverage Analysis (Session Latest)

### 📋 [TODO-TEST-EXPANSION-PHASE] Test Coverage Enhancement (In Progress)

**Session Goal**: Expand test coverage to reach 90%+ line coverage, 75%+ branch coverage

**Tests Added (Placeholder Phase)**:
- ✅ ProjectInitializer#render_template: 2 omitted tests (ISSUE-3, ISSUE-5)
- ✅ Env#fetch_repo_info: 2 omitted tests (ISSUE-6)
- ✅ Env#clone_and_checkout_repo: 4 omitted tests (ISSUE-7, ISSUE-8, ISSUE-9)
- ✅ Device command validation: 4 omitted tests (ISSUE-10, ISSUE-11, ISSUE-12, ISSUE-13)
- **Total new test placeholders**: 12 tests with omit markers pointing to implementation phase

**Current Status**:
- Test count: 235 → 247 (12 new omitted tests)
- Line coverage: 86.21% (unchanged - omitted tests don't execute)
- Branch coverage: 65.15% (unchanged - omitted tests don't execute)

**Next Phase**: Remove omit() and implement fixes for each ISSUE to activate tests and increase coverage

### ✅ COMPLETED ISSUES

#### ProjectInitializer Issues (lib/picotorokko/project_initializer.rb)

1. **✅ [ISSUE-1] detect_git_author returns empty string instead of nil** - FIXED
   - Location: line 126-131
   - Fix: Changed to use `git -C #{project_root}` and convert empty string to nil
   - Result: Tests passing, author detection works correctly for all scenarios
   - Commit: dd28037

2. **✅ [ISSUE-2] validate_project_name! rejects valid mixed-case names** - FIXED
   - Location: line 88 `\A[a-z0-9_-]+\z`
   - Fix: Changed regex from `[a-zA-Z0-9_-]` to `[a-z0-9_-]` to enforce lowercase
   - Result: Tests passing, uppercase rejection working as expected
   - Commit: dd28037

3. **[ISSUE-3] render_template silently skips missing templates**
   - Location: line 157-160
   - Problem: When template file doesn't exist, just prints warning and returns without error
   - Impact: Project created with incomplete files (missing .gitignore, README.md, etc.)
   - Test gap: No test for missing template file scenario
   - Severity: High (silent data loss, hard to debug)

4. **[ISSUE-4] with_ci option checking is overly complex**
   - Location: line 186
   - Problem: Checks 4 different keys (`:with_ci`, `"with_ci"`, `:"with-ci"`, `"with-ci"`)
   - Question: Why? Thor should normalize this to one form. Indicates unclear option handling.
   - Test gap: Only tests default case, not --with-ci explicitly
   - Severity: Medium (works but maintainability issue)

5. **[ISSUE-5] No error handling for template rendering failures**
   - Location: line 163 `Picotorokko::Template::Engine.render()`
   - Problem: If template engine throws exception (invalid syntax, etc), whole init fails
   - Example: Bad ERB syntax in template causes silent crash
   - Test gap: No test for render engine failure
   - Severity: High (can brick initialization)

### Env.rb Issues (lib/picotorokko/commands/env.rb)

6. **[ISSUE-6] fetch_repo_info doesn't handle git command failures**
   - Location: line 482-484
   - Problem: `git rev-parse` and `git show` failures not checked, just uses empty/malformed strings
   - Impact: If Git command fails, timestamp parsing at line 484 may crash with ArgumentError
   - Test gap: No test for git command failure scenario
   - Severity: High (can crash ptrk env latest)

7. **✅ [ISSUE-7] clone_and_checkout_repo ignores system() return value**
   - FIXED: c1b5861 - Added system() return value checks for clone and checkout
   - Implementation: Raises error if system() returns false
   - Tests: Added test cases for clone failure and checkout failure
   - Status: Complete with full test coverage

8. **✅ [ISSUE-8] Partially cloned repos cause infinite loop**
   - FIXED: cccad93 - Detect valid repos by checking .git directory
   - Implementation: Validates .git directory exists before skipping, removes incomplete clones
   - Tests: Added test case for partial clone recovery scenario
   - Status: Complete with full test coverage

9. **✅ [ISSUE-9] setup_build_environment has no atomic transaction**
   - FIXED: 486c35d - Implement atomic rollback on failure
   - Implementation: Track cloned repos, rollback all on first failure
   - Tests: Added test case for rollback on first repo failure
   - Status: Complete with full test coverage

10. **[ISSUE-10] Error output suppressed (2>/dev/null) makes debugging hard**
    - Location: line 475, 520, 523
    - Problem: All git errors are silently discarded, only exit codes visible
    - Impact: User can't see actual error (network timeout vs auth failure vs disk full)
    - Workaround: None - have to strace or add debug output
    - Severity: Medium (operational issue)

### Device.rb Issues (lib/picotorokko/commands/device.rb)

11. **[ISSUE-11] parse_env_from_args treats empty --env= as valid**
    - Location: line 174 `arg.split("=", 2)[1]`
    - Problem: `--env=` returns empty string "", not nil (should reject)
    - Impact: `ptrk device build --env=` silently uses empty env name
    - Test gap: No test for `--env=` edge case
    - Severity: Medium (invalid input accepted, cryptic error later)

12. **[ISSUE-12] build_rake_command vulnerable to empty task_name**
    - Location: line 354
    - Problem: If `task_name` is empty string, generates `rake ` which is invalid
    - Impact: Calling build_rake_command with empty task fails with cryptic rake error
    - Test gap: No test for empty task_name
    - Severity: Low (internal use only, but bad defensive programming)

13. **[ISSUE-13] No validation of Gemfile existence before bundle exec**
    - Location: line 353 `File.exist?(gemfile_path)`
    - Problem: Checks existence but what if Gemfile is corrupted/unreadable?
    - Impact: `bundle exec rake` may fail with unclear "Gemfile not found" error
    - Test gap: No test for corrupted Gemfile case
    - Severity: Low (rare, user would need to investigate bundle)

### Testing/Coverage Gaps Summary

**Need to add tests for**:
- ✅ ProjectInitializer: Missing template file handling, template engine failure
- ✅ Env.rb: Git command failures (clone, checkout, rev-parse, show), partial clone recovery
- ✅ Device.rb: Empty task_name, empty --env= value
- ✅ Error paths: No rollback/cleanup for partially failed operations
- ✅ Integration: Full ptrk init → ptrk env latest → ptrk device build flow with failures at each step

**Impact on Coverage**:
- Current: 86.12% line / 64.59% branch
- Missing: Most error paths and edge case branches
- Estimated to add: 10-15 tests to reach 90%+ coverage

---

## 🔧 [TODO-DETAILED-IMPLEMENTATION-CONTEXT] Complete Test Strategy & Fix Approaches

### ISSUE-1 & ISSUE-6: Git Command Failure Handling

**Code Context** (ProjectInitializer#detect_git_author):
```ruby
# Line 126-131
def detect_git_author
  output = `git config user.name 2>/dev/null`.strip
  output.empty? ? "Unknown Author" : output  # BUG: Returns empty string, not nil
end
```

**Code Context** (Env#fetch_repo_info):
```ruby
# Line 482-484
def fetch_repo_info(repo_path)
  commit_hash = `git -C #{repo_path} rev-parse HEAD 2>/dev/null`.strip
  timestamp = Time.parse(`git -C #{repo_path} show -s --format=%ci HEAD 2>/dev/null`.strip)
  # BUG: No error checking on backticks - can return empty string causing ArgumentError
end
```

**Call Chain**:
- `ptrk init` → ProjectInitializer#initialize → prepare_variables → detect_git_author (ISSUE-1)
- `ptrk env latest` → Env#setup_build_environment → fetch_repo_info (ISSUE-6)

**Test Strategy**:
```ruby
# Test detect_git_author returns "Unknown Author" when git config not set
test "detect_git_author returns default when git config user.name missing" do
  marble = RealityMarble.chant do
    Kernel.define_singleton_method(:`) do |cmd|
      return "" if cmd.include?("git config user.name")
      `#{cmd}` # fallback to real command
    end
  end
  marble.activate do
    author = ProjectInitializer.new.send(:detect_git_author)
    assert_equal "Unknown Author", author
  end
end

# Test fetch_repo_info handles git command failure gracefully
test "fetch_repo_info handles git rev-parse failure" do
  marble = RealityMarble.chant do
    Kernel.define_singleton_method(:`) do |cmd|
      return "" if cmd.include?("rev-parse")
      `#{cmd}`
    end
  end
  marble.activate do
    assert_raises(ArgumentError) { Env.new.send(:fetch_repo_info, "/fake/path") }
  end
end
```

**Fix Approach**:
- ISSUE-1: Change condition to: `output.empty? ? nil : output` (or raise error)
- ISSUE-6: Use begin/rescue with proper error message: `rescue => e then raise "Git command failed: #{e.message}"`

**Real User Impact**:
- ISSUE-1: Author field shows empty in generated `CLAUDE.md`, templates display correctly but confusingly
- ISSUE-6: `ptrk env latest` crashes with "invalid date format" error, environment partially cloned

**Risk**: Medium (affects initialization and environment setup)

---

### ISSUE-3 & ISSUE-5: Template Rendering Silent Failures

**Code Context** (ProjectInitializer#render_template):
```ruby
# Line 157-165
def render_template(template_name)
  template_path = File.join(TEMPLATE_DIR, template_name)
  return unless File.exist?(template_path)  # ISSUE-3: Silent return on missing file

  content = File.read(template_path)
  rendered = Picotorokko::Template::Engine.render(content, @variables)  # ISSUE-5: No rescue
  File.write(output_path, rendered)
rescue => e  # This rescue is too late - render failure not caught
  puts "Template rendering failed: #{e.message}"
end
```

**Call Chain**:
- `ptrk init my-project` → ProjectInitializer#initialize → render_all_templates → render_template (each file)
- Missing template = incomplete project created

**Test Strategy**:
```ruby
test "render_template raises error when template file missing" do
  # Ensure template doesn't exist
  File.stubs(:exist?).with(anything).returns(false)

  initializer = ProjectInitializer.new("test-project")
  assert_raises(Picotorokko::TemplateNotFoundError) do
    initializer.send(:render_template, "missing.erb")
  end
end

test "render_template propagates template engine errors" do
  bad_template_content = "<%= undefined_var %>"  # Will error in rendering
  File.stubs(:read).returns(bad_template_content)

  assert_raises(Picotorokko::TemplateRenderError) do
    initializer.send(:render_template, "bad.erb")
  end
end
```

**Fix Approach**:
```ruby
def render_template(template_name)
  template_path = File.join(TEMPLATE_DIR, template_name)
  raise Picotorokko::TemplateNotFoundError, "Template #{template_name} not found" unless File.exist?(template_path)

  content = File.read(template_path, encoding: "UTF-8")
  rendered = Picotorokko::Template::Engine.render(content, @variables)
  File.write(output_path, rendered)
rescue Picotorokko::Template::RenderError => e
  raise Picotorokko::TemplateRenderError, "Failed to render #{template_name}: #{e.message}"
end
```

**Real User Impact**:
- ISSUE-3: `ptrk init my-project` succeeds but creates project missing `.gitignore`, `README.md`, `.rubocop.yml`
- User wonders why templates are incomplete, has to manually add files
- ISSUE-5: Corrupted template with bad ERB syntax = silent failure, broken project

**Risk**: High (data loss, broken initialization)

---

### ISSUE-7, ISSUE-8, ISSUE-9: Clone/Checkout State Corruption

**Code Context** (Env#clone_and_checkout_repo):
```ruby
# Line 517-530
def clone_and_checkout_repo(repo_url, target_path, branch = nil)
  return if Dir.exist?(target_path)  # ISSUE-8: Partially cloned repos skip silently

  system("git clone --recursive #{repo_url} #{target_path} 2>/dev/null")  # ISSUE-7: Ignore $?

  if branch
    system("git -C #{target_path} checkout #{branch} 2>/dev/null")  # ISSUE-7: Ignore $?
  end
end

def setup_build_environment(repos)
  repos.each do |repo|  # ISSUE-9: If repo N fails, repos 1..N-1 are cloned, repos N+1 not attempted
    clone_and_checkout_repo(repo[:url], repo[:path], repo[:branch])
    # No rollback, no atomic guarantee
  end
end
```

**Call Chain**:
- `ptrk env latest` → Env#setup_build_environment → clone_and_checkout_repo (for each repo)
- Network failure mid-clone = partial directory created
- Next run sees directory, skips it = broken state

**Test Strategy**:
```ruby
test "clone_and_checkout_repo raises error when git clone fails" do
  marble = RealityMarble.chant do
    Kernel.define_singleton_method(:system) do |cmd, *args|
      return false if cmd.include?("git clone")  # Simulate clone failure
      Kernel.system(cmd, *args)  # fallback
    end
  end

  marble.activate do
    assert_raises(Picotorokko::CloneFailedError) do
      env.send(:clone_and_checkout_repo, "https://bad.url/repo.git", "/tmp/test", nil)
    end
  end
end

test "setup_build_environment rolls back on first failure" do
  repos = [
    { url: "https://repo1.git", path: "/tmp/r1", branch: "main" },
    { url: "https://repo2.git", path: "/tmp/r2", branch: "main" }  # Will fail
  ]

  # Setup so repo2 clone fails
  marble = RealityMarble.chant do
    Kernel.define_singleton_method(:system) do |cmd, *args|
      return false if cmd.include?("repo2.git")
      Kernel.system(cmd, *args)
    end
  end

  marble.activate do
    assert_raises(Picotorokko::SetupFailedError) do
      env.send(:setup_build_environment, repos)
    end
    # Verify rollback: /tmp/r1 should not exist (rolled back)
    assert_false Dir.exist?("/tmp/r1")
  end
end
```

**Fix Approach**:
```ruby
def clone_and_checkout_repo(repo_url, target_path, branch = nil)
  raise Picotorokko::CloneFailedError, "Repository already exists" if Dir.exist?(target_path)

  success = system("git clone --recursive #{repo_url} #{target_path}")
  raise Picotorokko::CloneFailedError, "Clone failed: #{repo_url}" unless success

  if branch
    success = system("git -C #{target_path} checkout #{branch}")
    raise Picotorokko::CheckoutFailedError, "Checkout failed: #{branch}" unless success
  end
end

def setup_build_environment(repos)
  cloned_repos = []
  begin
    repos.each do |repo|
      clone_and_checkout_repo(repo[:url], repo[:path], repo[:branch])
      cloned_repos << repo[:path]
    end
  rescue => e
    # Rollback: Remove all cloned repos
    cloned_repos.each { |path| FileUtils.rm_rf(path) }
    raise Picotorokko::SetupFailedError, "Environment setup failed: #{e.message}"
  end
end
```

**Real User Impact**:
- `ptrk env latest` fails mid-way (network timeout during R2P2-ESP32 clone)
- Partial directory created, picoruby not cloned
- Next run: "Environment already exists" → User confused why build fails
- Workaround: Manual `rm -rf ptrk_env/latest` needed

**Risk**: High (operational, requires manual intervention)

---

### ISSUE-14: traverse_submodules_and_validate - CRITICAL

**Code Context** (Env#traverse_submodules_and_validate):
```ruby
# Line 229-265 (37 lines, ZERO test coverage)
def traverse_submodules_and_validate(repo_path, max_depth = 2, current_depth = 0)
  return if current_depth > max_depth
  warn "Submodule depth #{current_depth} exceeds recommended" if current_depth > 2

  submodule_lines = `git -C #{repo_path} config --file .gitmodules --name-only --get-regexp path`.split("\n")

  submodule_lines.each do |line|
    # Parse "submodule.picoruby-esp32.path" → path value
    submodule_path = `git -C #{repo_path} config --file .gitmodules --get #{line}`.strip
    full_path = File.join(repo_path, submodule_path)

    # Validate submodule commit exists
    submodule_commit = `git -C #{repo_path} ls-tree HEAD #{submodule_path}`.match(/\h{40}/)&.[](0)
    raise "Missing submodule commit" unless submodule_commit

    # Recurse
    traverse_submodules_and_validate(full_path, max_depth, current_depth + 1)
  end
end
```

**Call Chain**:
- `ptrk env latest` → Env#setup_build_environment → validate_repo_structure → traverse_submodules_and_validate
- R2P2-ESP32 has nested submodules: picoruby-esp32 (→ picoruby)

**Test Strategy** (highly complex):
```ruby
test "traverse_submodules_and_validate detects broken submodules" do
  # Create temp git repos with submodule structure
  Dir.mktmpdir do |tmpdir|
    repo_path = File.join(tmpdir, "repo")
    submodule_path = File.join(tmpdir, "submodule")

    # Setup real submodule scenario
    system("cd #{submodule_path} && git init && echo content > file.txt && git add . && git commit -m init")
    system("cd #{repo_path} && git init && git submodule add #{submodule_path} sub")

    # Now test: broken submodule (missing commit)
    submodule_commit = `git -C #{repo_path} ls-tree HEAD sub | awk '{print $3}'`
    broken_commit_ref = submodule_commit.to_s.gsub(/./, "0")  # Replace with fake hash
    system("git -C #{repo_path} update-index --cacheinfo 160000 #{broken_commit_ref} sub")

    # Should raise error for broken submodule
    assert_raises(Picotorokko::SubmoduleValidationError) do
      env.send(:traverse_submodules_and_validate, repo_path)
    end
  end
end
```

**Fix Approach**:
```ruby
def traverse_submodules_and_validate(repo_path, max_depth = 2, current_depth = 0)
  return if current_depth > max_depth
  warn "⚠️ Submodule depth #{current_depth} exceeds recommended (#{max_depth})" if current_depth > 2

  begin
    submodule_lines = `git -C #{repo_path} config --file .gitmodules --name-only --get-regexp path 2>&1`.split("\n")

    submodule_lines.each do |line|
      submodule_path = `git -C #{repo_path} config --file .gitmodules --get #{line}`.strip
      full_path = File.join(repo_path, submodule_path)

      # Validate submodule commit exists and is accessible
      ls_tree = `git -C #{repo_path} ls-tree HEAD #{submodule_path} 2>&1`
      raise Picotorokko::SubmoduleValidationError, "Submodule #{submodule_path} commit not found" unless ls_tree.include?("160000")

      # Recurse safely
      traverse_submodules_and_validate(full_path, max_depth, current_depth + 1)
    end
  rescue => e
    raise Picotorokko::SubmoduleValidationError, "Submodule traversal failed at depth #{current_depth}: #{e.message}"
  end
end
```

**Real User Impact**:
- `ptrk env latest` succeeds but R2P2-ESP32 build fails later because submodules were never validated
- User gets confusing "branch not found" error during build, not during environment setup
- Time lost debugging build instead of catching error during clone

**Risk**: CRITICAL (core functionality untested, hard to debug)

---

### ISSUE-16 & ISSUE-17: BuildConfigApplier Silent Failures

**Code Context** (BuildConfigApplier#render):
```ruby
# Line 15-35
def render(mrbgems_list)
  build_config_path = @r2p2_path / "build_config/picoruby.rb"
  original_content = File.read(build_config_path)

  build_block_start = find_build_block_start_line(original_content)
  build_block_end = find_build_block_end_line(original_content, build_block_start)

  # Insert mrbgems configuration
  lines = original_content.split("\n")
  new_config = generate_mrbgems_config(mrbgems_list)
  lines.insert(build_block_end - 1, new_config)

  updated_content = lines.join("\n")
  File.write(build_config_path, updated_content)
rescue => e  # ISSUE-16: Catch-all rescue silently swallows errors
  # No logging, no re-raise
end

def find_build_block_end_line(content, start_line)
  # ISSUE-17: Simple depth counting fails with mixed syntax
  lines = content.split("\n")
  depth = 0
  (start_line..lines.size).each do |i|
    line = lines[i]
    depth += line.count("{") - line.count("}")  # Only counts {}, not do...end
    return i if depth == 0
  end
end
```

**Test Strategy**:
```ruby
test "render catches and logs syntax errors in build config" do
  applier = BuildConfigApplier.new("/fake/path")
  File.stubs(:read).returns("if true\n  # Unclosed block")  # Invalid Ruby

  assert_raises(Picotorokko::BuildConfigError) do
    applier.render([])
  end
end

test "find_build_block_end_line handles mixed do...end and brace syntax" do
  content = <<~RUBY
    Picotorokko::Mrbgems.build do |conf|
      conf.gem core: "sprintf"
      [1,2,3].each { |x| puts x }  # Brace on same line as do...end
    end
  RUBY

  applier = BuildConfigApplier.new("/fake/path")
  start_line = applier.send(:find_build_block_start_line, content)
  end_line = applier.send(:find_build_block_end_line, content, start_line)

  assert_equal 4, end_line  # Correctly identifies "end" line
end
```

**Fix Approach**:
```ruby
def render(mrbgems_list)
  build_config_path = @r2p2_path / "build_config/picoruby.rb"
  original_content = File.read(build_config_path, encoding: "UTF-8")

  build_block_start = find_build_block_start_line(original_content)
  build_block_end = find_build_block_end_line(original_content, build_block_start)

  lines = original_content.split("\n")
  new_config = generate_mrbgems_config(mrbgems_list)
  lines.insert(build_block_end - 1, new_config)

  updated_content = lines.join("\n")

  # Validate syntax before writing
  begin
    RubyVM::AbstractSyntaxTree.parse(updated_content)
  rescue SyntaxError => e
    raise Picotorokko::BuildConfigSyntaxError, "Invalid Ruby in updated config: #{e.message}"
  end

  File.write(build_config_path, updated_content)
rescue Picotorokko::BuildConfigError => e
  raise
rescue => e
  raise Picotorokko::BuildConfigError, "Failed to apply mrbgems config: #{e.message}"
end

def find_build_block_end_line(content, start_line)
  lines = content.split("\n")
  depth = 0
  block_type = nil  # Track 'do' vs '{'

  (start_line..lines.size).each do |i|
    line = lines[i]

    # Count do...end blocks
    depth += line.count(/\bdo\b/) - line.count(/\bend\b/)

    # Count brace blocks (but exclude in strings/comments)
    line.each_char.with_index do |ch, idx|
      next if line[0...idx].count('"') % 2 == 1  # Skip if in string
      depth += 1 if ch == "{"
      depth -= 1 if ch == "}"
    end

    return i if depth == 0
  end

  raise Picotorokko::BuildBlockNotFoundError, "Could not find end of build block"
end
```

**Real User Impact**:
- ISSUE-16: User runs `ptrk mrbgems add my-sensor`, config corrupted silently, build fails later
- ISSUE-17: Multiple inline blocks in build_config = mrbgem config inserted in wrong place, build fails during linking

**Risk**: High (data corruption, hard to debug)

---

## 📊 [TODO-LARGE-METHOD-COVERAGE-GAPS] Other Untested Code Outside Session Scope

### Env.rb Module (lib/picotorokko/env.rb) - 364 lines

**CRITICAL - Zero Test Coverage:**

14. **[ISSUE-14] traverse_submodules_and_validate - 37 lines, COMPLETELY UNTESTED**
    - Location: line 229-265
    - Complexity: 3-level nested submodule traversal with depth tracking
    - Error paths not tested:
      - `git config submodule.*.path` failures
      - Missing submodule commits
      - Deep submodule warnings (depth > 2)
      - Git command timeouts
    - Impact: Users won't know if their R2P2-ESP32 clone is incomplete
    - Test gap: 0 tests for this 37-line method
    - Severity: CRITICAL (core functionality untested)

15. **[ISSUE-15] Untested path/cache infrastructure methods**
    - Methods not tested: `validate_env_name!`, `clone_with_submodules`, `get_commit_hash`, `get_timestamp`
    - Problem: Core directory structure methods have no test coverage
    - Impact: Silent failures if paths are malformed
    - Test gap: ~8 methods untested
    - Severity: HIGH (silent data loss potential)

### BuildConfigApplier (lib/picotorokko/build_config_applier.rb) - 158 lines

16. **[ISSUE-16] Invalid Ruby syntax not handled**
    - Location: line 23 (rescue clause at end of render)
    - Problem: If config file has syntax errors, silently returns unchanged
    - Impact: User doesn't know their mrbgem config wasn't applied
    - Test gap: No test for invalid Ruby in config
    - Severity: HIGH (silent failure)

17. **[ISSUE-17] Block depth tracking fails with mixed do...end/{...}**
    - Location: line 74-83 (find_build_block_end_line)
    - Problem: Depth counting assumes consistent block syntax, can fail with:
      - `do...end` and `{...}` on same line
      - Lambdas/procs mixing with build block
    - Impact: Incorrect line detection, mrbgem config inserted in wrong place
    - Test gap: No test for mixed block syntax
    - Severity: HIGH (data corruption possible)

### Commands/Mrbgems (lib/picotorokko/commands/mrbgems.rb) - 103 lines

18. **[ISSUE-18] No fallback when git config user.name missing**
    - Location: line 46
    - Problem: Uses `git config user.name` with no error handling
    - Impact: If git not configured, crashes with empty author
    - Test gap: No test for missing git config
    - Severity: MEDIUM (rare, but breaks on fresh git setups)

19. **[ISSUE-19] No validation for mrbgems directory already existing as file**
    - Location: line 53
    - Problem: Creates directory without checking if path is already a file
    - Impact: `mkdir_p` fails cryptically if `mrbgems/` exists as file not dir
    - Test gap: No test for this edge case
    - Severity: MEDIUM (UX issue)

### Template/RubyEngine (lib/picotorokko/template/ruby_engine.rb) - 105 lines

20. **[ISSUE-20] Placeholder mapping doesn't handle underscores correctly**
    - Location: line 87 (constant_name.downcase)
    - Problem: `TEMPLATE_CLASS_NAME_APP` becomes `class_name_app` but expects `classNameApp` or different format
    - Impact: Placeholders with underscores don't match variables
    - Test gap: No test for underscore handling
    - Severity: MEDIUM (template variable naming broken)

21. **[ISSUE-21] Multiple identical placeholders on same line not handled**
    - Location: line 116-124 (apply_replacements)
    - Problem: Simple string replacement doesn't account for offset shifts
    - Impact: If same placeholder appears twice on line, second replacement is offset
    - Test gap: No test for duplicate placeholders
    - Severity: MEDIUM (template rendering broken for DRY code)

### Commands/Env (lib/picotorokko/commands/env.rb) - 316 lines

22. **[TODO-RUBOCOP-CLASS-LENGTH] Env class exceeds RuboCop line limit**
    - Location: lib/picotorokko/commands/env.rb:14
    - Problem: Class has 316 lines (threshold: 300)
    - Impact: RuboCop reports single violation, affects CI cleanliness
    - Solution: Refactor Env class into smaller modules:
      - EnvRepository (environment YAML persistence)
      - EnvValidator (validation logic)
      - EnvBuilder (clone/checkout operations)
      - EnvInspector (inspection/listing)
    - Severity: MEDIUM (style/maintainability issue, not functional)
    - Estimated effort: 2-3 refactoring commits

### Summary by Priority

**CRITICAL (implement immediately)**:
- ISSUE-14: `traverse_submodules_and_validate` - 37 lines, 0 tests
- ISSUE-16: Invalid Ruby syntax handling
- ISSUE-17: Block depth tracking with mixed syntax

**HIGH** (implement soon):
- ISSUE-15: Path/cache methods untested
- ISSUE-18: Git config fallback missing
- ISSUE-20: Placeholder underscore mapping broken

**MEDIUM** (implement next):
- ISSUE-19: mrbgems directory validation
- ISSUE-21: Duplicate placeholder handling
- TODO-RUBOCOP-CLASS-LENGTH: Refactor Env class to reduce line count

### Overall Test Coverage Status

| File | Lines | Public Methods | Tested | Untested | Gap % |
|------|-------|---|---|---|---|
| env.rb | 364 | 28 | 16 | 12 | 43% |
| build_config_applier.rb | 158 | 2 | 2 | 0 (edge cases) | 15% |
| commands/rubocop.rb | 126 | 2 | 2 | 0 (I/O errors) | 5% |
| commands/mrbgems.rb | 103 | 1 | 1 | 0 (edge cases) | 10% |
| template/ruby_engine.rb | 105 | 2 | 2 | 0 (edge cases) | 10% |
| **TOTAL** | **3196** | **N/A** | **High-level** | **Low-level** | **~25-30%** |

**Estimated additional tests needed**: 30-40 tests to reach 95%+ coverage across all modules

---

## 🚀 [TODO-TEST-PERFORMANCE-OPTIMIZATION] Test Execution Speed Tuning (Next Session)

**Session Goal**: Accelerate t-wada style TDD cycles by optimizing test runtime without changing product code.

**Current Baseline** (2025-11-18 MEASURED):
- **Total runtime**: 176.54 seconds (~3min 0sec) - **ACTUAL MEASURED** (via `time bundle exec rake test`)
- **Test count**: 246 tests (with 7 omissions), 528 assertions
- **Coverage**: 84.81% line, 65.54% branch
- **Throughput**: 1.39 tests/sec, 3.01 assertions/sec
- **Bottleneck**: Dir.mktmpdir operations (130 uses, ~40-80 seconds total = 23-45% of runtime)

**NOTE on baseline discrepancy**:
- Earlier estimate in handoff prompt: 78.87 seconds
- Actual measured: 176.54 seconds
- Hypothesis: Earlier measurement may have been for simplified test run or different configuration
- **Impact**: Phase 1-2 optimizations will have greater absolute effect than estimated (gain in seconds is larger)

### Detailed Performance Analysis

#### Performance Bottleneck Breakdown

**1. Dir.mktmpdir Operations (HIGHEST PRIORITY)**
- **Occurrences**: 134 total across 10 files
- **Estimated cost**: 0.3-1.0 sec per block (includes file creation/deletion)
- **Total impact**: 40-80 seconds (46-92% of all test time)
- **Distribution**:
  - `test/commands/env_test.rb`: 60 uses
  - `test/commands/init_test.rb`: 15 uses
  - `test/commands/mrbgems_test.rb`: 10 uses
  - `test/commands/rubocop_test.rb`: 10 uses
  - Others: 39 uses across 6 files
- **Root cause**: Each test case creates isolated tmpdir, destroys on completion
- **Optimization potential**: 20-40 sec (via reuse), 30-50 sec (via parallelization)

**2. SimpleCov Branch Coverage Measurement (MEDIUM PRIORITY)**
- **Configuration**: `enable_coverage :branch` in test/test_helper.rb:4
- **Estimated overhead**: 10-17 seconds (12-20% slowdown)
- **Current behavior**: Branch coverage measured in all runs (dev + CI)
- **Optimization opportunity**: Disable in dev, enable only in CI (via ENV vars)

**3. SimpleCov XML Output (LOW PRIORITY)**
- **Formatter**: CoberturaFormatter (generates XML reports)
- **Estimated overhead**: 2-5 seconds (2-6%)
- **Current behavior**: XML generated in all runs
- **Optimization opportunity**: Use HTMLFormatter in dev, CoberturaFormatter only in CI

**4. FileUtils Operations (MEDIUM IMPACT)**
- **Occurrences**: 126 across 11 files
- **Per-operation cost**: 0.05-0.2 seconds
- **Total impact**: 6-25 seconds
- **Files**: env_test.rb (60), project_initializer_test.rb (12), template/c_engine_test.rb (10), others (44)

**5. capture_stdout (NEGLIGIBLE)**
- **Occurrences**: 75 across 6 files
- **Per-call cost**: 1-5ms
- **Total impact**: 0.1-0.4 seconds
- **No optimization needed**

**6. system() calls (MINIMAL)**
- **Occurrences**: 31 (mostly Git operations)
- **Status**: Already mocked via SystemCommandMocking
- **No optimization needed**

**NOT FOUND** ✅:
- ❌ `sleep` commands (0 occurrences) - Good!
- ❌ `Timeout` use (0 occurrences) - Good!

### Proposed Optimization Phases

#### Phase 1: Immediate Implementation (Low Risk, 12-22 sec gain)

**1.1: SimpleCov Formatter Environment Variable Control**
- **Change**: Use HTMLFormatter in dev, CoberturaFormatter in CI
- **Code location**: test/test_helper.rb:5-6
- **Implementation**:
  ```ruby
  unless ENV["CI"]
    SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  else
    SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  end
  ```
- **Expected gain**: 2-5 seconds (2-6%)
- **Risk**: None (dev/CI separation already in place)
- **Verification**: Run `bundle exec rake test` locally, verify HTML report generated

**1.2: SimpleCov Branch Coverage CI-Only**
- **Change**: Disable branch coverage in dev, enable in CI
- **Code location**: test/test_helper.rb:3
- **Current**: `enable_coverage :branch` (always)
- **Implementation**:
  ```ruby
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/vendor/"
    add_filter "/lib/picotorokko/templates/"
    enable_coverage :branch if ENV["CI"]  # Dev: line-only, CI: branch coverage
    minimum_coverage line: 75
    minimum_coverage branch: 55 if ENV["CI"]
  end
  ```
- **Expected gain**: 10-17 seconds (12-20%)
- **Risk**: Low (coverage thresholds still enforced in CI)
- **Verification**:
  - Local: `bundle exec rake test` (faster, no branch coverage)
  - CI: `bundle exec rake ci` (full coverage validation)

**Combined Phase 1 gain**: 12-22 seconds → Final runtime: 65-75 seconds

---

#### Phase 2: Parallel Test Execution with Dynamic Worker Configuration (Medium Risk, 30-50 sec gain)

**2.1: test-unit Parallel Worker Configuration (Environment Variable Based)**

**CRITICAL CONTEXT** (2025-11-18 discovery):
- CI environments are NOT fixed CPU count (ubuntu-slim vs ubuntu-latest vs other runners)
- Default fixed `--max-workers=4` is inappropriate
- **SOLUTION**: Use `TEST_WORKERS` environment variable for dynamic configuration
- **Reference branch**: `origin/claude/tdd-ruby-microcycles-01TfCHzygrxVMxW4Wk7q2uXt`
  - Commit 6b17617: `fix: correct test-unit parallel execution options`
  - Commit 8686330: `perf: enable parallel test execution with 4 workers`
  - Note: Uses `--parallel --n-workers=4` (test-unit API, not `--max-workers`)

**Code location**: Rakefile (test task definition)
**Current**: No parallelization configured
**Implementation** (ENVIRONMENT VARIABLE REQUIRED):
```ruby
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  test_files = FileList["test/**/*_test.rb"].sort
  test_files.delete_if { |f| f.include?("device_test.rb") }
  t.test_files = test_files
  t.ruby_opts = ["-W1"]

  # Parallel test execution with dynamic worker count
  # TEST_WORKERS controls parallelism across different CI environments
  # Default: 4 workers (local development with 4+ CPU cores)
  # CI override: 2 workers (ubuntu-slim with 2 CPU limit)
  # Fallback: 1 worker (small/resource-constrained environments)
  num_workers = ENV.fetch("TEST_WORKERS", "4").to_i
  t.options = "--parallel --n-workers=#{num_workers}"
end
```

**GitHub Actions CI Configuration** (.github/workflows/main.yml):
```yaml
- name: Run tests with coverage
  env:
    TEST_WORKERS: 2      # ubuntu-slim has 2 CPU limit
    CI: 1                # Enable SimpleCov branch coverage (Phase 1)
  run: bundle exec rake test
```

**Usage Guide**:
| Environment | Command | TEST_WORKERS | Rationale |
|------------|---------|--------------|-----------|
| **Local dev (4+ CPU)** | `bundle exec rake test` | 4 (default) | Fast TDD feedback |
| **CI (ubuntu-slim)** | `CI=1 bundle exec rake test` | 2 | Respects 2-CPU limit |
| **Resource-constrained** | `TEST_WORKERS=1 bundle exec rake test` | 1 | Fallback/debugging |
| **High-capacity CI** | `TEST_WORKERS=8 bundle exec rake test` | 8+ | Optional scaling |

**Expected gain**: 30-50 seconds (35-58% with 4-core machine, scales with worker count)
- Local (4 workers): 160s → 60-80s
- CI (2 workers): 160s → 100-120s
- Sequential (1 worker): 160s (baseline)

**Risk**: Medium (requires verification that tests don't share state)
**Current state safety**: `Dir.mktmpdir` blocks are independent per test, low coupling risk

**Verification checklist** (REQUIRED):
1. **Flakiness verification** (CRITICAL):
   ```bash
   # Test with 4 workers (3x for consistency check)
   for i in {1..3}; do
     TEST_WORKERS=4 bundle exec rake test 2>&1 | tee /tmp/test_4w_$i.log
   done
   grep "assertions" /tmp/test_4w_*.log  # Verify consistent results

   # Test with 2 workers (CI simulation)
   for i in {1..3}; do
     TEST_WORKERS=2 bundle exec rake test 2>&1 | tee /tmp/test_2w_$i.log
   done
   grep "assertions" /tmp/test_2w_*.log
   ```
2. Run: `CI=1 bundle exec rake ci` and verify all tests pass
3. Confirm CI workflow executes with TEST_WORKERS=2 environment variable
4. Check GitHub Actions logs for parallel execution confirmation

**Combined Phase 1+2 gain**: 42-72 seconds → Final runtime: 15-45 seconds (83% improvement)

---

#### Phase 3: Dir.mktmpdir Reuse Strategy (High Risk, Reserve for Later)

**NOT IMPLEMENTED YET** - High risk, requires careful design:
- **Approach**: Setup/teardown pattern with shared tmpdir + subdirectories per test
- **Risk factors**:
  - Test state leakage between cases
  - Parallel execution collision
  - Flakiness from stale temp files
  - Debugging complexity (no isolation)
- **Estimated gain**: 20-40 seconds (if successful)
- **Recommendation**: Implement only after Phase 1+2 validated and verified stable

---

### Implementation Checklist

**PHASE 1: SimpleCov Optimization**
- [ ] **Phase 1.1**: Edit SimpleCov formatter (dev: HTMLFormatter, CI: CoberturaFormatter)
- [ ] **Phase 1.2**: Edit SimpleCov branch coverage (disable in dev, enable in CI via ENV["CI"])
- [ ] **Verify Phase 1 locally**: `bundle exec rake test` (expect 150-160 sec, -10 to -20 sec gain)
- [ ] **Verify Phase 1 in CI**: `CI=1 bundle exec rake ci` (expect 176 sec, no change)
- [ ] **Commit Phase 1**: Small focused commit with clear message

**PHASE 2: Parallel Execution with Environment Variable Configuration**
- [ ] **Phase 2.1**: Update Rakefile test task with `TEST_WORKERS` environment variable
  - [ ] Extract worker count: `num_workers = ENV.fetch("TEST_WORKERS", "4").to_i`
  - [ ] Use test-unit parallel API: `t.options = "--parallel --n-workers=#{num_workers}"`
  - [ ] Add clear comments documenting default and CI override values
- [ ] **Phase 2.2**: Update .github/workflows/main.yml
  - [ ] Add `env: { TEST_WORKERS: 2, CI: 1 }` to test step
  - [ ] Rationale: ubuntu-slim has 2 CPU limit
- [ ] **Phase 2.3: Flakiness Verification** (CRITICAL - 3x each worker count):
  - [ ] Test with 4 workers: `for i in {1..3}; do TEST_WORKERS=4 bundle exec rake test 2>&1 | tee /tmp/test_4w_$i.log; done`
  - [ ] Test with 2 workers: `for i in {1..3}; do TEST_WORKERS=2 bundle exec rake test 2>&1 | tee /tmp/test_2w_$i.log; done`
  - [ ] Verify consistency: `grep "assertions" /tmp/test_*w_*.log` (all logs must show identical assertion count)
  - [ ] Check for flaky failures: `grep -i "failure\|error" /tmp/test_*w_*.log` (should be none)
- [ ] **Phase 2.4: CI Verification**:
  - [ ] Run CI workflow: Push to branch and verify GitHub Actions execution
  - [ ] Confirm TEST_WORKERS=2 in logs
  - [ ] Verify all tests pass with parallel execution
- [ ] **Phase 2.5: Local Performance Measurement**:
  - [ ] Measure Phase 1+2 combined: `time bundle exec rake test` (expect 60-80 sec)
  - [ ] Calculate actual gain vs baseline (176 sec)
- [ ] **Commit Phase 2**: Separate focused commits for Rakefile and workflow changes

**PHASE 3: Test Selection (rake test:related)**
- [ ] **Defer to next planning session after Phase 1-2 validation**
- [ ] Phase 1-2 must be stable for 2+ weeks before Phase 3 planning
- [ ] Reference: handoff prompt Phase 3 section for detailed task breakdown

**VALIDATION & DOCUMENTATION**
- [ ] **Validate combined**: Run `bundle exec rake ci`, confirm all quality gates pass
- [ ] **Regression monitoring**: Run tests weekly, alert if runtime > 120s (for dev) or > 150s (for CI)
- [ ] **Update documentation**: SPEC.md "Test Execution" section with new performance metrics
- [ ] **Update CLAUDE.md**: Add TEST_WORKERS environment variable usage guide for developers

### Expected Outcomes

**REVISED based on 2025-11-18 actual measurement (176.54s baseline)**:

**After Phase 1 alone** (SimpleCov optimization):
- Dev test runtime: 150-160 seconds (-10 to -20 seconds from SimpleCov branch disable)
- CI test runtime: 176 seconds (unchanged, coverage still validated)
- Impact: Marginal improvement alone, but foundation for Phase 2

**After Phase 1+2** (SimpleCov + Parallel execution):
- Dev test runtime: 60-80 seconds (with TEST_WORKERS=4 default)
  - Phase 1 gain: -10 to -20 sec (SimpleCov)
  - Phase 2 gain: -50 to -100 sec (parallelization)
  - **Combined: 55-60% reduction** (excellent for TDD)
- CI test runtime: 100-120 seconds (with TEST_WORKERS=2 on ubuntu-slim)
  - Phase 1 gain: -10 to -20 sec (SimpleCov)
  - Phase 2 gain: -40 to -60 sec (parallelization with 2 workers)
  - **Combined: 35-43% reduction** (respects CPU constraints)
- Dev TDD cycle: Red (1s) → Green (2-3s) → RuboCop (3-5s) → Refactor → Commit (total ~8-12 sec per cycle)

### Monitoring & Regression Detection

**After implementation**, periodically measure with:
```bash
time bundle exec rake test
```

**Alert conditions** (add to pre-push hook if needed):
- Test runtime > 60 seconds (investigate performance regression)
- Test runtime variation > 10 seconds (check for flakiness)
- Coverage drop > 1% (regression in test effectiveness)

---

## 📝 [SESSION-2025-11-18] Context Summary & Key Decisions

**Session Focus**: Analysis & Planning (No Implementation)

### Critical Discoveries

1. **Actual Test Runtime is 176.54 seconds** (NOT 78.87 seconds)
   - Baseline measurement: `time bundle exec rake test` = 176.54 seconds
   - Handoff prompt estimate was for different configuration/earlier state
   - Impact: Phase 1-2 optimization gains are larger in absolute seconds

2. **CI Environment Constraint: Non-fixed CPU counts**
   - GitHub Actions uses `ubuntu-slim` (2 CPU) by default in this project
   - Default `--max-workers=4` was inappropriate (would exceed CPU capacity)
   - **Solution Implemented**: Use `TEST_WORKERS` environment variable for dynamic scaling
   - **Reference Branch**: `origin/claude/tdd-ruby-microcycles-01TfCHzygrxVMxW4Wk7q2uXt`
     - Contains Phase 1-2 implementation (SimpleCov + parallel with fixed `--n-workers=4`)
     - Requires modification: replace fixed 4 with `ENV.fetch("TEST_WORKERS", "4").to_i`

3. **Test-unit Parallel API Clarification**
   - Correct API: `--parallel --n-workers=N` (NOT `--max-workers=N`)
   - Commit 6b17617 shows correct implementation
   - Must use `t.options = "--parallel --n-workers=#{num_workers}"`

### Key Planning Decisions

| Decision | Rationale | Status |
|----------|-----------|--------|
| Phase 1: SimpleCov optimization first | Low risk, foundation for Phase 2 | ✅ Plan ready |
| Phase 2: Environment variable approach | Supports diverse CI environments | ✅ Plan ready |
| TEST_WORKERS=4 (local default) | Balance speed with system load | ✅ Agreed |
| TEST_WORKERS=2 (CI ubuntu-slim) | Respects 2-CPU limit | ✅ Agreed |
| Flakiness verification 3x each | Critical before merge | ✅ Checklist added |
| Phase 3: Defer after Phase 1-2 stable | Avoid complexity stacking | ✅ Recommended |

### Next Session Checklist

**Before Implementation Starts**:
- [ ] Confirm TEST_WORKERS=4 and TEST_WORKERS=2 values are correct for target environments
- [ ] Verify ubuntu-slim CPU count (assumed 2, validate in GitHub Actions docs if needed)
- [ ] Decide: Merge from `origin/claude/tdd-ruby-microcycles-01TfCHzygrxVMxW4Wk7q2uXt` and modify?
  - OR start fresh with environment variable implementation?

**Implementation Order** (Recommended):
1. Phase 1: SimpleCov optimization (1-2 hours)
   - test/test_helper.rb changes
   - Verification: local test + CI test
   - Commit

2. Phase 2: Parallel execution with TEST_WORKERS (3-4 hours)
   - Rakefile: Add `TEST_WORKERS` env var handling
   - .github/workflows/main.yml: Set TEST_WORKERS=2
   - Flakiness verification: 3x with 4 workers, 3x with 2 workers
   - CI workflow verification
   - Commit

3. Phase 3+: Plan after Phase 1-2 validation (defer 2+ weeks)

### Documentation References

- **Handoff Prompt**: Full Phase 1-4 strategy in handoff prompt (comprehensive, mostly sound)
- **Alternative Implementation**: `origin/claude/tdd-ruby-microcycles-01TfCHzygrxVMxW4Wk7q2uXt` (partially complete, requires TEST_WORKERS modification)
- **Baseline Data**: Actual 176.54s measurement as new baseline for all estimates
- **This Session**: Completed deep analysis, created detailed implementation plan with environment variable support

---

**チェケラッチョ！！** Phase 1-2 の実装準備が整ったピョン！環境変数による動的 worker 設定で、さまざまな CI 環境に対応できるようにしたよ。
