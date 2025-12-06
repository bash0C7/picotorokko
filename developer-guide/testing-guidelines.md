# Testing Guidelines

## Test Coverage

- ⚠️ NEVER lower `minimum_coverage` threshold in test_helper.rb
- ✅ When coverage falls below threshold, ALWAYS expand tests to meet the requirement
- ✅ Aim for comprehensive test coverage of new features and bug fixes
- ✅ Focus on both line coverage and branch coverage when writing tests
- 🎯 Current baseline: Line coverage ≥ 80%, Branch coverage ≥ 50%
- 🎯 Long-term goal: Incrementally improve coverage through additional tests

## Development vs CI

- 🚀 **Development** (`rake` or `rake test`): Quick feedback, coverage measured but not enforced
- 🔍 **CI** (`rake ci`): Thorough validation, coverage thresholds enforced via ENV["CI"]
- ✅ Development workflow optimized for speed and iteration
- ✅ CI workflow optimized for quality assurance
- 🔧 Available manual tasks: `rake rubocop` (linting, integrated into development cycle)

## RuboCop Integration (Quality Gate)

RuboCop is NOT optional — it is a quality gate equal to passing tests.

### Development Cycle

```
Red → Green (rubocop -A) → Refactor (fix remaining) → Commit
```

**Phase: Green (Automatic)**
- After test passes: Run `bundle exec rubocop -A` to auto-fix violations
- Auto-fixed violations: Layout, Style, Lint (non-breaking)
- Re-run tests to ensure auto-fixes don't break anything

**Phase: Refactor (Manual)**
- Fix remaining violations: Metrics (complexity, length), etc.
- Goal: Understand WHY violation exists, not just suppress it
- Result: 0 offenses before commit

### Quality Gates (ALL must pass)

```bash
# 1. Tests pass
bundle exec rake test
✅ Expected: All tests pass

# 2. RuboCop: 0 violations
bundle exec rubocop
✅ Expected: "26 files inspected, 0 offenses"

# 3. Coverage thresholds (CI only)
bundle exec rake ci
✅ Expected: Line: ≥ 80%, Branch: ≥ 50%

# 4. Documentation updated (if implementation changed)

📝 Review which documents need updating:
- **Command/behavior changed?** → Update SPEC.md + README.md
- **Templates changed?** → Update docs/MRBGEMS_GUIDE.md + docs/CI_CD_GUIDE.md
- **Public API changed?** → Update rbs-inline annotations + `steep check`
- Reference: `.claude/docs/documentation-automation-design.md` for full mapping
```

### When RuboCop Reports Violations

**Do NOT**:
- 🚫 Add `# rubocop:disable` comments
- 🚫 Lower RuboCop thresholds in `.rubocop.yml`
- 🚫 Create `.rubocop_todo.yml` entries

**Do**:
1. Run `bundle exec rubocop -A` for auto-fixes
2. Manually fix remaining violations through refactoring
3. If stuck → Ask user for guidance on refactoring approach

**Example: High Complexity**
```ruby
# ❌ WRONG (adding disable comment)
def process_device  # rubocop:disable Metrics/CyclomaticComplexity
  # ... 10+ conditions ...
end

# ✅ RIGHT (refactor into smaller methods)
def process_device
  return unless valid_device?
  return unless connected?

  configure_device
  execute_tasks
end

def valid_device?
  # ... validation logic ...
end

def connected?
  # ... connection logic ...
end
```

## Absolutely Forbidden Practices

### 🚫 NEVER: Add RuboCop Disable Comments

```ruby
# ❌ COMPLETELY FORBIDDEN
def method_name  # rubocop:disable Metrics/CyclomaticComplexity
end

method = value  # rubocop:disable Style/UnusedVariableAssignment
```

**Exception**: NONE. Always refactor instead.

**What to do**: Refactor to improve code structure for everyone.

### 🚫 NEVER: Write Fake Tests

