# Project Status - v0.1.0

## Implementation Notes

### Dependencies for Future Implementation

**For E2E Device Testing Framework (v0.2.0)**:
- Add to `picotorokko.gemspec` (when production E2E code is implemented):
  ```ruby
  spec.add_development_dependency "serialport", "~> 1.3"  # Serial port communication for device testing
  ```
- Note: Currently in gemspec from POC trial; remove until production implementation ready

### Key Design Decisions

#### 1. Environment Name Format: YYYYMMDD_HHMMSS
- **Pattern**: `^\d+_\d+$` (numbers_numbers only, no hyphens)
- **Generation**: `Time.now.strftime("%Y%m%d_%H%M%S")`
- **Validation**: All commands validate against this pattern
- **Current tracking**: `.picoruby-env.yml` stores which env is current

#### 2. Git Clone Failures
- **No retry**: Fatal error, terminate immediately
- **Reason**: Indicates network/permission issues that won't resolve with retry
- **User guidance**: Error message should direct to diagnostics

#### 3. RBS Parse Errors
- **Skip with warning**: Parse errors don't halt the entire env creation
- **Warning output**: Log warning to stderr for each failed RBS file
- **Reason**: A single malformed RBS file shouldn't break the entire env setup
- **Impact**: Missing methods from failed files won't be in JSON databases

#### 4. Git Submodule Structure
- **Three-level**: R2P2-ESP32 → components/picoruby-esp32 → picoruby
- **Initialization**: Use `--recursive --jobs 4` for parallel submodule fetching
- **Commit checkout**: Each level must be checked out independently
- **Push safety**: Disable push on all three levels via `git remote set-url --push origin no_push`

#### 5. Directory Separation
- **`.ptrk_env/{env}/`**: Read-only cache from git clones with submodules
- **`.ptrk_build/{env}/`**: Working directory for patching and building
- **Why separate**: Enables cache reuse, prevents accidental env modification

#### 6. RBS Method Extraction Pattern
- **Source**: picoruby.github.io/lib/rbs_doc/class_formatter.rb
- **Parser**: `RBS::Parser.parse_signature(File.read(path))`
- **AST nodes**: `RBS::AST::Declarations::Class/Module` and `RBS::AST::Members::MethodDefinition`
- **Filtering**: Skip methods with `@ignore` annotation or `@private` comment
- **Classification**: Use `member.kind` to separate `:instance` and `:singleton` methods

#### 7. JSON Database Structure
```json
{
  "ClassName": {
    "instance": ["method1", "method2"],
    "singleton": ["class_method1", "class_method2"]
  }
}
```
- **Sorted**: Method names alphabetically within each category
- **Used by**: RuboCop custom cop UnsupportedMethod detection

#### 8. Backwards Compatibility
- **ptrk rubocop command**: Complete removal (Phase 3f), no deprecation needed
- **Existing YAML**: Auto-migration handled by default env setter
- **Test impact**: All tests must use new `.ptrk_env` directory name

### Testing Strategy

#### MockExecutor for Git Operations
- Stub all system() calls in tests
- Return successful exit codes by default
- Override specific calls for failure scenarios
- Never actually clone/checkout in unit tests

#### Integration Tests for Submodules
- Use real git operations (git clone, submodule init/update)
- Test with temporary directories
- Verify submodule structure after clone
- Confirm push is disabled on all levels

#### RBS Parsing Tests
- Use fixture RBS files (simple class/method definitions)
- Test parse errors with malformed RBS
- Verify warning output when parse fails
- Test @ignore annotation filtering

---

## Test Execution

**Quick Reference**:
```bash
bundle exec rake              # Unit tests (fast feedback, ~1.3s)
bundle exec rake test:unit    # Unit tests only (same as above, ~1.3s)
bundle exec rake test         # Fast tests: unit → integration (~31s, scenario in CI only)
bundle exec rake test:all     # All tests: unit → integration → scenario (~35s)
bundle exec rake test:scenario # Scenario tests only (~0.8s)
bundle exec rake ci           # CI checks: all tests + RuboCop + coverage validation
bundle exec rake dev          # Development: RuboCop auto-fix + unit tests
```

