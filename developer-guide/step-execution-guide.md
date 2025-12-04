# Step Execution Guide for Scenario Tests

デバッグジェムを使ったシナリオテストのステップ実行検証ガイド。

## Prerequisites

### 1. Debug Gem Installation

```bash
# Install debug gem locally (not in Gemfile due to CI constraints)
gem install debug

# Verify installation
rdbg -v
# => ruby-debug-gem <version>
```

### 2. Understanding rdbg (Ruby Debugger)

`rdbg` is the Ruby debugger included in the `debug` gem. It provides:
- **Command-line breakpoints**: `-b "file:line"`
- **Interactive mode**: Step through code line-by-line
- **Variable inspection**: Print and evaluate expressions
- **Conditional breaks**: Break only when conditions match

## Basic Step Execution Workflow

### Step 1: Identify the Test to Debug

Choose a scenario test file:
```bash
# Simple tests (good for learning)
test/scenario/new_scenario_test.rb          # 6 tests
test/scenario/multi_env_test.rb             # 5 tests
test/scenario/storage_home_test.rb          # 5 tests

# Complex tests (more challenging)
test/scenario/phase5_e2e_test.rb            # 5 tests
test/scenario/mrbgems_workflow_test.rb      # 9 tests
test/scenario/project_lifecycle_test.rb     # 5 tests
```

### Step 2: Set Breakpoint at Test Entry

Find the line number where the test starts:

```ruby
# example: test/scenario/new_scenario_test.rb:26
test "creates complete project structure for new development" do
```

Run with breakpoint:
```bash
rdbg -c -b "test/scenario/new_scenario_test.rb:26" \
  -- bundle exec ruby -Itest test/scenario/new_scenario_test.rb
```

### Step 3: Interactive Debugging Session

Once the debugger starts and hits the breakpoint, use these commands:

```
(rdbg) step          # Step to next line
(rdbg) next          # Step over method calls
(rdbg) continue      # Continue to next breakpoint
(rdbg) info locals   # Show local variables
(rdbg) pp tmpdir     # Pretty-print variable
(rdbg) help          # Show all commands
(rdbg) quit          # Exit debugger
```

### Step 4: Key Inspection Points

When debugging scenario tests, focus on:

1. **Test setup**: Verify `tmpdir` is created correctly
2. **Command execution**: Check `run_ptrk_command` output and status
3. **File system state**: Verify files/directories exist after command runs
4. **Assertions**: Check what the test expects vs. what actually happened

Example inspection:
```
(rdbg) pp output     # See full command output
(rdbg) pp status     # See command exit status
(rdbg) system("ls -la #{tmpdir}")  # Inspect directory contents
```

## Practical Examples

### Example 1: Debug new_scenario_test.rb Simple Test

```bash
# Scenario: User creates basic PicoRuby project
# Breakpoint: Test entry point (creates project)

rdbg -c -b "test/scenario/new_scenario_test.rb:26" \
  -- bundle exec ruby -Itest test/scenario/new_scenario_test.rb

# Interactive commands:
(rdbg) step                    # Move to next line
(rdbg) info locals            # See tmpdir, project_id
(rdbg) step                    # Execute run_ptrk_command
(rdbg) pp status.success?      # Check if command succeeded
(rdbg) system("ls -la #{tmpdir}") # Inspect what was created
(rdbg) step                    # Continue to first assertion
(rdbg) quit
```

### Example 2: Debug multi_env_test.rb Environment Test

```bash
# Scenario: User lists environments
# Breakpoint: After environment creation

rdbg -c -b "test/scenario/multi_env_test.rb:35" \
  -- bundle exec ruby -Itest test/scenario/multi_env_test.rb

# Useful inspection:
(rdbg) pp output             # See list of environments
(rdbg) pp output.lines       # See as array of lines
(rdbg) pp output.include?("env_name")  # Check for specific environment
```

### Example 3: Debug phase5_e2e_test.rb Complex Workflow

```bash
# Scenario: Complete project initialization workflow
# Breakpoint: First command execution

rdbg -c -b "test/scenario/phase5_e2e_test.rb:30" \
  -- bundle exec ruby -Itest test/scenario/phase5_e2e_test.rb

# Step through full workflow:
(rdbg) next   # Step over run_ptrk_command("new #{project_id}")
(rdbg) pp status.success?     # Verify creation succeeded
(rdbg) next   # Step to environment setup
(rdbg) pp output              # Check environment setup output
(rdbg) next   # Step to environment switch
(rdbg) pp File.exist?(File.join(project_dir, ".ptrk_env")) # Verify .ptrk_env exists
```

## Advanced Debugging Techniques

### 1. Multiple Breakpoints

Set multiple breakpoints to trace control flow:

```bash
rdbg -c \
  -b "test/scenario/phase5_e2e_test.rb:30" \
  -b "test/scenario/phase5_e2e_test.rb:45" \
  -b "test/scenario/phase5_e2e_test.rb:60" \
  -- bundle exec ruby -Itest test/scenario/phase5_e2e_test.rb
```

The debugger will stop at each breakpoint in sequence.

### 2. Conditional Breakpoints

Use Ruby expressions to break conditionally:

```bash
rdbg -c \
  -b "test/scenario/new_scenario_test.rb:30:status.failure?" \
  -- bundle exec ruby -Itest test/scenario/new_scenario_test.rb
```

Stops only if `status.failure?` is true.

### 3. Post-Mortem Debugging (If Test Fails)

If a test fails, use `binding.break` in the test to debug at failure point:

```ruby
# In test/scenario/new_scenario_test.rb, add near assertion:
test "creates complete project structure" do
  Dir.mktmpdir do |tmpdir|
    project_id = generate_project_id
    output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)

    # Add this for interactive debugging on failure:
    binding.break unless status.success?

    assert status.success?, "ptrk new should succeed"
  end
end
```