Tests that don't verify real behavior:

```ruby
# ❌ COMPLETELY FORBIDDEN: No real assertion
def test_initialize
  device = Device.new
  assert_nothing { device.initialize }
end

# ❌ COMPLETELY FORBIDDEN: Test that always passes
def test_exists
  assert true
end

# ❌ COMPLETELY FORBIDDEN: Dummy setup without verification
def test_device
  device = Device.new
  assert_equal device, device  # Trivial assertion
end
```

**What to do**: Write meaningful tests that verify actual behavior.

```ruby
# ✅ RIGHT: Test real behavior
def test_device_initialization
  device = Device.new("esp32", port: "/dev/ttyUSB0")
  assert_equal "esp32", device.board
  assert_equal "/dev/ttyUSB0", device.port
end

# ✅ RIGHT: Test error conditions
def test_device_rejects_invalid_board
  assert_raises(ArgumentError) do
    Device.new("invalid_board")
  end
end
```

### 🚫 NEVER: Lower Coverage Thresholds

```ruby
# ❌ COMPLETELY FORBIDDEN
minimum_coverage line: 60, branch: 30

# ✅ RIGHT: Maintain high standards
minimum_coverage line: 80, branch: 50
```

**When coverage drops**:
1. Identify uncovered code
2. Write tests to cover it
3. If tests don't make sense → Code is likely dead and should be removed
4. If uncertain → Ask user for guidance

### 🚫 NEVER: Commit with RuboCop Violations

```bash
# ❌ COMPLETELY FORBIDDEN
bundle exec rubocop  # Shows 5 offenses
git add .
git commit -m "Add feature"

# ✅ RIGHT: Verify all gates pass
bundle exec rake ci  # Tests + RuboCop + Coverage
# All pass ✅
git add .
git commit -m "Add feature"
```

## When to Ask User for Guidance

**MUST ask** in these scenarios:

1. **Refactoring direction unclear**
   ```
   "Method X is 45 lines (MethodLength violation).
   Should I: (A) Split into 3 helper methods,
   (B) Extract to separate class, or (C) Other?
   What aligns with your architecture?"
   ```

2. **Test coverage gap is legitimate**
   ```
   "Uncovered code is error handling for rare case X.
   Adding test requires mocking 5 dependencies.
   Should I: (A) Add comprehensive test,
   (B) Mark as acceptable gap, or (C) Refactor?
   Your call."
   ```

3. **RuboCop violation has trade-offs**
   ```
   "Cyclomatic complexity triggered by 4 distinct error types.
   Each type requires different handling.
   Should I: (A) Accept higher complexity,
   (B) Refactor with intermediate methods, or (C) Other?
   Design decision needed."
   ```

## Development Workflow

See `.claude/docs/tdd-rubocop-cycle.md` for detailed micro-cycle:
- Red: Write failing test
- Green: Minimal code + `rubocop -A`
- Refactor: Improve + fix remaining violations
- Commit: Only when all gates pass

See `.claude/skills/project-workflow/SKILL.md` for macro-cycle:
- How to loop micro-cycles until task complete
- When to update TODO.md
- When to ask for user verification

---

## Coverage Improvement Strategy (Advanced)

### Branch Coverage Gap Analysis

**Critical Finding**: Line coverage and branch coverage are very different metrics:
- **Line coverage** = Did the line execute? (easier to achieve, ~65%)
- **Branch coverage** = Did BOTH sides of conditional execute? (harder to achieve, ~35%)

### High-Impact Coverage Gaps

Identify and prioritize untested code paths in this order:

#### 1. **Error Handling Paths (Highest Priority)**

```ruby
# ❌ Common pattern with 0% branch coverage
unless Dir.exist?(cache_path)
  raise "Error: Cache not found"  # ← Branch NOT tested
end
```