**Step Execution for Scenario Tests** (using debug gem):
```bash
# Set breakpoint at specific line
rdbg -c -b "test/scenario/phase5_e2e_test.rb:30" -- bundle exec ruby -Itest test/scenario/phase5_e2e_test.rb

# Interactive mode
RUBY_DEBUG_OPEN=true bundle exec ruby -Itest test/scenario/phase5_e2e_test.rb

# Debug commands: step, next, continue, info locals, pp <var>
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
- Comprehensive error handling with validation

---

## Roadmap (Future Versions)

### Priority 1: Device Testing Framework (E2E)

**Status**: 🔬 Research Complete / POC Trial In Progress (IMMATURE)

**Research Documents**:
- [e2e-testing-with-esp-idf.md](.claude/docs/e2e-testing-with-esp-idf.md) — ESP-IDF Monitor 詳細分析と Ruby 実装ガイド
- [e2e-poc-analysis.md](.claude/docs/e2e-poc-analysis.md) — POC テスト失敗の原因分析

**Current Status** (2025-11-24):
- ✅ Python esp-idf-monitor: Verified working stably with actual device
- ✅ Research phase: Completed with comprehensive documentation
- ⏳ Production Implementation: Awaiting v0.2.0 milestone
- Event-driven architecture pattern documented and ready for implementation

**Key Learnings from Research**:
- Previous experimental approaches revealed critical requirements:
  - Correct reset logic: RTS controls EN (reset), DTR controls IO0 (boot mode)
  - Non-blocking I/O architecture superior to blocking I/O with long timeouts
  - Direct SerialPort access better than PTY wrapping of idf-monitor
- Python idf-monitor patterns analyzed; Ruby implementation requires adaptation:
  - SerialPort gem behavior differs from pyserial
  - Event-driven architecture with background thread recommended
  - Line buffering with timeout-based flush essential for reliable pattern matching

**Recommended Ruby Implementation Pattern** (Event-Driven):

```ruby
class E2EMonitor
  def initialize(port, baud = 150000)
    @port = SerialPort.new(port, baud)
    @port.read_timeout = 250  # ms (CHECK_ALIVE_FLAG_TIMEOUT)
    @port.flow_control = SerialPort::NONE
    @event_queue = Queue.new
    @output_lines = []
    @line_buffer = ""
  end

  def start(auto_reset: true)
    reset if auto_reset
    @running = true
    Thread.new { read_loop }
    main_loop
  end

  def reset
    @port.rts = 1   # RTS LOW (EN pin physically)
    sleep 0.005     # 5ms pulse
    @port.rts = 0   # RTS HIGH (EN pin physically)
  end

  def send_command(cmd)
    @port.write("#{cmd}\\r\\n")
  end

  def expect(pattern, timeout: 10)
    deadline = Time.now + timeout
    while Time.now < deadline
      return line if @output_lines.any? { |line| line.match?(pattern) }
      sleep 0.01
    end
    raise TimeoutError, "Pattern not found: #{pattern.inspect}"
  end

  private

  def read_loop
    while @running
      begin
        data = @port.read(1024)  # Uses 250ms timeout
        @event_queue.push([:serial, data]) if data
      rescue Errno::EAGAIN, Errno::EWOULDBLOCK
        sleep 0.01
      end
    end
  end

  def main_loop
    last_flush = Time.now
    while @running
      begin
        event = @event_queue.pop(true)  # Non-blocking
        handle_serial_data(event[1]) if event[0] == :serial
        last_flush = Time.now
      rescue ThreadError
        # Queue empty, flush incomplete line after 100ms
        if Time.now - last_flush > 0.1
          flush_line_buffer
          last_flush = Time.now
        end
        sleep 0.03  # 30ms polling interval
      end
    end
  end

  def handle_serial_data(data)
    @line_buffer += data
    lines = @line_buffer.split(/\\r?\\n/, -1)
    @line_buffer = lines.pop || ""
    @output_lines.concat(lines)
  end

  def flush_line_buffer
    return if @line_buffer.empty?
    @output_lines << @line_buffer
    @line_buffer = ""
  end