Then run normally and the debugger starts on failure:

```bash
bundle exec ruby -Itest test/scenario/new_scenario_test.rb
# Debugger starts at binding.break if status is not success
```

## Test Helper Functions

### run_ptrk_command

```ruby
# Executes ptrk CLI command in specified directory
output, status = run_ptrk_command("new my-project", cwd: tmpdir)

# Returns:
# - output (String): Command output (stdout + stderr combined)
# - status (Process::Status): Exit status object
#   - status.success?  # true if exit code 0
#   - status.exitstatus  # raw exit code (0-255)
```

### generate_project_id

```ruby
# Generates unique project ID for test isolation
project_id = generate_project_id
# => "20251203_015030_abc123f"  (timestamp + hash)
```

### Useful assertions

```ruby
# File system checks
assert Dir.exist?(File.join(project_dir, "storage", "home"))
assert File.exist?(File.join(project_dir, "README.md"))

# Content checks
content = File.read(File.join(project_dir, "README.md"), encoding: "UTF-8")
assert_match(/project_id/, content)

# Command exit status
assert status.success?, "ptrk new should succeed. Output: #{output}"
assert_equal 1, status.exitstatus  # Check specific exit code
```

## Common Debugging Scenarios

### Scenario A: Command Fails Unexpectedly

```bash
# Set breakpoint right after command execution
rdbg -c -b "test/scenario/new_scenario_test.rb:32" \
  -- bundle exec ruby -Itest test/scenario/new_scenario_test.rb

(rdbg) pp output           # See error message
(rdbg) pp status.exitstatus  # See exit code
(rdbg) system("ls -la #{tmpdir}")  # What was actually created?
```

### Scenario B: Assertion Fails - File Not Found

```bash
# Debug file system state
rdbg -c -b "test/scenario/storage_home_test.rb:40" \
  -- bundle exec ruby -Itest test/scenario/storage_home_test.rb

(rdbg) system("find #{tmpdir} -type f")  # Find all files
(rdbg) system("tree #{tmpdir}")  # Visual directory tree
(rdbg) system("stat #{tmpdir}/my-project/storage/home")  # Check permissions
```

### Scenario C: Multiple Steps in Workflow

For tests with several commands, add breakpoints between steps:

```bash
rdbg -c \
  -b "test/scenario/project_lifecycle_test.rb:35" \
  -b "test/scenario/project_lifecycle_test.rb:45" \
  -b "test/scenario/project_lifecycle_test.rb:55" \
  -- bundle exec ruby -Itest test/scenario/project_lifecycle_test.rb

# Use 'continue' to jump to next breakpoint
(rdbg) pp status  # Check first command
(rdbg) continue   # Jump to second breakpoint
(rdbg) pp output  # Check second command output
(rdbg) continue   # Jump to third breakpoint
```

## Tips & Tricks

### 1. Run Only One Test Method

When debugging specific test:
```bash
# Run only one test from the file
rdbg -c -b "test/scenario/new_scenario_test.rb:26" \
  -- bundle exec ruby -Itest -t ScenarioNewTest#test_creates_complete_project_structure_for_new_development
```

### 2. Quiet Output

The `debug` gem outputs lots of information. Reduce noise:

```bash
# Pipe to tail to see only recent lines
rdbg -c -b "test/scenario/new_scenario_test.rb:26" \
  -- bundle exec ruby -Itest test/scenario/new_scenario_test.rb 2>&1 | tail -100
```

### 3. Save Debug Session Transcript

```bash
# Record all debugger output
rdbg -c -b "test/scenario/new_scenario_test.rb:26" \
  -- bundle exec ruby -Itest test/scenario/new_scenario_test.rb | tee debug_session.log
```

## Workflow Integration

### Development Cycle with Step Execution

```
1. Write test (Red phase)
   bundle exec ruby -Itest test/scenario/your_test.rb

2. Run with debugger when test fails (Green phase)
   rdbg -c -b "test/scenario/your_test.rb:LINE" \
     -- bundle exec ruby -Itest test/scenario/your_test.rb

3. Fix code based on debug findings

4. Verify with RuboCop
   bundle exec rubocop test/scenario/your_test.rb

5. Commit when all tests pass
   git add test/scenario/your_test.rb
   git commit -m "test: add new scenario for X feature"
```

## Troubleshooting

### Issue: rdbg not found

```bash
# Solution: Install debug gem
gem install debug

# Verify:
which rdbg
```

### Issue: Debugger won't start

```bash
# Make sure you're using correct Ruby version
ruby --version  # Should be 3.3+

# Reinstall debug gem
gem uninstall debug
gem install debug
```

### Issue: Breakpoint not hitting

```bash
# Verify line number exists in file
grep -n "creates complete" test/scenario/new_scenario_test.rb

# Use correct file path and line number
rdbg -c -b "test/scenario/new_scenario_test.rb:26" \
  -- bundle exec ruby -Itest test/scenario/new_scenario_test.rb
```

## Summary

Step execution verification with `rdbg` provides:
- ✅ Line-by-line visibility into test execution
- ✅ Interactive variable inspection
- ✅ File system state verification
- ✅ Command output analysis
- ✅ Assertion debugging

For scenario tests following t-wada TDD style:
1. **Red**: Write failing test → Run normally to see failure
2. **Green**: Implement code → Use step execution to verify behavior
3. **RuboCop**: Auto-fix style → Run tests again
4. **Refactor**: Improve code → Use step execution to verify refactoring didn't break logic
5. **Commit**: When all steps pass

See `CLAUDE.md` for integration with project workflow.
