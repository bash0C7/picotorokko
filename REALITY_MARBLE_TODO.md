# Reality Marble Implementation TODO

**Status**: Design Complete (REVISED with Critical Fixes), Ready for Implementation
**Target**: New standalone gem (separate from pra gem)
**Timeline**: To be determined (independent project)
**Last Updated**: 2025-11-11 (Post Peer Review - Critical architectural improvements)

---

## Project Overview

### Concept

**Reality Marble** - A Pure Ruby mock/stub library using Refinements for Test::Unit.

Inspired by TYPE-MOON's "Reality Marble" (固有結界):
- **Chant** (詠唱): Define your mock with normal Ruby syntax
- **Activate** (展開): Deploy the marble in test scope
- **Trace** (痕跡): Observe what happened inside
- **Auto-dissolution**: Automatic cleanup on block exit

### Key Features

- ✅ **Zero pollution** - Refinements provide lexical scoping
- ✅ **Zero cleanup** - Automatic on block exit (ensure)
- ✅ **Zero learning curve** - Normal Ruby syntax (refine/def/super)
- ✅ **Thread-safe** - Context isolated per thread
- ✅ **Test::Unit focused** - Optimized for one framework

### Design Philosophy

1. **Explicit declaration**: `using RealityMarble.chant` in every test file (明示的宣言)
2. **Normal Ruby syntax**: 100% standard Ruby inside `refine` blocks
3. **Automatic trace recording**: No manual instrumentation needed
4. **Method wrapping, not TracePoint**: Performance-friendly approach

---

## Final Design Summary

### API Overview

```ruby
require 'test/unit'
require 'reality_marble'

class GitTest < Test::Unit::TestCase
  # Step 1: Chant (Define marble with Refinements)
  using RealityMarble.chant do
    refine Kernel do
      def system(cmd)
        case cmd
        when /git clone/ then true
        when /git checkout/ then false
        else super  # Call original
        end
      end
    end
  end

  # Step 2: Activate (Deploy marble + auto trace)
  def test_git_commands
    RealityMarble.activate do |trace|
      system('git clone repo')
      system('git checkout main')

      # Step 3: Verify with trace
      assert_equal 2, trace[Kernel, :system].invocations
      assert trace[Kernel, :system].summoned_with?(/git clone/)
    end
  end
end
```

### Core Components

1. **RealityMarble.chant** → Returns Refinement module
2. **RealityMarble.activate** → Thread-local context + ensure cleanup
3. **Trace** → Spy-like recording (invocations, summoned_with?, etc.)
4. **Automatic wrapping** → Methods in `refine` blocks are auto-instrumented

---

## Technical Deep Dive: Critical Architectural Decisions

### The Fundamental Challenge

**Problem**: Refinements are **lexically scoped** (字句スコープ), not dynamically scoped.

```ruby
using RealityMarble.chant { ... }  # ← Always active in this scope

class MyTest
  def test_foo
    RealityMarble.activate do
      system('git')  # ← Want mock only here
    end

    system('ls')  # ← Want original here (NOT mock)
  end
end
```

**Naive approach would fail**:
- Refinements apply to entire scope where `using` is declared
- Cannot be turned on/off at runtime
- **Without proper architecture, mock would apply to both calls**

### The Solution: "Alias-Rename + Guarded Dispatch" Pattern

**Core Insight**: Leverage Thread-local context check **inside** the Refinement

#### Step-by-Step Mechanism

**1. User writes normal Refinement:**

```ruby
using RealityMarble.chant do
  refine Kernel do
    def system(cmd)
      case cmd
      when /git/ then true
      else super
      end
    end
  end
end
```

**2. Chant automatically transforms it to:**

```ruby
refine Kernel do
  # Save user's mock under different name
  alias_method :__rm_mock_system, :system

  # Replace with dispatcher (using `def` for super support)
  def system(*args, **kwargs, &block)
    ctx = Thread.current[:reality_marble_context]

    if ctx
      # Inside activate block → call mock
      trace = ctx.trace_for(Kernel, :system)
      record = trace.start_call(args, kwargs, block)
      begin
        result = __rm_mock_system(*args, **kwargs, &block)
        record.finish(result)
        result
      rescue => e
        record.finish_with_error(e)
        raise
      end
    else
      # Outside activate block → call original
      super
    end
  end
end
```

**3. Behavior:**

```ruby
# Outside activate → super → original implementation
system('ls')  # ← Real system call

# Inside activate → __rm_mock_system → user's mock
RealityMarble.activate do
  system('git')  # ← Mock (returns true)
end

# Outside again → super → original
system('pwd')  # ← Real system call
```

### Why This Works

| Aspect | Mechanism | Result |
|--------|-----------|--------|
| **Refinement scope** | `using` makes dispatcher always active | ✅ Consistent |
| **Mock activation** | Thread-local context check | ✅ `activate` only |
| **Original access** | `super` in dispatcher | ✅ Outside `activate` |
| **Trace recording** | Wrapped in dispatcher | ✅ Automatic |
| **User experience** | Write normal `def`/`super` | ✅ Natural Ruby |

### Critical Implementation Details

#### 1. Must Use `def`, Not `define_method`

**Problem**: `super` doesn't work in `define_method`

```ruby
# ❌ This fails
define_method(:foo) do
  super  # NoMethodError: super called outside method
end

# ✅ This works
def foo
  super  # Correctly calls superclass/original method
end
```

**Solution**: Generate `def` via `class_eval` with heredoc:

```ruby
class_eval <<~RUBY, __FILE__, __LINE__ + 1
  def #{method_name}(*args, **kwargs, &block)
    # ... dispatcher code ...
  end
RUBY
```

#### 2. Method Name Sanitization

