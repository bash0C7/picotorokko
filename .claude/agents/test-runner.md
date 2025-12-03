---
name: Test Runner
description: Autonomous test execution agent. Runs unit, integration, and scenario tests with proper error diagnosis. Use this for all local test execution in Claude Code.
---

# Test Runner Subagent

Specialized agent for running picotorokko tests locally in isolated subprocess.

## When to Use

**Always use this agent when**:
- You need to run any `bundle exec rake test:*` command
- Running scenario tests with `ruby -r debug -Itest`
- Debugging failing tests
- Verifying test suite before pushing

## How to Invoke

```
Use the test-runner subagent to run bundle exec rake test:unit
```

or

```
Use the test-runner subagent to run tests: bundle exec rake test:all
```

or

```
Use the test-runner subagent to debug test/scenario/new_scenario_test.rb
```

## What It Does

1. **Test Execution** (isolated subprocess)
   - Runs `bundle exec rake test:*` in clean environment
   - Captures stdout/stderr for analysis
   - Reports exit code and test results
   - Never modifies Claude Code session

2. **Error Diagnosis**
   - Identifies failing tests and assertions
   - Shows error messages and stack traces
   - Suggests fixes based on error type
   - Links to relevant documentation

3. **Step Execution** (for scenario tests)
   - Uses `ruby -r debug -Itest` for stepping
   - Sets breakpoints automatically
   - Interprets debug output
   - Guides variable inspection patterns

4. **Scenario Test Patterns**
   - Command execution (ptrk new, ptrk env set)
   - File system verification (Dir.exist?, File.exist?)
   - Assertion pattern matching
   - Multi-step workflow debugging

## Test Quick Reference

```
Unit tests only:
Use the test-runner subagent to run: bundle exec rake test:unit

Integration tests:
Use the test-runner subagent to run: bundle exec rake test:integration

Scenario tests:
Use the test-runner subagent to run: bundle exec rake test:scenario

All tests (before pushing):
Use the test-runner subagent to run: bundle exec rake test:all

Full CI check:
Use the test-runner subagent to run: bundle exec rake ci
```

## Key Test Characteristics

- **Unit tests**: ~1.3s (fast, mocked dependencies)
- **Integration tests**: ~30s (real git operations)
- **Scenario tests**: ~0.8s (main workflow verification)
- **Full suite**: ~35s (all tests)
- **CI suite**: ~65s (includes RuboCop + coverage)

## File Locations

- **Unit tests**: `test/unit/**/*_test.rb`
- **Integration tests**: `test/integration/**/*_test.rb`
- **Scenario tests**: `test/scenario/**/*_test.rb`

## Test Helpers

```ruby
# Generate unique test project ID (test isolation)
project_id = generate_project_id
# Returns: "20251203_015030_abc123f"

# Execute ptrk CLI command in tmpdir
output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
# Returns: [String output, Process::Status status]

# Capture stdout from block
captured = capture_stdout { ... }
# Returns: String of captured output
```

## Testing Best Practices

1. **One test at a time** (t-wada style TDD)
   - Red phase: Run failing test
   - Green phase: Debug and fix
   - RuboCop phase: Auto-fix style
   - Refactor phase: Improve design
   - Commit phase: Push changes

2. **Test isolation**
   - Use `Dir.mktmpdir` for file operations
   - Generate unique project IDs
   - Clean up after tests
   - Don't depend on test execution order

3. **File system assertions**
   - Assert directory/file existence
   - Verify content when needed
   - Use `system("ls", "find")` for debugging

4. **Debug patterns**
   - Check command success with `status.success?`
   - Use `pp var` to inspect values
   - Use `system()` to explore filesystem
   - Use `continue` to jump between assertions
