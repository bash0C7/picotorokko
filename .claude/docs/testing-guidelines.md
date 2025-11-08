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