end
```

**Timeout Recommendations** (from esp-idf-monitor reference):
- SERIAL_READ_TIMEOUT: 250ms (pyserial CHECK_ALIVE_FLAG_TIMEOUT)
- LINE_FLUSH_TIMEOUT: 100ms (incomplete line buffer)
- MAIN_LOOP_POLL: 30ms (responsive polling)
- HARD_RESET_PULSE: 5ms (EN pin reset width)
- BOOTLOADER_DELAY: 100-150ms (IO0 sequence duration)

**Critical Implementation Requirements**:
- Direct `SerialPort` access (not PTY wrapping) for device control
- RTS-based reset for ESP32: RTS controls EN (reset pin)
  - Correct sequence: `rts = 1` (LOW physically) → 5ms pulse → `rts = 0` (HIGH physically)
  - DTR controls IO0 (boot mode), not reset
- Background thread with event queue for responsive `expect()` behavior (30ms polling)
- Non-blocking read architecture to avoid artificial delays
- Line buffering strategy: Accumulate data, split on `\r?\n`, flush incomplete lines after 100ms

**Production Implementation Strategy**:

Based on research analysis, the Event-Driven Monitor pattern (shown above) is the recommended approach:
1. **Architecture**: Background thread for serial reading + event queue + 30ms polling loop
2. **Reset Control**: RTS-based (EN pin) with 5ms pulse: `rts = 1` → 5ms → `rts = 0`
3. **Bootloader Mode**: DTR-based sequence for IO0 control (100ms duration)
4. **Line Handling**: Accumulate data, split on `\r?\n`, flush at 100ms timeout
5. **Timeouts**:
   - Serial read: 250ms (check alive flag)
   - Main loop poll: 30ms (responsive)
   - Line flush: 100ms (incomplete line)

**Design Principles**:
- ✅ Event queue with background thread for non-blocking reads
- ✅ Proper line buffering with timeout-based flush
- ✅ RTS control for device reset (not DTR)
- ✅ 30ms main loop polling interval
- ❌ Avoid blocking `read()` with long timeouts
- ❌ Avoid PTY wrapping (use direct SerialPort)
- ❌ Avoid accumulating output without line boundaries

**Implementation Roadmap**:
1. **Create `lib/picotorokko/e2e/monitor.rb`** — Production-grade Monitor class (event-driven pattern)
2. **Add `serialport` gem** — Update Gemfile and .gemspec
3. **Create test helpers** — `test/helpers/e2e_helper.rb`
4. **Write E2E test suite** — `test/e2e/device_control_test.rb` with:
   - Device reset verification
   - Command send/receive with pattern matching
   - Bootloader mode entry
   - Error condition handling
5. **CI Integration**: Detect serial port availability, skip if unavailable
6. **Documentation**: Usage guide for E2E testing workflow

**Estimated**: v0.2.0

### Priority 1.5: Scenario Test E2E Conversion

**Status**: Planned

**Objective**: Convert 77 currently-omitted scenario tests to true end-to-end tests that execute actual `ptrk` commands

**Approach**:
- Replace MockExecutor-based tests with real command execution via `bundle exec bin/ptrk`
- Verify commands through filesystem state (file existence, content validation)
- Test exit codes explicitly for success/failure scenarios
- Maintain test isolation with independent tmpdir for each test
- Skip ESP-IDF-dependent tests (device build/flash) in CI when ESP-IDF unavailable

**Example Pattern**:
```ruby
def test_env_set_and_build_workflow
  Dir.mktmpdir do |tmpdir|
    Dir.chdir(tmpdir) do
      output, status = Open3.capture2e("bundle exec ptrk init my_project")
      assert status.success?, "ptrk init should succeed"
      assert File.exist?("my_project/.rubocop.yml"), "RuboCop config should be generated"
    end
  end
