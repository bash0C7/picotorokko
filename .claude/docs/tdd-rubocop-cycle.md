# TDD + RuboCop Development Cycle

**Integration of Tidy First (Kent Beck) with t-wada style TDD and RuboCop quality gates**

## Core Philosophy

This document integrates three practices:

1. **Tidy First** (Kent Beck): Small, frequent refactoring steps that improve code understanding
2. **t-wada style TDD**: Red-Green-Refactor micro-cycles (1-5 minutes per iteration)
3. **RuboCop Quality Gates**: Code quality and style are not optional

### Key Principle

> "Tidy first, then add functionality" — Kent Beck
>
> Small changes compound into massive improvements without risk.

---

## The Development Micro-Cycle (1-5 Minutes)

```
┌─────────┐    ┌──────────┐    ┌──────────┐    ┌────────┐
│ RED     │ → │ GREEN    │ → │REFACTOR  │ → │COMMIT │
└─────────┘    └──────────┘    └──────────┘    └────────┘
    ↓              ↓                ↓
  Write        Min code +       Tidy code +
  failing      rubocop -A       RuboCop fix
  test
```

### Phase 1: RED (Write Failing Test)

**Goal**: Define the behavior you want

- Write ONE test that fails
- Focus on behavior, not implementation
- Keep test simple and readable

```ruby
# test/commands/device_test.rb

def test_resolve_env_name_with_valid_env
  env_name = Pra::Commands::Device.new.send(:resolve_env_name, "prod")
  assert_equal "production", env_name
end
```

**Verify**: `bundle exec rake test` shows 1 failure

---

### Phase 2: GREEN (Minimal Code + Auto-Fix RuboCop)

**Goal**: Make the test pass with minimal code

```ruby
# lib/pra/commands/device.rb

def resolve_env_name(short_name)
  { "prod" => "production", "dev" => "development" }[short_name]
end
```

**Steps**:

1. Write minimum code to pass test
2. Run tests: `bundle exec rake test` → Should pass ✅
3. Auto-fix RuboCop: `bundle exec rubocop -A`
4. Run tests again to ensure auto-fixes don't break anything

**Example RuboCop auto-fixes**:
- Line length: Automatically splits long lines
- Missing frozen string literal: Automatically adds
- Indentation: Automatically corrects
- String quotes: Automatically converts to double quotes

---

### Phase 3: REFACTOR (Improve + Fix Remaining RuboCop)

**Goal**: Improve code quality while keeping tests green

**Refactoring ideas (from Tidy First)**:
- Extract magic values to constants
- Simplify guard clauses
- Remove dead code
- Create symmetry in similar patterns
- Extract complex conditions to named variables

```ruby
# lib/pra/commands/device.rb

# BEFORE (minimal Green code)
def resolve_env_name(short_name)
  { "prod" => "production", "dev" => "development" }[short_name]
end

# AFTER (after Refactor phase)
ENVIRONMENT_ALIASES = {
  "prod" => "production",
  "dev" => "development"
}.freeze

def resolve_env_name(short_name)
  ENVIRONMENT_ALIASES[short_name]
end
```

**Steps**:

1. Refactor for clarity (following Tidy First principles)
2. Run tests: `bundle exec rake test` → Should still pass ✅
3. Run RuboCop: `bundle exec rubocop` → Check for violations
4. Manually fix remaining violations
5. **Key**: Understand WHY each violation exists; don't just silence it

**Example manual fixes**:
- Complexity too high? Refactor method into smaller pieces
- Method too long? Extract helper methods
- ABC size too large? Simplify logic

**🚫 NEVER do this**:
```ruby
# ❌ WRONG: Do not add # rubocop:disable
def overly_complex_method  # rubocop:disable Metrics/CyclomaticComplexity
  # ... complex code ...
end

# ✅ RIGHT: Refactor to multiple methods
def main_method
  step1
  step2
  step3
end

def step1
  # ...
end

def step2
  # ...
end

def step3
  # ...
end
```

---

### Phase 4: VERIFY & COMMIT

**Goal**: Ensure all quality gates pass before committing

**Quality Gates** (ALL must pass):

```bash
# 1. Unit tests pass
bundle exec rake test
✅ Expected: All tests pass

# 2. RuboCop violations: 0
bundle exec rubocop
✅ Expected: "26 files inspected, 0 offenses"

# 3. Coverage meets thresholds (in CI)
bundle exec rake ci
✅ Expected: Line: ≥ 80%, Branch: ≥ 50%
```

**Only commit when**:
- ✅ All tests pass
- ✅ RuboCop shows 0 offenses
- ✅ Coverage meets thresholds
- ❌ No `# rubocop:disable` comments added

**Commit message**:
```
Imperative mood, explains WHY

Example:
- ✅ "Extract environment name resolution for clarity"
- ✅ "Remove unused hash duplicate in device command"
- ❌ "Fixed stuff"
```

---

## Macro-Cycle: Task Completion

```
1. Check TODO.md for priorities
2. Review code structure (use explore agent)
3. Repeat micro-cycle until task complete
   - Red → Green → Refactor → Commit (1-5 min each)
4. Update TODO.md (remove completed task)
5. User verifies with full test suite
```

---

## Absolutely Forbidden Practices

### 🚫 NEVER Add RuboCop Ignore Comments