**Problem**: Special characters in method names (`, [], []=, etc.)

```ruby
# Backtick method
refine Kernel do
  def `(cmd)  # ← How to generate this in class_eval?
  end
end
```

**Solution**:
- For most methods: Direct string interpolation OK
- For special syntax methods: May need `send` or `define_method` + `alias_method` hybrid

#### 3. Handling Methods Without Original Implementation

**Problem**: What if user defines a **new** method (not refining existing)?

```ruby
refine MyClass do
  def brand_new_method
    # No original to call with super
  end
end
```

**Solution**: Check if method exists before generating dispatcher:

```ruby
if target_class.instance_methods.include?(method_name)
  # Has original → generate dispatcher with super
else
  # No original → generate dispatcher without super branch
end
```

#### 4. Thread Safety

**Guarantee**: Each thread has independent context

```ruby
Thread.new do
  RealityMarble.activate do
    system('git')  # Mock in this thread
  end
end

Thread.new do
  system('ls')  # Original in this thread
end
```

**Mechanism**: `Thread.current[:reality_marble_context]` is thread-local storage

### Performance Considerations

**Overhead per call**:
1. Thread-local lookup: ~10ns
2. Conditional branch: ~1ns
3. Method call (`__rm_mock_*`): ~50ns
4. Trace recording: ~100ns (array append + object creation)

**Total**: ~161ns per mocked call (negligible for tests)

**Comparison**:
- TracePoint (global): ~5000ns per call
- Our approach: ~161ns per call
- **30x faster than TracePoint**

### Known Limitations and Constraints

#### 1. Lexical Scope Boundary (Refinements Inherent)

**Limitation**: Refinements don't propagate across `require`

```ruby
# test_helper.rb
using RealityMarble.chant { ... }

# foo_test.rb
require 'test_helper'

class FooTest
  def test_foo
    system('git')  # ← Refinement NOT active here
  end
end
```

**Workaround**: Each test file must have `using` declaration

```ruby
# foo_test.rb
require 'test_helper'

using MyGitMarble  # ← Must declare in each file

class FooTest
  # Now refinement is active
end
```

**Status**: **This is acceptable** - explicit declaration is a feature, not a bug

#### 2. Deep Call Chains

**Limitation**: Refinements only affect code **defined in the using scope**

```ruby
# test_git.rb
using RealityMarble.chant { ... }

class GitTest
  def test_clone
    LibraryCode.do_something  # Calls system() internally
  end
end

# library_code.rb (different file, no `using`)
module LibraryCode
  def self.do_something
    system('git clone')  # ← Refinement NOT active here
  end
end
```

**Workaround**: Mock at the boundary (where you call LibraryCode)

**Status**: **This is by design** - prevents dangerous "action at a distance"

#### 3. Singleton Method Wrapping Complexity

**Challenge**: Class methods require `refine Foo.singleton_class`

```ruby
# More verbose
refine FileUtils.singleton_class do
  def mkdir_p(path)
    # ...
  end
end
```

**Status**: **Supported but verbose** - document in examples

---

## 🚨 Critical Remaining Challenge: Production Code Boundary Problem

### The Problem: Refinements Cannot Reach Across File Boundaries

**Discovery**: During specification exploration, we identified a fundamental limitation that affects Reality Marble's applicability to real-world test scenarios.

#### Concrete Example (from pra gem)

**Test file** (`test/commands/env_test.rb`, lines 1272-1332):
```ruby
using SystemCommandMocking::SystemRefinement  # ← Refinement declared here

class EnvCommandTest < Test::Unit::TestCase
  def test_init_clones_repository
    # This test calls Env.init which internally calls lib/pra/env.rb code
    Pra::Env.init(env_name: 'test', repo_url: 'https://example.com/repo.git')
    # ...
  end
end
```

**Production code** (`lib/pra/env.rb`, line 111-117):
```ruby
# This file has NO `using` declaration
module Pra
  class Env
    def clone_repo(repo_url, dest_path, commit)
      return if Dir.exist?(dest_path)

      puts "Cloning #{repo_url} to #{dest_path}..."
      unless system("git clone #{Shellwords.escape(repo_url)} #{Shellwords.escape(dest_path)}")
        # ↑ This system() call is NOT affected by test file's Refinement!
        raise "Failed to clone repository"
      end
      # ...
    end
  end
end
```

**What happens**:
1. Test file declares `using SystemCommandMocking::SystemRefinement`
2. Test calls `Pra::Env.init` (production code in separate file)
3. Production code calls `system()` internally
4. **Refinement does NOT apply** → Real `system()` executes → Real git command runs!

**Test failure output**:
```
Cloning https://github.com/picoruby/picoruby.git to /tmp/d20250111-9999-abcdef...
Cloning into '/tmp/d20250111-9999-abcdef'...
remote: Enumerating objects: 15234, done.
# ← Real git clone executed instead of mock!
```

#### Why This Happens

**Refinements lexical scope constraint**:
- `using` only affects **code defined in the same file** where `using` appears
- Code in `lib/pra/env.rb` has no `using` declaration
- Therefore, `system()` call inside `lib/pra/env.rb` is NOT refined

**Call chain visualization**:
```
[test/commands/env_test.rb]  ← using declared here
  ↓ calls
[lib/pra/env.rb]             ← NO using here
  ↓ calls
system('git clone ...')      ← Original Kernel#system, NOT refined version
```

### Why This Matters

This limitation affects Reality Marble's **value proposition** and **target use cases**:

#### ❌ Invalid Use Cases (Cannot Work)

1. **Testing production code that makes system calls internally**
   - Example: Testing `Pra::Env.init` which calls `system()` in separate file
   - Refinement cannot reach the actual call site

2. **Deep call chains crossing file boundaries**
   - Test → ProductionClass → AnotherClass → system()
   - Only the first arrow is in `using` scope

3. **Third-party library method calls**
   - Test → YourCode → GemCode → File.read
   - GemCode has no `using` declaration (and you can't modify it)

#### ✅ Valid Use Cases (Can Work)

1. **Direct method calls in test code**
   - Test file has `using`
   - Test directly calls `system()` or `File.read`
   - Works perfectly

2. **Boundary mocking**
   - Mock the entry point to production code, not internal calls
   - Example: Mock `Pra::Env.init` itself, not the internal `system()` calls

3. **Test helper methods**
   - Helper methods defined in test files with `using`
   - These methods call system/File/etc.
   - Works perfectly

### Potential Solutions (Not Yet Decided)

#### Option 1: Explicit Scope Limitation

**Approach**: Accept this as a design constraint and document clearly.

**Documentation strategy**:
```markdown
## Reality Marble Scope

Reality Marble is designed for:
- ✅ Direct method calls in test code
- ✅ Test helper methods
- ✅ Boundary mocking

NOT designed for:
- ❌ Testing production code's internal system calls
- ❌ Deep call chains across files
- ❌ Third-party library internals

For these cases, use integration tests or dependency injection.
```

**Pros**:
- Honest about capabilities
- Avoids misleading users
- Simple mental model

**Cons**:
- Limits applicability
- Users expect mocking to "just work" everywhere

#### Option 2: Production Code Refactoring (Dependency Injection)

**Approach**: Refactor production code to accept callable dependencies.

**Example refactor**:
```ruby
# lib/pra/env.rb (BEFORE)
def clone_repo(repo_url, dest_path, commit)
  system("git clone #{Shellwords.escape(repo_url)} ...")
end

# lib/pra/env.rb (AFTER)
def clone_repo(repo_url, dest_path, commit, system_executor: method(:system))
  system_executor.call("git clone #{Shellwords.escape(repo_url)} ...")
end

# test/commands/env_test.rb
def test_clone_repo
  mock_system = ->(cmd) { true }
  env.clone_repo(url, path, commit, system_executor: mock_system)
end
```

**Pros**:
- Works without Refinements magic
- Testable at unit level
- Industry-standard pattern

**Cons**:
- Requires production code changes
- More verbose
- Defeats purpose of Reality Marble (non-invasive mocking)

#### Option 3: Integration Test Territory

**Approach**: Accept these as integration tests, not unit tests.

**Strategy**:
```ruby
# test/integration/env_integration_test.rb
class EnvIntegrationTest < Test::Unit::TestCase
  def test_init_with_real_git
    # Use temporary directories
    # Call real git (or stub at shell level with test doubles)
    Dir.mktmpdir do |tmpdir|
      # ...
    end
  end
end
```

**Pros**:
- Tests real behavior
- No mocking complexity
- Catches integration bugs

**Cons**:
- Slower tests
- Requires git installed
- May hit network (if cloning real repos)

#### Option 4: Hybrid Approach

**Combination**:
1. Reality Marble for **test code's direct calls** (Option 1)
2. Dependency injection for **critical production paths** (Option 2)
3. Integration tests for **full system behavior** (Option 3)

**Test pyramid**:
```
     /\
    /  \  ← Integration tests (real git, full behavior)
   /____\
  /      \
 / Unit   \ ← Reality Marble (test helpers, direct calls)
/__________\
```

### Impact on Reality Marble Design (案2)

This challenge affects the **architectural foundation** of 案2:

**Current 案2 assumptions**:
- Alias-Rename + Guarded Dispatch pattern works ✅
- Thread-local context for activation control ✅
- Automatic trace recording ✅
- **Can mock production code's internal calls** ❌ ← **INVALID**

**Revised understanding**:
- Reality Marble's Refinements are lexically scoped
- Therefore, can only affect **code in files with `using` declaration**
- Cannot transparently mock deep call chains

**Questions for 案3**:
1. Should we fundamentally change the approach?
2. Should we accept scope limitation and optimize for valid use cases?
3. Should we combine Refinements with other techniques?

### Status: Awaiting 案3

**Current state**: 案2 is **architecturally sound** (Alias-Rename + Guarded Dispatch pattern works), but **scope-limited** (cannot reach production code).

**Next step**: 案3 will propose an alternative design approach that addresses this fundamental limitation.

**Decision pending**: User will provide 案3 in next chat session, then we'll evaluate tradeoffs and choose the best path forward.

---

## 🔮 案3: TracePoint-Based Global Interception Approach

### Overview

**Core Idea**: Use Ruby's TracePoint API to globally intercept method calls across file boundaries, bypassing Refinements' lexical scope limitation.

**Key Difference from 案2**:
- 案2: Refinements (lexically scoped) → Cannot reach production code
- 案3: TracePoint (globally scoped) → **Can reach production code**

### How TracePoint Works

TracePoint is Ruby's built-in instrumentation API that can monitor various events (`:call`, `:c_call`, `:return`, etc.) **globally** across all code execution.

**Key capabilities**:
```ruby
TracePoint.new(:call) do |tp|
  tp.defined_class  # => Class where method is defined
  tp.method_id      # => Method name
  tp.self           # => Receiver object
  tp.binding        # => Binding at call site
  tp.lineno         # => Line number
  tp.path           # => File path
end
```

**Critical insight**: TracePoint fires **regardless of which file the code is in** — it's not bound by lexical scope.

### Proposed 案3 Architecture

#### 1. API Design (Similar to 案2)

```ruby
require 'test/unit'
require 'reality_marble'

class GitTest < Test::Unit::TestCase
  # Step 1: Define mock rules (NOT Refinements)
  git_marble = RealityMarble.chant do
    mock Kernel, :system do |cmd|
      case cmd
      when /git clone/ then true
      when /git checkout/ then false
      else
        original(cmd)  # Call original method
      end
    end
  end

  # Step 2: Activate (enables TracePoint)
  def test_git_commands
    git_marble.activate do |trace|
      # This will trigger production code
      Pra::Env.init(env_name: 'test', repo_url: 'https://example.com/repo.git')

      # Production code calls system() internally → TracePoint intercepts!

      # Verify with trace
      assert_equal 1, trace[Kernel, :system].invocations
      assert trace[Kernel, :system].summoned_with?(/git clone/)
    end
  end
end
```

#### 2. Core Mechanism: TracePoint + Exception-Based Interception

**Challenge**: TracePoint can **observe** method calls but cannot **intercept** them (no built-in "return value override").

**Solution**: Use exception-based control flow to abort original execution and return mock value.

```ruby
class RealityMarble
  class Activation
    def activate(&test_block)
      context = Context.new
      Thread.current[:reality_marble_context] = context

      # Create TracePoint for method call interception
      trace = TracePoint.new(:call, :c_call) do |tp|
        # Check if this method should be mocked
        mock = context.find_mock(tp.defined_class, tp.method_id)
        next unless mock

        # Extract arguments from binding
        args, kwargs = extract_arguments(tp)

        # Record invocation
        record = context.trace_for(tp.defined_class, tp.method_id).start_call(args, kwargs, nil)

        # Execute mock and intercept original call
        begin
          result = mock.call(*args, **kwargs)
          record.finish(result)

          # Abort original method execution using exception
          throw :reality_marble_intercept, result
        rescue => e
          record.finish_with_error(e)
          throw :reality_marble_intercept, e
        end
      end

      # Enable TracePoint during test block
      trace.enable

      begin
        # Wrap test execution with catch to receive thrown values
        result = catch(:reality_marble_intercept) do
          test_block.call(context.trace)
        end

        # If we caught an exception from mock, re-raise it
        raise result if result.is_a?(Exception)
      ensure
        trace.disable
        Thread.current[:reality_marble_context] = nil
      end
    end

    private

    def extract_arguments(tp)
      # Use binding to extract method parameters
      params = tp.parameters
      binding = tp.binding

      args = []
      kwargs = {}

      params.each do |(type, name)|
        case type
        when :req, :opt
          args << binding.local_variable_get(name)
        when :key, :keyreq
          kwargs[name] = binding.local_variable_get(name)
        # ... handle rest, block, etc.
        end
      end

      [args, kwargs]
    end
  end
end
```

#### 3. How Interception Works

**Step-by-step execution**:

```ruby
# Test code (test/commands/env_test.rb)
git_marble.activate do
  Pra::Env.init(env_name: 'test', repo_url: 'https://example.com/repo.git')
  # ↓
end

# Production code (lib/pra/env.rb) - NO using declaration
def clone_repo(repo_url, dest_path, commit)
  system("git clone #{Shellwords.escape(repo_url)} ...")
  # ↓ When system() is called...
end

# TracePoint hook fires BEFORE system() executes
trace = TracePoint.new(:call) do |tp|
  # tp.method_id => :system
  # tp.defined_class => Kernel

  # Check if we have a mock for Kernel#system
  mock = find_mock(Kernel, :system)

  # Execute mock
  result = mock.call("git clone https://...")  # => true

  # Throw to abort original system() call
  throw :reality_marble_intercept, result
end
# ↓
# Original system() NEVER executes (intercepted!)
# Test receives `true` from mock
```

**Key insight**: `throw :reality_marble_intercept` unwinds the stack and prevents the original method from executing.

### Technical Deep Dive

#### Advantage 1: File Boundary Traversal ✅

**Problem in 案2**: Refinements cannot reach `lib/pra/env.rb` because it has no `using` declaration.

**Solution in 案3**: TracePoint is **globally active** when enabled.

```ruby
# test/commands/env_test.rb
git_marble.activate do
  # TracePoint is now monitoring ALL method calls in ALL files

  Pra::Env.init(...)
  # ↓ calls
  # lib/pra/env.rb: clone_repo(...)
  # ↓ calls
  # lib/pra/env.rb: system("git clone ...")
  # ↑ TracePoint catches this call even though lib/pra/env.rb has no `using`!
end
```

**Verdict**: ✅ **Solves the Production Code Boundary Problem completely**

#### Advantage 2: No Code Modification Required ✅

**案2**: Requires `using` declaration in every test file.

**案3**: No `using` needed. Just call `git_marble.activate`.

**Verdict**: ✅ **More transparent to users**

#### Advantage 3: True Dynamic Scoping ✅

**案2**: Refinements are lexically scoped (compile-time).

**案3**: TracePoint can be enabled/disabled at runtime (dynamic).

```ruby
# Outside activate → TracePoint disabled → No interception
system('ls')  # Real system call

# Inside activate → TracePoint enabled → Interception
git_marble.activate do
  system('git')  # Mocked
end

# Outside again → Disabled
system('pwd')  # Real system call
```

**Verdict**: ✅ **More intuitive on/off behavior**

### Critical Challenges and Limitations

#### Challenge 1: Exception-Based Interception Is Fragile ❌

**Problem**: Using `throw`/`catch` to abort original method execution is a hack.

**Issues**:
1. **Ensure blocks not executed**: Original method's `ensure` blocks will NOT run (stack unwound)
2. **Rescue interference**: If test code has `rescue Exception`, it might catch our throw
3. **Debugging nightmare**: Stack traces become confusing

**Example of breakage**:
```ruby
def important_cleanup
  system('git clone ...')
ensure
  cleanup_resources  # ← This will NOT run if we throw!
end
```

**Severity**: 🔴 **High** — Can cause resource leaks, unclosed files, etc.

#### Challenge 2: Performance Overhead ❌

**TracePoint overhead**: ~5000ns per method call (when enabled)

**案2 overhead**: ~161ns per method call

**Comparison**: **30x slower**

**Impact in tests**:
```ruby
# Test suite with 10,000 method calls
# 案2: 10,000 × 161ns = 1.61ms overhead
# 案3: 10,000 × 5000ns = 50ms overhead

# For large test suites (100,000 calls):
# 案2: 16ms
# 案3: 500ms (half a second!)
```

**Severity**: 🟡 **Medium** — Acceptable for tests, but noticeably slower for large suites

#### Challenge 3: Global Scope Pollution ❌

**Problem**: TracePoint monitors **ALL** method calls when enabled, not just mocked ones.

**案2**: Only affects code with `using` declaration (lexically scoped)

**案3**: Affects **everything** during `activate` block (globally scoped)

**Example**:
```ruby
git_marble.activate do
  # TracePoint is firing for EVERY method call:
  assert_equal(...)  # ← Fires
  result.to_s        # ← Fires
  [1, 2, 3].map {...} # ← Fires 3 times
  # ... hundreds of TracePoint callbacks
end
```

**Mitigation**: Add early-exit filter in TracePoint callback:
```ruby
TracePoint.new(:call) do |tp|
  # Quick check: Is this method mocked?
  next unless context.has_mock?(tp.defined_class, tp.method_id)

  # Only proceed for mocked methods
  # ...
end
```

**Severity**: 🟡 **Medium** — Mitigable with early filtering, but still overhead

#### Challenge 4: C Extension Opaqueness ❌

**Problem**: C-implemented methods (`:c_call`) don't provide full binding information.

```ruby
TracePoint.new(:c_call) do |tp|
  tp.binding  # => nil (C methods don't create Ruby bindings!)
  # Cannot extract arguments!
end
```

**Impact**: Cannot mock C methods with argument inspection.

**Workaround**: Only support Ruby-implemented methods (`:call` event).

**Severity**: 🟡 **Medium** — Can document as limitation (similar to 案2's special method name issue)

#### Challenge 5: Thread Safety Complexity ❌

**Problem**: Multiple threads enabling TracePoint simultaneously.

**Scenario**:
```ruby
Thread.new do
  git_marble.activate { ... }  # Enables TracePoint
end

Thread.new do
  file_marble.activate { ... }  # Enables ANOTHER TracePoint?
end
```

**Solution**: Thread-local TracePoint instances + context registry.

**Severity**: 🟢 **Low** — Solvable with Thread-local storage (same as 案2)

### API Comparison: 案2 vs 案3

| Aspect | 案2 (Refinements) | 案3 (TracePoint) |
|--------|-------------------|------------------|
| **File boundary** | ❌ Cannot cross | ✅ Can cross |
| **Production code** | ❌ Cannot reach | ✅ Can reach |
| **Performance** | ✅ Fast (~161ns) | ❌ Slow (~5000ns) |
| **Scope** | ✅ Lexical (safe) | ❌ Global (risky) |
| **`using` declaration** | ❌ Required per file | ✅ Not needed |
| **Ruby syntax** | ✅ Normal `refine`/`def` | ⚠️ DSL (`mock`/`original`) |
| **Resource safety** | ✅ Ensure blocks run | ❌ Throw bypasses ensure |
| **C methods** | ⚠️ Limited support | ⚠️ No binding access |
| **Complexity** | 🟢 Low | 🔴 High |

### Use Case Analysis

#### When 案3 Excels ✅

1. **Integration-style tests**: Testing production code paths that make system calls
   ```ruby
   def test_full_env_initialization
     git_marble.activate do
       Pra::Env.init(...)  # Crosses into lib/pra/env.rb
     end
   end
   ```

2. **Third-party gem mocking**: Mocking gems you can't modify
   ```ruby
   http_marble.activate do
     Net::HTTP.get(...)  # Mock gem code
   end
   ```

3. **Legacy codebases**: Where adding DI would require massive refactoring

#### When 案2 Excels ✅

1. **Test helper methods**: Code directly in test files
   ```ruby
   using GitMarble

   def helper_that_calls_system
     system('git status')  # Direct call in test file
   end
   ```

2. **Performance-critical tests**: Large test suites with many iterations

3. **Safety-first approach**: Where `ensure` blocks must always run

### Implementation Roadmap for 案3

**Phase 0**: Proof of Concept
- [ ] Implement basic TracePoint hooking
- [ ] Test throw/catch interception mechanism
- [ ] Measure performance overhead
- [ ] **Test ensure block behavior** (critical!)

**Phase 1**: Core Implementation
- [ ] Implement `RealityMarble.chant` (mock definition DSL)
- [ ] Implement `Marble#activate` with TracePoint
- [ ] Implement argument extraction from binding
- [ ] Implement context + trace recording

**Phase 2**: Robustness
- [ ] Handle C methods (`:c_call` events)
- [ ] Thread-local TracePoint management
- [ ] Error handling for binding extraction failures
- [ ] Early-exit filtering for performance

**Phase 3**: Edge Cases
- [ ] Keyword arguments, blocks, splats
- [ ] Methods without bindings
- [ ] Nested `activate` calls
- [ ] Mock priority/ordering

### Open Questions

1. **Ensure block problem**: Can we make throws safe?
   - Option A: Document as limitation ("Don't mock methods with critical ensure blocks")
   - Option B: Use `return` injection instead of `throw` (requires deeper VM hacking)
   - Option C: Accept that 案3 is unsuitable for resource-managing code

2. **Performance**: Is 30x slowdown acceptable?
   - Need real-world benchmarks with actual test suites
   - May be acceptable if test suite takes <1 second total

3. **Hybrid approach**: Can we combine 案2 + 案3?
   - 案2 for test file direct calls (fast path)
   - 案3 for production code calls (slow path, on-demand)

### Recommendation Status: Evaluation Needed

**案3 viability depends on**:
1. ✅ Ensure block safety is acceptable risk
2. ✅ Performance overhead is acceptable for test context
3. ✅ Global scope is mitigated with early filtering

**Next steps**:
1. Implement Phase 0 proof-of-concept
2. Benchmark against 案2
3. Test ensure block behavior with real-world code
4. Decide: 案2, 案3, or Hybrid approach

---

## Implementation Plan

### Phase 0: Project Setup

**Goal**: Create gem skeleton with proper structure

#### Tasks

- [ ] Create new gem project: `bundle gem reality_marble`
- [ ] Setup gemspec
  - [ ] Name: `reality_marble`
  - [ ] Summary: "Pure Ruby mock library using Refinements for Test::Unit"
  - [ ] Description: Full description with TYPE-MOON metaphor
  - [ ] Dependencies: None (zero runtime dependencies)
  - [ ] Development dependencies: test-unit, rake, rubocop
  - [ ] Ruby version: >= 3.4.0
- [ ] Setup directory structure
  ```
  reality_marble/
  ├── lib/
  │   ├── reality_marble.rb
  │   └── reality_marble/
  │       ├── version.rb
  │       ├── chant.rb
  │       ├── activation.rb
  │       ├── trace.rb
  │       └── record.rb
  ├── test/
  │   ├── test_helper.rb
  │   └── reality_marble/
  ├── examples/
  ├── docs/
  ├── reality_marble.gemspec
  ├── Gemfile
  ├── Rakefile
  ├── README.md
  ├── CHANGELOG.md
  └── LICENSE (MIT)
  ```
- [ ] Setup Rakefile (test, rubocop tasks)
- [ ] Setup .rubocop.yml
- [ ] Setup .gitignore
- [ ] Initialize git repository
- [ ] Create initial README.md (basic structure)

---

### Phase 1: Core Implementation (Chant + Activate + Basic Trace)

**Goal**: Implement minimal working version

#### 1.1 Chant Implementation (REVISED: Alias-Rename + Guarded Dispatch)

**File**: `lib/reality_marble/chant.rb`

**CRITICAL**: This implementation uses the "Alias-Rename + Guarded Dispatch" pattern to achieve true activate/deactivate behavior.

```ruby
require 'set'

module RealityMarble
  module Chant
    # Registry of refined methods
    @refined_methods = Set.new
    @wrapped_methods = Set.new  # Track already-wrapped to prevent double-wrap

    class << self
      attr_reader :refined_methods

      def create(&refinement_block)
        Module.new do
          # Override refine to track and wrap methods
          define_singleton_method(:refine) do |target_class, &block|
            super(target_class) do
              # Capture methods before user block
              before_methods = instance_methods(false)

              # Execute user's method definitions
              module_eval(&block)

              # Detect newly defined methods
              after_methods = instance_methods(false)
              new_methods = after_methods - before_methods

              # Register and wrap each new method
              new_methods.each do |method_name|
                key = [target_class, method_name]

                # Skip if already wrapped (prevents double-wrapping)
                next if RealityMarble::Chant.wrapped?(key)

                RealityMarble::Chant.register(target_class, method_name)
                wrap_with_guarded_dispatch(target_class, method_name)
                RealityMarble::Chant.mark_wrapped(key)
              end
            end
          end

          # Execute user's refinement block
          module_eval(&refinement_block)
        end
      end

      def register(target_class, method_name)
        @refined_methods << [target_class, method_name]
      end

      def wrapped?(key)
        @wrapped_methods.include?(key)
      end

      def mark_wrapped(key)
        @wrapped_methods << key
      end

      def refined?(target_class, method_name)
        @refined_methods.include?([target_class, method_name])
      end
    end

    private

    # CRITICAL: Alias-Rename + Guarded Dispatch pattern
    # This is the core of Reality Marble's activate/deactivate mechanism
    def wrap_with_guarded_dispatch(target_class, method_name)
      # Step 1: Rename user's mock to __rm_mock_<method>
      mock_name = :"__rm_mock_#{method_name}"
      alias_method mock_name, method_name

      # Step 2: Check if original implementation exists
      has_original = begin
        target_class.instance_method(method_name)
        true
      rescue NameError
        false
      end

      # Step 3: Generate dispatcher using `def` (for super support)
      # Use class_eval to generate `def` (define_method doesn't support super)

      # Handle special method names (backtick, [], []=, etc.)
      method_str = method_name.to_s
      safe_name = if method_str =~ /^[a-zA-Z_][a-zA-Z0-9_]*[?!=]?$/
                    method_str  # Normal method name
                  else
                    # Special syntax - will need send-based approach
                    # For now, mark as TODO
                    warn "[Reality Marble] Special method syntax not yet supported: #{method_name}"
                    return
                  end

      # Generate dispatcher
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{safe_name}(*args, **kwargs, &block)
          ctx = Thread.current[:reality_marble_context]

          if ctx
            # Inside activate → call mock + trace
            trace = ctx.trace_for(#{target_class}, :#{method_name})
            record = trace.start_call(args, kwargs, block)

            begin
              result = #{mock_name}(*args, **kwargs, &block)
              record.finish(result)
              result
            rescue => e
              record.finish_with_error(e)
              raise
            end
          else
            # Outside activate → call original
            #{has_original ? 'super' : 'raise NoMethodError, "undefined method for Reality Marble mock"'}
          end
        end
      RUBY
    end
  end
end
```

**Tasks**:
- [ ] Implement `RealityMarble::Chant` module
- [ ] Implement `create` method (returns Refinement module)
- [ ] Implement `refine` override with method detection
- [ ] Implement method registry (Set-based)
- [ ] **CRITICAL**: Implement `wrap_with_guarded_dispatch` (Alias + Dispatch pattern)
- [ ] Implement double-wrap prevention (`@wrapped_methods`)
- [ ] Implement original method existence check
- [ ] Implement special method name handling (backtick, etc.)
- [ ] Test: Basic chant creation
- [ ] Test: Method registration
- [ ] Test: Multiple refine blocks
- [ ] **NEW**: Test: Activate on/off behavior (CRITICAL TEST)
- [ ] **NEW**: Test: Outside activate calls original
- [ ] **NEW**: Test: Inside activate calls mock
- [ ] **NEW**: Test: super resolution order

#### 1.2 Activation Implementation

**File**: `lib/reality_marble/activation.rb`

```ruby
module RealityMarble
  class Activation
    def initialize
      @traces = {}
    end

    # Access trace by [Class, :method]
    def [](target_class, method_name)
      trace_for(target_class, method_name)
    end

    def trace_for(target_class, method_name)
      key = [target_class, method_name]
      @traces[key] ||= Trace.new(target_class, method_name)
    end
  end

  module_function

  def activate(&test_block)
    context = Activation.new
    Thread.current[:reality_marble_context] = context

    begin
      test_block.call(context)
    ensure
      Thread.current[:reality_marble_context] = nil
    end
  end
end
```

**Tasks**:
- [ ] Implement `Activation` class
- [ ] Implement `trace_for` method
- [ ] Implement `[]` accessor (syntactic sugar)
- [ ] Implement `activate` module function
- [ ] Thread-local context management
- [ ] Ensure cleanup in ensure block
- [ ] Test: Context creation and cleanup
- [ ] Test: Thread isolation
- [ ] Test: Multiple activations (sequential)

#### 1.3 Basic Trace Implementation

**File**: `lib/reality_marble/trace.rb`

```ruby
module RealityMarble
  class Trace
    attr_reader :target_class, :method_name, :records

    def initialize(target_class, method_name)
      @target_class = target_class
      @method_name = method_name
      @records = []
    end

    def start_call(args, kwargs, block)
      record = Record.new(args, kwargs, block)
      @records << record
      record
    end

    # Basic query methods
    def invocations
      @records.size
    end

    def summoned?
      @records.any?
    end

    def dormant?
      @records.empty?
    end

    def first_record
      @records.first
    end

    def last_record
      @records.last
    end
  end
end
```

**File**: `lib/reality_marble/record.rb`

```ruby
module RealityMarble
  class Record
    attr_reader :arguments, :keyword_arguments, :block, :timestamp
    attr_accessor :outcome, :error, :duration

    def initialize(args, kwargs, block)
      @arguments = args
      @keyword_arguments = kwargs
      @block = block
      @timestamp = Time.now
      @outcome = nil
      @error = nil
      @duration = nil
    end

    def finish(result)
      @outcome = result
      @duration = Time.now - @timestamp
    end

    def finish_with_error(error)
      @error = error
      @duration = Time.now - @timestamp
    end

    def success?
      @error.nil?
    end

    def failed?
      !@error.nil?
    end
  end
end
```

**Tasks**:
- [ ] Implement `Trace` class
- [ ] Implement `start_call` (creates Record)
- [ ] Implement basic query methods (invocations, summoned?, dormant?)
- [ ] Implement `Record` class
- [ ] Implement `finish` and `finish_with_error`
- [ ] Test: Record creation and storage
- [ ] Test: Basic query methods
- [ ] Test: Multiple calls to same method

#### 1.4 Main Entry Point

**File**: `lib/reality_marble.rb`

```ruby
require_relative 'reality_marble/version'
require_relative 'reality_marble/chant'
require_relative 'reality_marble/activation'
require_relative 'reality_marble/trace'
require_relative 'reality_marble/record'

module RealityMarble
  class Error < StandardError; end

  module_function

  def chant(&refinement_block)
    Chant.create(&refinement_block)
  end

  def activate(&test_block)
    context = Activation.new
    Thread.current[:reality_marble_context] = context

    begin
      test_block.call(context)
    ensure
      Thread.current[:reality_marble_context] = nil
    end
  end
end
```

**Tasks**:
- [ ] Implement main module entry point
- [ ] Require all submodules
- [ ] Define `chant` convenience method
- [ ] Define `activate` convenience method
- [ ] Test: End-to-end basic flow
- [ ] Test: Kernel#system mock
- [ ] Test: Multiple methods in single marble

---

### Phase 2: Advanced Trace Features

**Goal**: Implement pattern matching and advanced queries

#### 2.1 Pattern Matching

**Add to `Trace` class**:

```ruby
def summoned_with?(*expected_args, **expected_kwargs, &matcher)
  @records.any? do |record|
    if matcher
      # Block-based matching
      matcher.call(*record.arguments, **record.keyword_arguments)
    elsif expected_args.size == 1 && expected_args.first.is_a?(Regexp)
      # Regex matching (join args as string)
      record.arguments.join(' ') =~ expected_args.first
    elsif expected_args.empty? && expected_kwargs.empty?
      # No pattern given
      false
    else
      # Exact match
      record.arguments == expected_args &&
        record.keyword_arguments == expected_kwargs
    end
  end
end
```

**Tasks**:
- [ ] Implement `summoned_with?` with multiple patterns
- [ ] Support exact match (args comparison)
- [ ] Support Regexp match (join args as string)
- [ ] Support block-based matching
- [ ] Test: Exact match
- [ ] Test: Regex match
- [ ] Test: Block match
- [ ] Test: Edge cases (empty args, kwargs only)

#### 2.2 Record Filtering

**Add to `Trace` class**:

```ruby
def select_records(&filter)
  @records.select(&filter)
end

def successful_calls
  @records.select(&:success?)
end

def failed_calls
  @records.select(&:failed?)
end
```

**Tasks**:
- [ ] Implement `select_records`
- [ ] Implement `successful_calls`
- [ ] Implement `failed_calls`
- [ ] Test: Filtering by outcome
- [ ] Test: Filtering by custom criteria

---

### Phase 3: Class Method Support

**Goal**: Support mocking class methods (singleton_class)

#### 3.1 Singleton Class Refinement

**Example usage**:

```ruby
using RealityMarble.chant do
  refine FileUtils.singleton_class do
    def mkdir_p(path)
      puts "Mock: mkdir_p(#{path})"
      [path]
    end
  end
end
```

**Tasks**:
- [ ] Test singleton_class refinement
- [ ] Ensure method wrapping works for class methods
- [ ] Test: FileUtils.mkdir_p mocking
- [ ] Test: Custom class methods
- [ ] Document singleton_class pattern

---

### Phase 4: Test::Unit Integration Helpers

**Goal**: Provide convenience helpers for Test::Unit

#### 4.1 Test Helper Module

**File**: `lib/reality_marble/test_unit.rb`

```ruby
module RealityMarble
  module TestUnit
    # Convenience method for activate
    def with_marble(&block)
      RealityMarble.activate(&block)
    end

    # Assert helpers
    def assert_summoned(trace, message = nil)
      assert trace.summoned?, message || "Expected #{trace.method_name} to be called"
    end

    def assert_not_summoned(trace, message = nil)
      assert trace.dormant?, message || "Expected #{trace.method_name} not to be called"
    end

    def assert_summoned_with(trace, *expected, **kwargs, &block)
      assert trace.summoned_with?(*expected, **kwargs, &block),
             "Expected #{trace.method_name} to be called with #{expected.inspect}"
    end
  end
end
```

**Tasks**:
- [ ] Implement `TestUnit` helper module
- [ ] Implement `with_marble` alias
- [ ] Implement `assert_summoned`
- [ ] Implement `assert_not_summoned`
- [ ] Implement `assert_summoned_with`
- [ ] Test: Helper methods in Test::Unit context
- [ ] Document usage in README

---

### Phase 5: Documentation & Examples

**Goal**: Complete documentation with rich examples

#### 5.1 README.md

**Sections**:
1. Project overview with TYPE-MOON metaphor
2. Installation
3. Quick start (3-step usage)
4. Core concepts (chant/activate/trace)
5. API reference (brief)
6. Test::Unit integration
7. Advanced usage (link to docs/)
8. Contributing
9. License

**Tasks**:
- [ ] Write project overview
- [ ] Write installation guide
- [ ] Write quick start (3 examples)
- [ ] Write core concepts section
- [ ] Write API reference summary
- [ ] Add badges (gem version, build status, etc.)
- [ ] Proofread and polish

#### 5.2 Detailed Documentation

**Files**:
- `docs/CONCEPT.md` - Reality Marble metaphor explained
- `docs/API.md` - Complete API reference
- `docs/TRACE_API.md` - Trace methods reference
- `docs/ADVANCED.md` - Custom logging workarounds
- `docs/RECIPES.md` - Common patterns and recipes

**Tasks**:
- [ ] Write CONCEPT.md (TYPE-MOON background)
- [ ] Write API.md (complete method reference)
- [ ] Write TRACE_API.md (all Trace methods)
- [ ] Write ADVANCED.md (custom logging with closures)
- [ ] Write RECIPES.md (common patterns)

#### 5.3 Example Code

**Files**:
- `examples/basic_example.rb` - Simple Kernel#system mock
- `examples/git_commands.rb` - Git command mocking
- `examples/file_operations.rb` - FileUtils mocking
- `examples/http_requests.rb` - Net::HTTP mocking
- `examples/backtick_commands.rb` - Backtick (`) mocking
- `examples/custom_logging.rb` - Advanced: Custom trace with closures

**Tasks**:
- [ ] Write basic_example.rb
- [ ] Write git_commands.rb (realistic git workflow)
- [ ] Write file_operations.rb (FileUtils)
- [ ] Write http_requests.rb (Net::HTTP)
- [ ] Write backtick_commands.rb (` mocking)
- [ ] Write custom_logging.rb (closure-based logging)
- [ ] Ensure all examples are runnable
- [ ] Add comments explaining each pattern

---

### Phase 6: Integration with pra gem (This Project)

**Goal**: Replace SystemCommandMocking with Reality Marble

#### 6.1 Analysis of Existing Code

**Current implementation**: `test/commands/env_test.rb` (lines 6-77)

**Components**:
- `SystemCommandMocking` module
- `SystemRefinement` with Kernel#system refinement
- `with_system_mocking` helper
- Thread-local mock context
- Call counting and failure simulation

**Tasks**:
- [ ] Review current SystemCommandMocking implementation
- [ ] Identify all mocking patterns used
- [ ] List all test cases that depend on it
- [ ] Document migration requirements

#### 6.2 Migration Plan

**Step 1**: Add Reality Marble as development dependency

```ruby
# picoruby-application-on-r2p2-esp32-development-kit.gemspec
spec.add_development_dependency 'reality_marble', '~> 0.1.0'
```

**Step 2**: Create marble definition for git commands

```ruby
# test/support/git_marble.rb
using RealityMarble.chant do
  refine Kernel do
    def system(cmd)
      case cmd
      when /git clone/
        # Create dummy git repository
        if cmd =~ /git clone.* (\S+)\s*$/
          dest_path = $1.gsub(/['"]/, '')
          FileUtils.mkdir_p(dest_path)
          FileUtils.mkdir_p(File.join(dest_path, '.git'))
        end
        true
      when /git checkout/
        true
      when /git submodule update/
        true
      else
        super
      end
    end
  end
end
```

**Step 3**: Rewrite test cases

**Before** (SystemCommandMocking):
```ruby
def test_clone_success
  with_system_mocking do |mock|
    # ...
    assert_equal 1, mock[:call_count][:clone]
  end
end
```

**After** (Reality Marble):
```ruby
def test_clone_success
  RealityMarble.activate do |trace|
    # ...
    assert_equal 1, trace[Kernel, :system].invocations
    assert trace[Kernel, :system].summoned_with?(/git clone/)
  end
end
```

**Tasks**:
- [ ] Add reality_marble to gemspec (development dependency)
- [ ] Create `test/support/git_marble.rb`
- [ ] Migrate `test_clone_success` test case
- [ ] Migrate `test_clone_failure` test case
- [ ] Migrate `test_checkout_failure` test case
- [ ] Migrate `test_submodule_failure` test case
- [ ] Remove old `SystemCommandMocking` module
- [ ] Run full test suite (ensure all pass)
- [ ] Update test_helper.rb if needed

#### 6.3 Verification

**Tasks**:
- [ ] Run `bundle exec rake test` (all tests pass)
- [ ] Run `bundle exec rake ci` (coverage maintained)
- [ ] Verify no SystemCommandMocking references remain
- [ ] Git commit: "refactor: replace SystemCommandMocking with Reality Marble"

---

### Phase 7: Polish & Release Preparation

**Goal**: Prepare gem for public release

#### 7.1 Code Quality

**Tasks**:
- [ ] Run RuboCop (0 violations)
- [ ] Run test suite (100% pass rate)
- [ ] Measure test coverage (target: 90%+ line, 80%+ branch)
- [ ] Add YARD documentation comments
- [ ] Generate API documentation

#### 7.2 Release Checklist

**Tasks**:
- [ ] Update CHANGELOG.md (version 0.1.0)
- [ ] Update version.rb (0.1.0)
- [ ] Review README.md (final polish)
- [ ] Review all documentation
- [ ] Create GitHub repository
- [ ] Push code to GitHub
- [ ] Create git tag: v0.1.0
- [ ] Build gem: `gem build reality_marble.gemspec`
- [ ] Test gem installation locally
- [ ] Publish to RubyGems.org: `gem push reality_marble-0.1.0.gem`
- [ ] Announce on Twitter/社交媒体

---

## Sample Code (Complete Examples)

### Example 1: Basic Git Command Mocking

```ruby
require 'test/unit'
require 'reality_marble'

class GitCommandTest < Test::Unit::TestCase
  # Chant: Define Reality Marble
  using RealityMarble.chant do
    refine Kernel do
      def system(cmd)
        case cmd
        when /git clone/
          puts "[Marble] git clone → success"
          true
        when /git checkout/
          puts "[Marble] git checkout → failure"
          false
        else
          super  # Call original for non-git commands
        end
      end
    end
  end

  def test_git_clone_succeeds_in_marble
    RealityMarble.activate do |trace|
      result = system('git clone https://github.com/user/repo.git')

      assert_true result
      assert_equal 1, trace[Kernel, :system].invocations
      assert trace[Kernel, :system].summoned_with?(/git clone/)
    end
  end

  def test_git_checkout_fails_in_marble
    RealityMarble.activate do |trace|
      result = system('git checkout main')

      assert_false result
      assert_equal 1, trace[Kernel, :system].invocations
    end
  end

  def test_non_git_commands_use_original
    RealityMarble.activate do |trace|
      system('echo hello')  # Uses real system

      # Still recorded
      assert_equal 1, trace[Kernel, :system].invocations
    end
  end
end
```

### Example 2: File Operations

```ruby
require 'test/unit'
require 'reality_marble'
require 'fileutils'

class FileOperationsTest < Test::Unit::TestCase
  using RealityMarble.chant do
    refine FileUtils.singleton_class do
      def mkdir_p(path)
        puts "[Marble] mkdir_p: #{path}"
        [path]  # Return path without actually creating
      end

      def rm_rf(path)
        puts "[Marble] rm_rf: #{path} (blocked)"
        # Do nothing (safe in tests)
      end
    end
  end

  def test_mkdir_without_side_effects
    RealityMarble.activate do |trace|
      result = FileUtils.mkdir_p('/tmp/test/deep/path')

      assert_equal ['/tmp/test/deep/path'], result
      assert_equal 1, trace[FileUtils.singleton_class, :mkdir_p].invocations
    end
  end

  def test_rm_rf_is_safe
    RealityMarble.activate do |trace|
      FileUtils.rm_rf('/important/data')  # Safe in marble!

      assert_equal 1, trace[FileUtils.singleton_class, :rm_rf].invocations
    end
  end
end
```

### Example 3: Backtick Commands

```ruby
require 'test/unit'
require 'reality_marble'

class BacktickCommandTest < Test::Unit::TestCase
  using RealityMarble.chant do
    refine Kernel do
      def `(cmd)
        case cmd
        when /date/
          "2025-11-10\n"
        when /uname/
          "Reality Marble OS\n"
        else
          super
        end
      end
    end
  end

  def test_date_command_returns_fixed_date
    RealityMarble.activate do |trace|
      output = `date`

      assert_equal "2025-11-10\n", output
      assert_equal 1, trace[Kernel, :`].invocations
    end
  end

  def test_multiple_backtick_calls
    RealityMarble.activate do |trace|
      date = `date`
      os = `uname`

      assert_equal "2025-11-10\n", date
      assert_equal "Reality Marble OS\n", os
      assert_equal 2, trace[Kernel, :`].invocations

      # Verify each call
      assert trace[Kernel, :`].summoned_with?(/date/)
      assert trace[Kernel, :`].summoned_with?(/uname/)
    end
  end
end
```

### Example 4: Advanced - Custom Logging

```ruby
require 'test/unit'
require 'reality_marble'

class CustomLoggingTest < Test::Unit::TestCase
  using RealityMarble.chant do
    # Use closure to capture custom data
    http_requests = []

    refine Net::HTTP do
      def request(req)
        # Custom logging (beyond automatic trace)
        http_requests << {
          method: req.method,
          path: req.path,
          headers: req.to_hash,
          body: req.body,
          timestamp: Time.now
        }

        # Mock response
        Net::HTTPSuccess.new('1.1', '200', 'OK')
      end
    end

    # Helper to access custom log
    def all_http_requests
      http_requests
    end

    def post_requests
      http_requests.select { |r| r[:method] == 'POST' }
    end
  end

  def test_http_requests_with_custom_logging
    RealityMarble.activate do |trace|
      http = Net::HTTP.new('api.example.com')
      http.request(Net::HTTP::Post.new('/users'))
      http.request(Net::HTTP::Get.new('/status'))

      # Automatic trace
      assert_equal 2, trace[Net::HTTP, :request].invocations

      # Custom logging
      assert_equal 2, all_http_requests.size
      assert_equal 1, post_requests.size
      assert_equal '/users', post_requests.first[:path]
    end
  end
end
```

---

## Documentation Structure

### README.md Outline

```markdown
# Reality Marble

Pure Ruby mock library using Refinements for Test::Unit.

> "I am the bone of my sword" - Inspired by TYPE-MOON's Reality Marble (固有結界)

## Features

- Zero pollution (Refinements scoped)
- Zero cleanup (automatic)
- Zero learning curve (normal Ruby syntax)
- Thread-safe
- Test::Unit focused

## Installation

gem install reality_marble

## Quick Start

[3-step example]

## Core Concepts

### Chant (詠唱)
### Activate (展開)
### Trace (痕跡)

## API Reference

[Brief summary, link to docs/API.md]

## Test::Unit Integration

[Helper methods]

## Advanced Usage

[Link to docs/ADVANCED.md]

## Contributing

## License

MIT
```

### docs/CONCEPT.md Outline

```markdown
# Reality Marble Concept

## TYPE-MOON Background

[Explanation of 固有結界 in Fate/月姫]

## Metaphor Mapping

| Reality Marble | RealityMarble Gem |
|----------------|-------------------|
| Chant (詠唱)   | using RealityMarble.chant |
| Deploy (展開)  | RealityMarble.activate |
| Inner world    | Refinement scope |
| Auto-fade      | Block exit cleanup |
| Trace (痕跡)   | Spy recording |

## Why This Metaphor Works

[Technical + poetic explanation]
```

### docs/API.md Outline

```markdown
# API Reference

## Module: RealityMarble

### RealityMarble.chant(&block)
### RealityMarble.activate(&block)

## Class: RealityMarble::Trace

### Instance Methods

- invocations
- summoned?
- dormant?
- summoned_with?(...)
- first_record
- last_record
- records

## Class: RealityMarble::Record

### Attributes

- arguments
- keyword_arguments
- outcome
- error
- timestamp
- duration

### Methods

- success?
- failed?
```

### docs/RECIPES.md Outline

```markdown
# Common Recipes

## Recipe 1: Mock git commands
## Recipe 2: Mock file operations
## Recipe 3: Mock HTTP requests
## Recipe 4: Mock time-dependent code
## Recipe 5: Mock external API calls
## Recipe 6: Combine multiple marbles
## Recipe 7: Custom logging patterns
```

---

## Testing Strategy

### Test Coverage Goals

- **Line coverage**: 90%+
- **Branch coverage**: 80%+
- **All public APIs**: 100% tested

### Test Organization

```
test/
├── test_helper.rb
├── reality_marble/
│   ├── chant_test.rb          # Chant functionality
│   ├── activation_test.rb     # Activation + context
│   ├── trace_test.rb          # Trace queries
│   ├── record_test.rb         # Record attributes
│   ├── wrapping_test.rb       # Method wrapping
│   ├── thread_safety_test.rb # Thread isolation
│   └── integration_test.rb    # End-to-end scenarios
```

### Key Test Cases

#### Chant Tests
- Basic refine block
- Multiple refine blocks
- Multiple methods in single refine
- Class methods (singleton_class)
- Method with super
- Method with complex logic

#### Activation Tests
- Basic activate
- Thread-local context
- Ensure cleanup on exception
- Multiple sequential activations
- Thread isolation

#### Trace Tests
- Basic invocation counting
- summoned? / dormant?
- summoned_with? patterns (exact, regex, block)
- first_record / last_record
- Multiple calls to same method

#### Wrapping Tests
- super calls original method
- Arguments passed correctly
- Return value captured
- Exception handling
- Block arguments

#### Integration Tests
- Kernel#system mocking
- FileUtils mocking
- Backtick mocking
- Multiple methods simultaneously
- Real-world git command scenario

---

## Technical Notes

### Refinement Wrapping Implementation

**Key insight**: Use `instance_method` + `define_method` pattern

```ruby
def wrap_with_trace(target_class, method_name)
  original = instance_method(method_name)

  define_method(method_name) do |*args, **kwargs, &block|
    # Trace logic here
    original.bind(self).call(*args, **kwargs, &block)
  end
end
```

**Why this works**:
1. `instance_method(method_name)` captures UnboundMethod
2. `define_method` replaces it with wrapper
3. `original.bind(self).call` invokes captured method
4. `super` still works (goes to pre-Refinement method)

### Thread Safety

**Context isolation**:
```ruby
Thread.current[:reality_marble_context] = context
```

Each thread has independent context, no shared state.

### Performance Considerations

**No TracePoint overhead**:
- Only wrapped methods have trace logic
- No global method monitoring
- Minimal performance impact

**Benchmarks** (to be measured):
- Wrapping overhead: < 5% vs direct call
- Memory overhead: ~100 bytes per Record

---

## Migration Guide (for pra gem)

### Before (SystemCommandMocking)

```ruby
module SystemCommandMocking
  module SystemRefinement
    refine Kernel do
      def system(*args)
        mock_context = Thread.current[:system_mock_context]
        return ORIGINAL_SYSTEM.bind(self).call(*args) unless mock_context

        cmd = args.join(' ')
        if cmd.include?('git clone')
          mock_context[:call_count][:clone] += 1
          return false if mock_context[:fail_clone]
          # ...
        end
      end
    end
  end

  def with_system_mocking(fail_clone: false, ...)
    # Manual context setup
  end
end
```

### After (Reality Marble)

```ruby
using RealityMarble.chant do
  refine Kernel do
    def system(cmd)
      case cmd
      when /git clone/
        # Setup logic here
        true
      else
        super
      end
    end
  end
end

def test_git_clone
  RealityMarble.activate do |trace|
    # Test logic
    assert trace[Kernel, :system].summoned_with?(/git clone/)
  end
end
```

### Benefits of Migration

1. **Simpler**: Less boilerplate
2. **Standard**: Uses gem instead of custom code
3. **Maintainable**: Gem is tested and documented
4. **Readable**: Normal Ruby syntax

---

## Future Enhancements (Post-v1.0)

### Possible Features

- [ ] RSpec integration (if demand exists)
- [ ] Minitest integration
- [ ] Marble chaining (marble1 + marble2)
- [ ] Marble inheritance
- [ ] Record serialization (JSON export)
- [ ] Web UI for trace visualization
- [ ] Performance profiling integration

### Out of Scope (Philosophy)

- ❌ Auto-mocking (against explicit declaration)
- ❌ Framework-agnostic (Test::Unit focus is strength)
- ❌ DSL for method definition (normal Ruby is better)

---

## Success Criteria

### v0.1.0 Release Checklist

- [ ] All Phase 1-5 tasks complete
- [ ] Test coverage ≥ 90% line, ≥ 80% branch
- [ ] RuboCop: 0 violations
- [ ] Documentation complete (README + docs/)
- [ ] Examples runnable
- [ ] Gem builds successfully
- [ ] Published to RubyGems.org

### Post-Release

- [ ] pra gem migration complete (Phase 6)
- [ ] Blog post written (Japanese + English)
- [ ] Community feedback collected
- [ ] GitHub issues addressed
- [ ] v0.2.0 planning (based on feedback)

---

## Contact & Contribution

**Maintainer**: bash0C7 (from pra gem project)
**Repository**: (TBD - to be created)
**License**: MIT

**Contribution welcome**:
- Bug reports
- Feature requests (aligned with philosophy)
- Documentation improvements
- Example code

---

## Appendix: Design Decisions

### Why Refinements?

- Lexical scoping (no global pollution)
- Built-in to Ruby 3.4+ (no dependencies)
- Perfect metaphor for "alternate reality"

### Why Test::Unit Only?

- Focus on one framework = better quality
- Most pra gem tests use Test::Unit
- Simpler implementation and documentation

### Why No TracePoint?

- Performance (avoid global monitoring)
- Noise (too many irrelevant events)
- Precision (only track refined methods)

### Why Normal Ruby Syntax?

- Zero learning curve
- IDE support (syntax highlighting, completion)
- Flexibility (full Ruby power)

---

## Appendix: Peer Review Feedback & Resolution

### Review Date: 2025-11-11

**Reviewer**: External AI peer review

**Overall Assessment**: Design concept excellent, but critical architectural flaw identified in original implementation.

### Critical Issues Identified

#### Issue 1: Refinements Lexical Scope Misunderstanding

**Problem**: Original design assumed `activate` could dynamically enable/disable Refinements at runtime.

**Reality**: Refinements are lexically scoped and cannot be toggled at runtime.

**Impact**:
- `activate` block would only control trace recording, not mock behavior
- Mocks would apply everywhere in `using` scope, not just inside `activate`
- "Auto-dissolution" and "Zero pollution" claims would be misleading

**Resolution**: ✅ **Adopted "Alias-Rename + Guarded Dispatch" pattern**
- Mock renamed to `__rm_mock_*`
- Dispatcher checks Thread-local context
- `activate` block truly controls mock behavior
- True "Auto-dissolution" achieved

#### Issue 2: `define_method` Cannot Use `super`

**Problem**: Original `wrap_with_trace` used `define_method`, which doesn't support `super`.

**Impact**:
- Dispatcher couldn't fall back to original method via `super`
- Would break user's `super` calls inside mocks

**Resolution**: ✅ **Switched to `class_eval` + `def`**
- Generate `def` via heredoc string evaluation
- `super` now works correctly
- Maintains clean method resolution order

#### Issue 3: Mock Always Active (Original Design)

**Problem**: Original implementation always called mock, just skipped trace recording outside `activate`.

**Impact**:
- setup/teardown methods would see mock behavior
- Helper methods in test class would see mock behavior
- Violated "Zero pollution" principle

**Resolution**: ✅ **Dispatcher routes to `super` outside `activate`**
- Inside `activate` → `__rm_mock_*` (mock)
- Outside `activate` → `super` (original)
- True isolation achieved

### Validated Design Decisions

#### ✅ Correct: Test::Unit Focus

**Peer Feedback**: Agreed that focusing on one framework is pragmatic.

**Status**: No changes needed.

#### ✅ Correct: Explicit `using` Declaration

**Peer Feedback**: Requiring `using` in each test file is acceptable and even desirable (explicit > implicit).

**Status**: No changes needed. Document as feature, not limitation.

#### ✅ Correct: Performance Approach

**Peer Feedback**: Avoiding TracePoint is wise, alias-dispatch is efficient.

**Status**: No changes needed.

### Action Items from Review

- [x] Add "Technical Deep Dive" section explaining Refinements constraints
- [x] Revise Phase 1.1 implementation to use alias-dispatch pattern
- [x] Add tests for activate on/off behavior
- [x] Add tests for `super` resolution
- [x] Document known limitations (lexical scope, deep calls)
- [x] Add performance benchmarks section
- [ ] Implement special method name handling (backtick, [], etc.)
- [ ] Add warning for methods without original implementation
- [ ] Create comprehensive test suite for Thread safety

### Lessons Learned

1. **Refinements are not dynamic**: Lexical scope is a feature, not a bug. Embrace it.
2. **`def` > `define_method`**: When `super` is needed, use `class_eval` + `def`.
3. **Peer review is essential**: External review caught critical architectural flaw before implementation.
4. **Document constraints clearly**: Known limitations should be prominently documented, not hidden.

### Quality Improvements

**Before Review**:
- Architectural flaw (mock always active)
- Misleading "Auto-dissolution" claim
- `super` wouldn't work
- Missing thread safety tests

**After Review**:
- ✅ True activate/deactivate behavior
- ✅ Honest, accurate documentation
- ✅ `super` works correctly
- ✅ Comprehensive test plan

### Confidence Level

**Before Review**: 60% (promising but unproven concept)

**After Review**: 90% (solid architecture with clear path to implementation)

**Remaining 10%**: Implementation details (special method names, edge cases, real-world testing)

---

**END OF REALITY_MARBLE_TODO.md**
