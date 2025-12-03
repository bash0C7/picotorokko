# Step Execution Debugging Session Example

## Real-World Example: Debug new_scenario_test.rb

### Setup

```bash
# Navigate to project root
cd /home/user/picotorokko

# Install debug gem if not already installed
gem install debug

# Start debugging session with step execution
ruby -r debug -Itest test/scenario/new_scenario_test.rb
```

### Expected Startup Output

```
S
Loading test framework...
[Breakpoint] Starting test framework setup...
(rdbg)
```

### Interactive Debugging Session Walkthrough

#### Phase 1: Navigate to Test Entry Point

```
(rdbg) continue
# OR type 'c' for short

# Output shows:
Started
S...

(rdbg) step
# Step into test class definition
```

#### Phase 2: Step Through Test Execution

Assuming we stop at the first test method `test_creates_complete_project_structure_for_new_development`:

```
(rdbg) step                           # Move to first line of test
(rdbg) step                           # Execute Dir.mktmpdir block entry
(rdbg) pp tmpdir                      # Inspect tmpdir value
=> "/tmp/d20251203-9999-abc123"

(rdbg) step                           # Generate project ID
(rdbg) pp project_id                  # Inspect project ID
=> "20251203_015500_f7a8b3"

(rdbg) step                           # Execute run_ptrk_command
# This line takes a moment as it spawns ptrk process
(rdbg) pp output                      # Check command output
=> "Creating project my_project_20251203_015500_f7a8b3 at /tmp/d20251203-9999-abc123\n..."

(rdbg) pp status.success?             # Check if command succeeded
=> true

(rdbg) pp status.exitstatus           # Check exit code
=> 0

(rdbg) step                           # Move to project_dir assertion
(rdbg) step                           # Execute first Dir.exist? check
(rdbg) next                           # Skip to next meaningful line
```

#### Phase 3: Verify File System State

When test assertion fails, verify actual state:

```
(rdbg) step                           # Execute: assert Dir.exist?(project_dir)
(rdbg) pp Dir.exist?(project_dir)     # Did directory get created?
=> true  # Good!

(rdbg) step                           # Move to next assertion
(rdbg) system("ls -la #{tmpdir}")     # List tmpdir contents
# Output:
# total 8
# drwxr-xr-x  3 root root 4096 Dec  3 01:55 .
# drwxrwxrwt 15 root root 4096 Dec  3 01:55 ..
# drwxr-xr-x  3 root root 4096 Dec  3 01:55 my_project_20251203_015500_f7a8b3

(rdbg) system("ls -la #{File.join(project_dir, 'mrbgems')}")
# Verify mrbgems directory exists
```

#### Phase 4: Continue to Next Test

```
(rdbg) continue                       # Jump to next assertion or test
# Debugger continues, may hit another test

(rdbg) info locals                    # Show all local variables at current point
(rdbg) pp locals.keys                 # See variable names
=> [:tmpdir, :project_id, :output, :status, :project_dir]
```

#### Phase 5: Exit Debugger

```
(rdbg) quit                           # Exit debugger
(rdbg) q                              # Short form

# Output shows test results:
# 100% passed
# Coverage: ...
```

### Common Inspection Patterns

#### Pattern 1: Check Command Success

```
(rdbg) step                           # Execute: output, status = run_ptrk_command(...)
(rdbg) pp status                      # See full status object
=> #<Process::Status: pid 12345 exit 0>

(rdbg) pp status.class                # Check class
=> Process::Status

(rdbg) pp status.exitstatus           # Check numeric exit code
=> 0
```

#### Pattern 2: Inspect String Output

```
(rdbg) pp output                      # See full output
(rdbg) pp output.lines                # Split into lines
=> ["Creating project...\n", "Project initialized\n"]

(rdbg) pp output.include?("storage/home")  # Check for specific text
=> true

(rdbg) pp output.match?(/expected_pattern/)  # Regex match
=> true
```

#### Pattern 3: File System Verification

```
(rdbg) system("find #{tmpdir} -type f")     # Find all files
(rdbg) system("find #{tmpdir} -type d")     # Find all directories
(rdbg) system("stat #{File.join(project_dir, 'storage/home')}")  # Check permissions
(rdbg) system("file #{File.join(project_dir, 'mrbgems/applib/mrblib/applib.rb')}")  # Check file type
```

#### Pattern 4: Multiline Inspection

```
# For complex objects, use pp with width adjustment:
(rdbg) pp output.lines.first(10)      # Show first 10 lines

# For arrays:
(rdbg) Dir.glob(File.join(project_dir, "**/*")).first(20).each { |f| puts f }
```

### Troubleshooting During Debug Session

#### Issue: Test Fails at Assertion

```
# You see: assert_match(/pattern/, output)  # Fails

(rdbg) pp output                      # See what's actually in output
(rdbg) puts output                    # Pretty print it
(rdbg) pp output.inspect              # Show escaped version
```

#### Issue: File Not Found

```
# You see: assert File.exist?(expected_file)  # Fails

(rdbg) pp File.exist?(expected_file)  # Check existence
(rdbg) system("ls -la #{File.dirname(expected_file)}")  # List parent dir
(rdbg) system("find #{tmpdir} -name '*applib*'")  # Search for file
```

#### Issue: Command Failed

```
# You see: assert status.success?  # Fails

(rdbg) pp status.exitstatus          # See exit code
(rdbg) pp output                     # See error message
(rdbg) system("#{ptrk_path} new --help")  # Check command syntax
```

### Advanced: Setting Conditional Breakpoints

Instead of stepping through manually, add conditional breaks:

```ruby
# In test code (temporarily):
if tmpdir.empty?
  binding.break  # Break only if tmpdir is empty
end
```

Then run normally and debugger starts at condition.

### Advanced: Post-Mortem Analysis

If test fails without debugger:

```bash
# 1. Add binding.break at strategic point
# 2. Re-run test normally
bundle exec ruby -Itest test/scenario/new_scenario_test.rb

# 3. Debugger starts at binding.break if condition hit
(rdbg) pp <variables>
(rdbg) system(...)
```

## Quick Reference: Common Debug Commands

| Command | Short | Purpose |
|---------|-------|---------|
| `step` | `s` | Step into next line (enter method calls) |
| `next` | `n` | Step over next line (skip method calls) |
| `continue` | `c` | Continue until next breakpoint |
| `finish` | `f` | Continue until method returns |
| `list` | `l` | Show code context (5 lines each way) |
| `info locals` | | Show all local variables |
| `pp var` | | Pretty-print variable |
| `help` | `h` | Show all commands |
| `quit` | `q` | Exit debugger |

## Notes

1. **Interactive Mode**: Debug gem is designed for interactive exploration
2. **Performance**: Stepping through tests is slower than normal execution
3. **Test Isolation**: Each test uses tmpdir, so file changes are isolated
4. **Command Execution**: ptrk commands create real projects in tmpdir
5. **Cleanup**: tmpdir is automatically cleaned up when test exits

## See Also

- `.claude/docs/step-execution-guide.md` — Complete step execution guide
- `CLAUDE.md` — Debugging workflow integration with TDD cycle
- `test_helper.rb` — Test helper functions (generate_project_id, run_ptrk_command, etc.)