```ruby
# ❌ WRONG
def complex_method  # rubocop:disable Metrics/CyclomaticComplexity
  if condition_a
    if condition_b
      if condition_c
        do_something
      end
    end
  end
end

# ✅ RIGHT: Refactor to simpler structure
def complex_method
  return unless condition_a
  return unless condition_b
  return unless condition_c
  do_something
end
```

**Why**: Ignoring violations hides problems. Refactoring improves code for everyone.

### 🚫 NEVER Write Fake Tests

```ruby
# ❌ WRONG: Fake test (no real assertion)
def test_device_initialization
  device = Device.new
  assert_nothing { device.initialize }
end

# ❌ WRONG: Test that always passes
def test_device_exists
  assert true
end

# ✅ RIGHT: Test actual behavior
def test_device_initialization
  device = Device.new("esp32")
  assert_equal "esp32", device.name
end
```

**Why**: Fake tests don't catch bugs. Real tests verify behavior.

### 🚫 NEVER Lower Coverage Thresholds

```ruby
# ❌ WRONG in test/test_helper.rb
minimum_coverage line: 60, branch: 30  # Too low!

# ✅ RIGHT
minimum_coverage line: 80, branch: 50  # Maintain high standards
```

**When coverage drops**:
1. Identify uncovered code
2. Write tests to cover it
3. If tests don't make sense → Dead code should be removed
4. If stuck → Ask user for guidance

### 🚫 NEVER Commit with RuboCop Violations

```bash
# ❌ WRONG: Commit despite violations
bundle exec rubocop  # Shows 5 offenses
git add .
git commit -m "Add new feature"

# ✅ RIGHT: Fix violations before commit
bundle exec rubocop -A  # Auto-fix
bundle exec rubocop     # Check remaining
# ... manually fix remaining violations ...
bundle exec rake ci     # Verify all gates pass
git add .
git commit -m "Add new feature"
```

---

## When to Ask for User Guidance

You MUST ask the user for help in these scenarios:

1. **RuboCop violation that doesn't have an obvious fix**
   ```
   Question: "The `validate_config` method is now 35 lines
   and triggers MethodLength violation. How should I split it?
   Option A: Extract validation into separate methods
   Option B: Move to a separate Validator class
   Which approach aligns with the codebase design?"
   ```

2. **Test behavior unclear or controversial**
   ```
   Question: "Should the `execute_with_esp_env` method in
   the CI environment skip ESP-IDF sourcing (returning no-op)
   or raise an error? This affects how we test integration scenarios."
   ```

3. **Trade-off between simplicity and completeness**
   ```
   Question: "Coverage is at 78% line coverage (target 80%).
   The 2% gap is from error handling edge cases that rarely
   occur. Should I add tests for them or accept the gap?
   Reasoning: [explain the choice]"
   ```

4. **Refactoring direction unclear**
   ```
   Question: "The show_available_tasks method handles multiple
   concerns: validation, environment detection, and task listing.
   Should I split it into 3 methods or reorganize the command structure?"
   ```

---

## Real-World Example: Complete Micro-Cycle

### Task: Add command to list available tasks for a device

**Phase 1: RED**
```ruby
# test/commands/device_test.rb
def test_show_available_tasks_displays_r2p2_tasks
  output = capture_stdout do
    device_cmd = Pra::Commands::Device.new
    device_cmd.invoke(:tasks, ["test_env"])
  end

  assert_includes output, "build"
  assert_includes output, "monitor"
end
```

Run: `bundle exec rake test` → ❌ FAIL

---

**Phase 2: GREEN**
```ruby
# lib/pra/commands/device.rb
def tasks(env_name = nil)
  puts "Available tasks:"
  puts "  build"
  puts "  monitor"
end
```

Run: `bundle exec rake test` → ✅ PASS
Run: `bundle exec rubocop -A` → Auto-fixes applied

---

**Phase 3: REFACTOR**
```ruby
# lib/pra/commands/device.rb

AVAILABLE_TASKS = ["build", "monitor", "flash", "clean"].freeze

def tasks(env_name = nil)
  show_available_tasks(env_name)
end

alias_method :help, :tasks

private

def show_available_tasks(env_name)
  resolved_env = resolve_env_name(env_name)

  puts "Available tasks for #{resolved_env}:"
  AVAILABLE_TASKS.each { |task| puts "  #{task}" }
end

def resolve_env_name(env_name)
  return "default" if env_name.nil?
  ENV_ALIASES[env_name]
end
```

Run: `bundle exec rake test` → ✅ PASS
Run: `bundle exec rubocop` → ✅ 0 violations
Run: `bundle exec rake ci` → ✅ All gates pass

---

**Phase 4: COMMIT**
```
Add tasks command to device for improved discoverability

Users can now run 'pra device tasks' to see available commands
for a specific environment. This reduces cognitive load when
exploring new commands.
```

---

## Integration with Project Workflow

See `.claude/skills/project-workflow/SKILL.md` for macro-cycle integration:
- How to loop this micro-cycle until task completion
- When to check TODO.md
- When to use explore agent
- When to commit and when user verifies

---

## References

- **Tidy First?** Kent Beck, 2023 — On small, frequent refactoring
- **Test-Driven Development: By Example** Kent Beck, 2003 — Original TDD patterns
- **Growing Object-Oriented Software** Steve Freeman & Nat Pryce, 2009 — Practical TDD
- **RuboCop Documentation**: https://rubocop.org/ — Style guide and violation details