end
```

**Benefits**:
- Tests actual user-facing behavior, not internal implementation
- Eliminates hidden exit code 1 issues from mock interference
- Better test isolation and predictability
- Easier to understand and maintain

**Estimated**: v0.2.0 (after E2E framework is stable)

### Priority 2: Additional mrbgems Management
- **Status**: Planned
- **Objective**: Commands for generating, testing, publishing mrbgems
- **Estimated**: v0.2.0+

### Priority 3: CI/CD Templates
- **Status**: Planned
- **Objective**: Enhanced GitHub Actions workflow templates
- **Estimated**: v0.3.0+

### Priority 99: Prism AST Debug Injection (LOWEST PRIORITY)

**⚠️ REQUIRES SPECIAL INSTRUCTION FROM USER TO PROCEED**

- **Status**: Idea only
- **Objective**: Use Prism to dynamically inject debug breakpoints into test AST without modifying source
- **Approach**: Parse test files, inject `binding.break` at strategic points (assertions, command calls), execute transformed code
- **Note**: Current approach using `rdbg` command-line breakpoints is sufficient for scenario test stepping

### [TODO-VERIFY-1] Step Execution Verification for Scenario Tests

**Status**: ✅ COMPLETED (2025-12-03)

**Objective**: Establish regular step execution verification workflow for scenario tests

**Solution Implemented**:
1. **Debug Gem Installation**: Installed locally via `gem install debug`
2. **Step Execution Method**: Use `ruby -r debug -Itest` (better than `rdbg` command for PATH compatibility)
3. **Comprehensive Documentation**:
   - `.claude/docs/step-execution-guide.md` — 400+ line complete guide with examples
   - `CLAUDE.md` — Integrated debugging workflow with TDD cycle
   - `.claude/examples/debugging-session-example.md` — Real-world interactive session example
4. **Working Example**: `.claude/examples/step-execution-example.rb` (demonstrative script)
5. **Specialized Subagent**: `.claude/agents/debug-workflow.md` — Autonomous debugging assistant

**Subagent Features** (NEW):
- Analyzes test structure and identifies failing assertions
- Guides interactive step execution through Ruby debugger
- Interprets debug output, variable values, file system states
- Teaches four core debugging patterns with examples
- Integrates with t-wada TDD cycle
- Uses Haiku model for fast, cost-effective pattern-based guidance
- References official guides and test helpers automatically

**Key Learnings**:
- `ruby -r debug` is more reliable than `rdbg` command (PATH issues)
- Step execution best used for: understanding expected behavior (Green phase), refactoring verification (Refactor phase)
- Test helpers (`generate_project_id`, `run_ptrk_command`) integrate seamlessly with debugger
- File system assertions (Dir.exist?, File.exist?) are most efficiently debugged with `system("ls", "find", etc.)`
- Multiple breakpoints can be set with multiple `-b` flags
- Subagent architecture provides superior context and autonomous guidance compared to skills

**Usage Quick Start**:
```bash
# 1. Install debug gem locally (once)
gem install debug

# 2. Run test with step execution
ruby -r debug -Itest test/scenario/new_scenario_test.rb

# 3. At debugger prompt, use:
(rdbg) step       # Step to next line
(rdbg) pp var     # Print variable
(rdbg) help       # Show all commands

# 4. OR invoke debugging subagent:
# "Use the debug-workflow subagent to help me debug test/scenario/new_scenario_test.rb"
```

**For Detailed Guide**: See `.claude/docs/step-execution-guide.md`

**For Interactive Example**: See `.claude/examples/debugging-session-example.md`

**For Subagent Details**: See `AGENTS.md` section "Specialized Subagents" → "debug-workflow Subagent"

**Integration**: CLAUDE.md includes complete TDD cycle integration

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
- ✅ Tests: 100% success rate
- ✅ RuboCop: 0 violations
- ✅ Coverage: Targets met (≥85% line, ≥60% branch)
- ✅ Type checking: Steep validation passing
- ✅ Documentation: Updated with code changes

---

## Known Limitations & Future Work

1. **Device Testing**: Research complete; ready for production implementation
   - **Research Summary**: Event-driven architecture with background thread + queue is the recommended approach
   - **Key Findings**:
     - RTS-based reset (EN pin) is correct control mechanism (not DTR)
     - 30ms main loop polling required for responsive behavior
     - Event queue decouples reading from processing for robustness
     - 250ms serial read timeout + 100ms line flush timeout optimal
   - **Design Lessons**: Blocking I/O and PTY wrapping approaches proved inadequate; direct SerialPort with event queue required
   - **Production Path**: Implement Event-Driven Monitor class (pattern documented in Priority 1 above) for v0.2.0
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

## Performance Notes

### Test Execution Performance
- **Parallel execution**: Enabled with multiple workers
- **SimpleCov**: HTMLFormatter in dev, CoberturaFormatter in CI
- **Branch coverage**: CI-only (disabled in dev for speed)

**Monitor with**:
```bash
time bundle exec rake test
```