**Test strategy**: Create scenario where the condition is TRUE
```ruby
test "raises error when cache is missing" do
  # Setup: Don't create cache_path
  assert_raise(RuntimeError) do
    Pra::Commands::Build.start(['setup', 'test-env'])
  end
end
```

#### 2. **Conditional File Operations**

```ruby
# ❌ Only testing the "directory exists" branch
if File.symlink?(current_link)
  target = File.readlink(current_link)  # ← Tested
else
  puts 'No current environment'  # ← NOT tested
end
```

**Test strategy**: Test both branches
- When symlink EXISTS (true branch)
- When symlink DOESN'T EXIST (false branch)

#### 3. **Method Delegation and Edge Cases**

```ruby
# ❌ method_missing with low branch coverage
def method_missing(method_name, *args)
  if method_name.to_s.start_with?('_')
    super  # ← NOT tested (private method handling)
  else
    delegate_to_rake(method_name)  # ← Tested
  end
end
```

**Test strategy**: Call with underscore prefix, verify it raises NoMethodError

### Coverage Analysis Workflow

**Before writing tests**, run:
```bash
bundle exec rake ci
grep 'branch-rate="0' coverage/coverage.xml
```

This shows you exactly which files have 0% branch coverage.

**Example output** (from actual session):
```
lib/picotorokko/commands/env.rb: 0% branch coverage
lib/picotorokko/commands/patch.rb: 0% branch coverage
lib/picotorokko/commands/rubocop.rb: 0% branch coverage
```

### Common Patterns to Test Both Branches

| Pattern | True Branch | False Branch |
|---------|------------|--------------|
| `if File.exist?(path)` | Path exists | Path doesn't exist |
| `unless Dir.exist?(dir)` | Dir missing | Dir exists |
| `if env_name == 'current'` | Env is 'current' | Env is explicit name |
| `unless condition` | Condition false | Condition true |
| `if config.nil?` | Config is nil | Config exists |

### Test Template for Branch Coverage

```ruby
# ❌ Pattern that leaves branches untested
test "setup works with caches" do
  setup_caches
  output = capture_stdout { cmd.start(['setup']) }
  assert_match(/success/, output)
end

# ✅ Pattern that tests both branches
test "setup works when caches exist" do
  setup_caches
  output = capture_stdout { cmd.start(['setup']) }
  assert_match(/success/, output)
end

test "setup raises error when caches missing" do
  # Don't setup caches
  assert_raise(RuntimeError) do
    capture_stdout { cmd.start(['setup']) }
  end
end
```

### Tracking Coverage Improvements

After adding tests, verify impact:
```bash
# Before
bundle exec rake ci
# → Line: 65.03%, Branch: 34.45%

# After each test addition
bundle exec rake ci
# → Line: 65.10%, Branch: 35.20%
```

Document progress in commit message:
```
Add tests for build.rb cache validation

- Added test for R2P2-ESP32 cache missing (line 44-46)
- Added test for symlink not existing (line 19-22)
- Coverage improvement: 65.03% → 65.10% line, 34.45% → 35.20% branch
- Focused on error handling paths (highest impact)
```

### Session Insights (Actual Data)

From analyzing 8 command files (November 2024):

| File | Line Coverage | Branch Coverage | Gap Reason |
|------|---|---|---|
| `cache.rb` | 98.53% | 94.44% | Nearly complete |
| `ci.rb` | 94.29% | 83.33% | Missing edge cases |
| `mrbgems.rb` | 98.33% | 50% | One directory-exists branch |
| `device.rb` | 94.12% | 71.43% | Error path branches |
| `build.rb` | 89.12% | 59.38% | Multiple cache checks |
| `rubocop.rb` | 25% | 0% | Minimal test coverage |
| `patch.rb` | 10.71% | 0% | Minimal test coverage |
| `env.rb` | 15.49% | 0% | Minimal test coverage |

**Key insight**: Files with low branch coverage need MORE tests per method, not just any test. Each error condition branch requires a dedicated test case.
