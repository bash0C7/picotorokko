# Reality Marble Implementation TODO

**Status**: Design Complete (REVISED with Critical Fixes), Ready for Implementation
**Target**: New standalone gem (separate from picotorokko gem)
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

#### Concrete Example (from picotorokko gem)

**Test file** (`test/commands/env_test.rb`, lines 1272-1332):
```ruby
using SystemCommandMocking::SystemRefinement  # ← Refinement declared here

class EnvCommandTest < Test::Unit::TestCase
  def test_init_clones_repository
    # This test calls Env.init which internally calls lib/picotorokko/env.rb code
    Picotorokko::Env.init(env_name: 'test', repo_url: 'https://example.com/repo.git')
    # ...
  end
end
```

**Production code** (`lib/picotorokko/env.rb`, line 111-117):
```ruby
# This file has NO `using` declaration
module Picotorokko
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
2. Test calls `Picotorokko::Env.init` (production code in separate file)
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
- Code in `lib/picotorokko/env.rb` has no `using` declaration
- Therefore, `system()` call inside `lib/picotorokko/env.rb` is NOT refined

**Call chain visualization**:
```
[test/commands/env_test.rb]  ← using declared here
  ↓ calls
[lib/picotorokko/env.rb]             ← NO using here
  ↓ calls
system('git clone ...')      ← Original Kernel#system, NOT refined version
```

### Why This Matters

This limitation affects Reality Marble's **value proposition** and **target use cases**:

#### ❌ Invalid Use Cases (Cannot Work)

1. **Testing production code that makes system calls internally**
   - Example: Testing `Picotorokko::Env.init` which calls `system()` in separate file
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
   - Example: Mock `Picotorokko::Env.init` itself, not the internal `system()` calls

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
# lib/picotorokko/env.rb (BEFORE)
def clone_repo(repo_url, dest_path, commit)
  system("git clone #{Shellwords.escape(repo_url)} ...")
end

# lib/picotorokko/env.rb (AFTER)
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
      Picotorokko::Env.init(env_name: 'test', repo_url: 'https://example.com/repo.git')

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
  Picotorokko::Env.init(env_name: 'test', repo_url: 'https://example.com/repo.git')
  # ↓
end

# Production code (lib/picotorokko/env.rb) - NO using declaration
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

**Problem in 案2**: Refinements cannot reach `lib/picotorokko/env.rb` because it has no `using` declaration.

**Solution in 案3**: TracePoint is **globally active** when enabled.

```ruby
# test/commands/env_test.rb
git_marble.activate do
  # TracePoint is now monitoring ALL method calls in ALL files

  Picotorokko::Env.init(...)
  # ↓ calls
  # lib/picotorokko/env.rb: clone_repo(...)
  # ↓ calls
  # lib/picotorokko/env.rb: system("git clone ...")
  # ↑ TracePoint catches this call even though lib/picotorokko/env.rb has no `using`!
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
       Picotorokko::Env.init(...)  # Crosses into lib/picotorokko/env.rb
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

---

## 🛡️ 案3.1: TracePoint + Temporary Method Redefinition (Ensure-Safe)

### Motivation: Critical User Requirement

**User feedback**: 「全メソッド呼び出しを監視は問題ないけど、横取りしたところの撤回はこのライブラリで保証したいな」

**Translation**: "Monitoring all method calls is acceptable, but the library must guarantee restoration after interception."

**Critical requirement**:
- ✅ `ensure` blocks must execute (resource cleanup guaranteed)
- ✅ Methods must be restored after `activate` ends (no permanent pollution)

### The Fatal Flaw of 案3 (throw/catch)

```ruby
def clone_repo(url, path)
  acquire_lock(path)
  system("git clone #{url} #{path}")  # ← throw :intercept HERE
  release_lock(path)  # ← NEVER EXECUTED
ensure
  cleanup_temp_files(path)  # ← NEVER EXECUTED (stack unwound!)
end
```

**Problem**: `throw` unwinds the stack, skipping both normal code AND `ensure` blocks.

**Impact**: Resource leaks, file handles, database connections, locks not released.

### Solution: Method Redefinition Instead of Stack Unwinding

**Key insight**: If we redefine the method temporarily, execution flow remains normal.

```ruby
# Original implementation (before activate)
module Kernel
  def system(cmd)
    # ... native implementation ...
  end
end

# During activate: TracePoint detects first call → redefine with guard
module Kernel
  def system(cmd)
    ctx = Thread.current[:reality_marble_context]

    if ctx && ctx.has_mock?(Kernel, :system)
      # Execute mock
      ctx.execute_mock(Kernel, :system, cmd)
    else
      # Call original (via saved UnboundMethod)
      RealityMarble.call_original(Kernel, :system, self, cmd)
    end
  end
end

# After activate ends (in ensure block): restore original
module Kernel
  def system(cmd)
    # ← RESTORED to original implementation
  end
end
```

Now `ensure` blocks execute normally:
```ruby
def clone_repo(url, path)
  acquire_lock(path)
  system("git clone ...")  # ← Returns mock value (NO throw)
  release_lock(path)  # ← EXECUTES ✅
ensure
  cleanup_temp_files(path)  # ← EXECUTES ✅ (normal flow)
end
```

### Architecture

```ruby
module RealityMarble
  # Global registry with reference counting for concurrent activations
  @redefinition_registry = {}  # {[Class, :method] => {original:, ref_count:}}
  @registry_mutex = Mutex.new

  class Activation
    def initialize(marble)
      @marble = marble
      @my_redefinitions = []  # Track which methods THIS activation redefined
    end

    def activate(&test_block)
      context = Context.new(@marble.mocks)
      Thread.current[:reality_marble_context] = context

      # TracePoint to detect and redefine methods on first call
      trace = TracePoint.new(:call) do |tp|
        mock = context.find_mock(tp.defined_class, tp.method_id)
        next unless mock

        # Redefine method (with reference counting)
        RealityMarble.redefine_method(tp.defined_class, tp.method_id)
        @my_redefinitions << [tp.defined_class, tp.method_id]
      end

      trace.enable

      begin
        result = test_block.call(context.trace)
        result
      ensure
        trace.disable

        # Restore all methods redefined by THIS activation
        @my_redefinitions.each do |klass, method|
          RealityMarble.restore_method(klass, method)
        end

        Thread.current[:reality_marble_context] = nil
      end
    end
  end

  class << self
    def redefine_method(klass, method_name)
      @registry_mutex.synchronize do
        key = [klass, method_name]

        # Already redefined by another concurrent activation?
        if @redefinition_registry[key]
          @redefinition_registry[key][:ref_count] += 1
          return
        end

        # First time: save original and redefine
        original = klass.instance_method(method_name)
        @redefinition_registry[key] = {
          original: original,
          ref_count: 1
        }

        # Redefine with Thread-local guard
        klass.define_method(method_name) do |*args, **kwargs, &block|
          ctx = Thread.current[:reality_marble_context]

          if ctx && ctx.has_mock?(klass, method_name)
            # Inside activate (this thread) → execute mock
            ctx.execute_mock(klass, method_name, *args, **kwargs, &block)
          else
            # Outside activate OR different thread → call original
            original_method = RealityMarble.get_original(klass, method_name)
            original_method.bind(self).call(*args, **kwargs, &block)
          end
        end
      end
    end

    def restore_method(klass, method_name)
      @registry_mutex.synchronize do
        key = [klass, method_name]
        entry = @redefinition_registry[key]
        return unless entry

        # Decrement reference count
        entry[:ref_count] -= 1

        # Last activation using this method? Restore original
        if entry[:ref_count] == 0
          klass.define_method(method_name, entry[:original])
          @redefinition_registry.delete(key)
        end
      end
    end

    def get_original(klass, method_name)
      @redefinition_registry[[klass, method_name]][:original]
    end
  end
end
```

### How This Solves Key Problems

#### Problem 1: Ensure Blocks Not Executed ✅ SOLVED

**案3 (throw/catch)**:
```ruby
throw :reality_marble_intercept, result
# ↑ Stack unwinds → ensure blocks skipped
```

**案3.1 (method redefinition)**:
```ruby
def system(cmd)
  if ctx
    execute_mock(cmd)  # Returns normally
  else
    original(cmd)  # Returns normally
  end
end
# ↑ Normal execution flow → ensure blocks execute
```

#### Problem 2: Global Pollution ✅ MITIGATED

**Concern**: Redefined methods affect all threads.

**Solution**: Guard checks Thread-local context:
```ruby
# Thread A (test with activate)
Thread.current[:reality_marble_context] = ctx  # Set
system('git')  # → Guard finds ctx → mock executes

# Thread B (other code)
Thread.current[:reality_marble_context]  # nil
system('ls')  # → Guard finds nil → original executes
```

**Verdict**: Global redefinition, but **behavior is thread-local** ✅

#### Problem 3: Permanent Pollution ✅ SOLVED

**Guarantee**: `activate` ensure block always calls `restore_method`.

```ruby
def activate
  # ...
ensure
  @my_redefinitions.each { |k, m| restore_method(k, m) }
end
```

**Even if test crashes**, ensure runs → methods restored ✅

#### Problem 4: Concurrent Activations ✅ SOLVED

**Scenario**:
```ruby
# Thread 1
git_marble.activate { system('git') }  # Redefines Kernel#system

# Thread 2 (overlapping)
git_marble.activate { system('git') }  # Tries to redefine again?
```

**Solution**: Reference counting in global registry:
```ruby
# Thread 1 starts
redefine_method(Kernel, :system)  # ref_count = 1

# Thread 2 starts (overlaps)
redefine_method(Kernel, :system)  # ref_count = 2 (no actual redefinition)

# Thread 1 ends
restore_method(Kernel, :system)  # ref_count = 1 (not yet restored)

# Thread 2 ends
restore_method(Kernel, :system)  # ref_count = 0 → NOW restore
```

**Verdict**: Safe for concurrent activations ✅

### Comparison: 案3 vs 案3.1

| Aspect | 案3 (throw/catch) | 案3.1 (redefinition) |
|--------|-------------------|----------------------|
| **Ensure blocks** | ❌ Not executed | ✅ Always executed |
| **Resource safety** | ❌ Leaks possible | ✅ Guaranteed cleanup |
| **Restoration** | ⚠️ Only if no crash | ✅ Ensured by Ruby ensure |
| **Thread safety** | ⚠️ Complex | ✅ Ref counting + mutex |
| **Global pollution** | ⚠️ During activate only | ⚠️ During activate only |
| **Performance** | 🟡 Medium (TracePoint) | 🟡 Medium (TracePoint + redef) |
| **Complexity** | 🟢 Low | 🟡 Medium (registry) |

### New Challenges in 案3.1

#### Challenge 1: Method Redefinition Overhead ⚠️

**Cost**:
- TracePoint detection: ~5000ns
- `define_method` execution: ~100ns (one-time)
- Mutex synchronization: ~50ns (one-time)

**Impact**: Only pays cost on FIRST call to each mocked method.

**Verdict**: 🟢 Acceptable (one-time cost per method)

#### Challenge 2: Reference Counting Complexity ⚠️

**Risk**: Bugs in ref counting could leave methods redefined permanently.

**Mitigation**:
- Comprehensive tests for concurrent scenarios
- Failsafe: Global `RealityMarble.restore_all` method for emergency cleanup

#### Challenge 3: C Methods Still Problematic ⚠️

**Problem**: C methods like `Kernel#system` cannot be redefined with `define_method`.

```ruby
# This will fail for C methods
Kernel.define_method(:system) { ... }
# => TypeError: can't redefine C method
```

**Solutions**:
1. Use `alias_method` + `define_method` workaround:
   ```ruby
   Kernel.alias_method(:__original_system, :system)
   Kernel.send(:remove_method, :system)
   Kernel.define_method(:system) { |cmd| __original_system(cmd) }
   ```

2. Only support Ruby methods, document C method limitation

**Verdict**: 🟡 Solvable but requires special handling

### Recommendation: 案3.1 vs 案3

**案3.1 advantages**:
- ✅ **User requirement satisfied**: "横取りしたところの撤回を保証"
- ✅ Ensure blocks always execute (critical for production use)
- ✅ Guaranteed restoration even on exceptions

**案3.1 disadvantages**:
- ⚠️ More complex implementation (registry + ref counting)
- ⚠️ C method handling requires workarounds

**Verdict**: 🟢 **案3.1 is superior for production use** — satisfies user's critical requirement for safe interception.

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

## ⚡ 案3.2: Upfront Bulk Redefinition (Peer Review Revision)

### Peer Review Feedback: Critical Flaw in 案3.1

**External AI evaluation identified fatal timing issue**:

> "TracePointで「初回呼び出しを検知してから再定義」は、現在フレームには間に合わない可能性が高く（メソッド解決は既に済んでいる）、1回目は素通りしやすい。"

**Translation**: "TracePoint's 'detect first call then redefine' approach likely cannot intercept the current frame (method resolution already completed), causing the first call to pass through."

### The Fatal Timing Problem

```ruby
# 案3.1 architecture
trace = TracePoint.new(:call) do |tp|
  # This fires AFTER method resolution is complete
  # The current frame is already executing the original method!

  RealityMarble.redefine_method(tp.defined_class, tp.method_id)
  # ↑ This redefinition only affects FUTURE calls, not THIS call
end

trace.enable

# Test code
git_marble.activate do
  system('git clone ...')  # ← First call: TracePoint fires but TOO LATE
                            #   Method resolution already picked original
                            #   → REAL git clone executes! ❌

  system('git status')     # ← Second call: Now uses redefined version
                            #   → Mock executes ✅ (but first call leaked!)
end
```

**Impact**: 🔴 **Critical** — First invocation of each mocked method executes the original implementation, defeating the purpose of mocking.

### Root Cause Analysis

**Method resolution timeline**:
```
1. Ruby VM: Look up method `system` in Kernel
   └─> Find implementation: <original Kernel#system>
2. Ruby VM: Create call frame with this implementation
3. TracePoint :call event fires ← "We are here"
4. Method body begins executing ← "Already too late"
```

**TracePoint callbacks run AFTER step 2**, so redefining the method in step 3 cannot affect the current frame.

### Solution: Upfront Bulk Redefinition

**Key change**: Redefine all target methods **at activate start**, BEFORE any test code runs.

```ruby
class Activation
  def activate(&test_block)
    context = Context.new(@marble.mocks)
    Thread.current[:reality_marble_context] = context

    # ✅ Redefine ALL target methods BEFORE test block runs
    @marble.mocks.each do |(klass, method_name), mock_proc|
      RealityMarble.redefine_method(klass, method_name)
      @my_redefinitions << [klass, method_name]
    end

    # ❌ NO TracePoint needed for interception
    # (TracePoint only for optional diagnostics/tracing)

    begin
      result = test_block.call(context.trace)
      result
    ensure
      # Restore all methods
      @my_redefinitions.each do |klass, method|
        RealityMarble.restore_method(klass, method)
      end

      Thread.current[:reality_marble_context] = nil
    end
  end
end
```

**Timeline now**:
```
1. activate starts
2. Redefine Kernel#system (globally, with Thread-local guard)
3. Test block runs
4. system('git clone ...') is called
   └─> Ruby VM looks up `system` in Kernel
   └─> Finds REDEFINED version (with guard)
   └─> Guard checks Thread.current[:reality_marble_context]
   └─> Context present → Mock executes ✅
5. activate ends (ensure)
6. Restore Kernel#system to original
```

**Verdict**: ✅ **First call is intercepted** — No timing race.

### Enhanced Architecture with Visibility Preservation

**Peer review requirement**: Preserve method visibility, module_function status, and owner resolution.

```ruby
module RealityMarble
  @redefinition_registry = {}  # {[Class, :method] => {original:, visibility:, module_fn:, ref_count:}}
  @registry_mutex = Mutex.new

  class << self
    def redefine_method(klass, method_name)
      @registry_mutex.synchronize do
        key = [klass, method_name]

        # Already redefined?
        if @redefinition_registry[key]
          @redefinition_registry[key][:ref_count] += 1
          return
        end

        # Step 1: Determine owner (where method is actually defined)
        owner = klass.instance_method(method_name).owner

        # Step 2: Save original implementation
        original = owner.instance_method(method_name)

        # Step 3: Save visibility
        visibility = if owner.public_method_defined?(method_name)
                       :public
                     elsif owner.protected_method_defined?(method_name)
                       :protected
                     elsif owner.private_method_defined?(method_name)
                       :private
                     end

        # Step 4: Check if module_function
        is_module_fn = owner.is_a?(Module) &&
                       owner.respond_to?(method_name) &&
                       owner.method(method_name).owner == owner.singleton_class

        # Step 5: Handle C methods (alias → remove → redefine)
        if original.source_location.nil?  # C method
          original_name = :"__rm_original_#{method_name}"
          owner.alias_method(original_name, method_name)
          owner.send(:remove_method, method_name)

          owner.define_method(method_name) do |*args, **kwargs, &block|
            ctx = Thread.current[:reality_marble_context]

            if ctx && ctx.has_mock?(owner, method_name)
              ctx.execute_mock(owner, method_name, *args, **kwargs, &block)
            else
              # Call aliased original
              __send__(original_name, *args, **kwargs, &block)
            end
          end
        else
          # Ruby method (simpler)
          owner.define_method(method_name) do |*args, **kwargs, &block|
            ctx = Thread.current[:reality_marble_context]

            if ctx && ctx.has_mock?(owner, method_name)
              ctx.execute_mock(owner, method_name, *args, **kwargs, &block)
            else
              original.bind(self).call(*args, **kwargs, &block)
            end
          end
        end

        # Step 6: Restore visibility
        case visibility
        when :protected then owner.protected(method_name)
        when :private then owner.private(method_name)
        # :public is default
        end

        # Step 7: Restore module_function if needed
        owner.module_function(method_name) if is_module_fn

        # Step 8: Register
        @redefinition_registry[key] = {
          owner: owner,
          original: original,
          visibility: visibility,
          module_fn: is_module_fn,
          original_name: (original_name if original.source_location.nil?),
          ref_count: 1
        }
      end
    end

    def restore_method(klass, method_name)
      @registry_mutex.synchronize do
        key = [klass, method_name]
        entry = @redefinition_registry[key]
        return unless entry

        # Decrement reference count
        entry[:ref_count] -= 1
        return if entry[:ref_count] > 0

        # Last activation → Restore fully
        owner = entry[:owner]

        if entry[:original_name]
          # C method: Remove redefined → Restore alias → Remove alias
          owner.send(:remove_method, method_name)
          owner.alias_method(method_name, entry[:original_name])
          owner.send(:remove_method, entry[:original_name])
        else
          # Ruby method: Redefine with original
          owner.define_method(method_name, entry[:original])
        end

        # Restore visibility
        case entry[:visibility]
        when :protected then owner.protected(method_name)
        when :private then owner.private(method_name)
        end

        # Restore module_function
        owner.module_function(method_name) if entry[:module_fn]

        @redefinition_registry.delete(key)
      end
    end

    # Emergency restoration (for crashes, debugging)
    def restore_all!
      @registry_mutex.synchronize do
        @redefinition_registry.each do |(klass, method_name), entry|
          # Force restore regardless of ref_count
          # ... (same logic as restore_method)
        end
        @redefinition_registry.clear
      end
    end
  end
end
```

### Key Improvements Over 案3.1

| Aspect | 案3.1 (Lazy TracePoint) | 案3.2 (Upfront) |
|--------|-------------------------|-----------------|
| **First call interception** | ❌ Misses first call | ✅ Catches first call |
| **TracePoint dependency** | ❌ Required (performance hit) | ✅ Optional (diagnostics only) |
| **Timing race** | ❌ Vulnerable | ✅ No race |
| **Performance** | 🟡 TracePoint overhead on every call | ✅ Only redefinition cost at activate start |
| **C method support** | ⚠️ Partial | ✅ Full (alias → remove → redefine) |
| **Visibility preservation** | ❌ Not addressed | ✅ public/protected/private restored |
| **module_function** | ❌ Not addressed | ✅ Detected and restored |
| **Owner resolution** | ⚠️ Assumes target class | ✅ Resolves actual owner (inheritance) |
| **Emergency restoration** | ❌ Not provided | ✅ `restore_all!` for crashes |

### Peer Review Recommendations (Implemented)

1. ✅ **"activate開始時に対象メソッドを前倒しで一括再定義"** (Upfront bulk redefinition at activate start)
2. ✅ **"可視性・別名の復元"** (Visibility and alias restoration)
3. ✅ **"所有者（owner）の特定"** (Owner resolution via `instance_method(:m).owner`)
4. ✅ **"Cメソッド対応"** (C method handling: alias → remove → define_method)
5. ✅ **"TracePoint基本オフ"** (TracePoint optional, not required for interception)
6. ✅ **"緊急退避API"** (Emergency `restore_all!` method)

### Remaining Challenges

#### Challenge 1: Nested activate in Same Thread ⚠️

**Scenario**:
```ruby
git_marble.activate do
  file_marble.activate do
    # Both marbles have redefined methods
    # Which mock executes?
  end
end
```

**Solution**: LIFO stack in Thread-local context:
```ruby
Thread.current[:reality_marble_context_stack] = []

# On activate start
stack = (Thread.current[:reality_marble_context_stack] ||= [])
stack.push(context)

# In guard
def system(cmd)
  stack = Thread.current[:reality_marble_context_stack]
  ctx = stack&.last  # Most recent activation (LIFO)

  if ctx && ctx.has_mock?(Kernel, :system)
    ctx.execute_mock(Kernel, :system, cmd)
  else
    original(cmd)
  end
end

# On activate end (ensure)
stack.pop
```

#### Challenge 2: Mock Conflict in Concurrent Activations ⚠️

**Scenario**:
```ruby
# Thread 1
git_marble.activate { system('git') }  # Mock A

# Thread 2 (overlapping)
other_marble.activate { system('other') }  # Mock B (different!)
```

**Problem**: Both threads redefine the same method globally, but with different mocks.

**Solution**: Context stores mock definition per thread:
```ruby
# Redefined method (shared by all threads)
def system(cmd)
  ctx = Thread.current[:reality_marble_context]

  if ctx && ctx.has_mock?(Kernel, :system)
    # ctx.execute_mock retrieves THIS thread's mock definition
    ctx.execute_mock(Kernel, :system, cmd)
  else
    original(cmd)
  end
end
```

**Each thread's context holds its own mock**, so no conflict.

#### Challenge 3: Refinements Interaction ⚠️

**Problem**: If user code already uses Refinements to modify `system`, our redefinition may override or conflict.

**Detection**:
```ruby
# Check if method was refined
if klass.instance_method(method_name).owner != klass
  warn "RealityMarble: #{klass}##{method_name} may be refined. Behavior undefined."
end
```

**Recommendation**: Document that Reality Marble and Refinements should not be mixed on the same methods.

### Test Coverage Requirements (Peer Review)

1. ✅ **初回呼び出しが必ずモックされる** (First call always mocked)
   - Test: `activate { assert_equal mock_result, system('git') }`

2. ✅ **Cメソッドの再定義と復元** (C method redefinition and restoration)
   - Test: `Kernel#system`, `Kernel#\``, `File.read` (C methods)
   - Verify: Visibility, behavior, restoration after activate

3. ✅ **可視性/残骸なし** (Visibility preservation, no artifacts)
   - Test: `protected`/`private` methods remain so after restoration
   - Test: `module_function` status preserved

4. ✅ **所有者単位** (Owner-level redefinition)
   - Test: Class methods (`singleton_class`) vs instance methods
   - Test: Inherited methods (owner != declaring class)

5. ✅ **例外時の復旧** (Restoration on exception)
   - Test: `activate { raise 'error' }` → Method still restored

6. ✅ **ネスト/並行/競合** (Nesting, concurrency, conflicts)
   - Test: Nested `activate` (same thread, LIFO)
   - Test: Concurrent `activate` (different threads, isolated contexts)
   - Test: Conflicting mocks (different definitions, same method)

7. ✅ **性能** (Performance)
   - Benchmark: Redefinition cost at activate start (one-time)
   - Benchmark: Guard overhead per call (~Thread-local lookup + branch)
   - Compare: 案3.2 vs 案2 (should be closer than 案3.1)

### Performance Estimation

**案3.2 costs**:
- **Activate start**: N × (owner resolution + alias/define_method) ≈ N × 500ns
  - For 10 mocked methods: ~5µs (one-time)
- **Per call**: Thread-local lookup + branch ≈ 50ns
  - vs 案2 (Refinements): ~161ns
  - vs 案3.1 (TracePoint): ~5000ns

**Verdict**: 🟢 **案3.2 is ~3x faster than 案2 per call, ~100x faster than 案3.1**

### Final Comparison: 案2 vs 案3.1 vs 案3.2

| Aspect | 案2 (Refinements) | 案3.1 (Lazy TracePoint) | 案3.2 (Upfront) |
|--------|-------------------|-------------------------|-----------------|
| **File boundary** | ❌ Cannot cross | ✅ Can cross | ✅ Can cross |
| **First call** | ✅ Intercepted | ❌ Misses | ✅ Intercepted |
| **Ensure blocks** | ✅ Execute | ✅ Execute | ✅ Execute |
| **Restoration** | ✅ Automatic (lexical) | ✅ Ensured | ✅ Ensured |
| **Performance (per call)** | 🟡 ~161ns | ❌ ~5000ns | ✅ ~50ns |
| **TracePoint** | ❌ Not used | ❌ Required | ✅ Optional |
| **C methods** | ⚠️ Limited | ⚠️ Complex | ✅ Full support |
| **Visibility** | ✅ Preserved (Refinements) | ❌ Not handled | ✅ Preserved |
| **Complexity** | 🟢 Low (Ruby native) | 🟡 Medium | 🟡 Medium-High |
| **Production ready** | ⚠️ Scope-limited | ❌ Timing bug | ✅ Yes |

### Recommendation: 案3.2 is the Production Candidate

**Verdict**: 🎯 **案3.2 (Upfront Bulk Redefinition) is the recommended architecture for production use.**

**Rationale**:
1. ✅ Solves Production Code Boundary Problem (案2's fatal flaw)
2. ✅ Solves First Call Timing Problem (案3.1's fatal flaw)
3. ✅ Satisfies user requirement: "横取りしたところの撤回を保証" (guaranteed restoration)
4. ✅ Fast: ~50ns per call (vs 161ns for 案2, 5000ns for 案3.1)
5. ✅ Comprehensive: C methods, visibility, owner resolution, emergency restore
6. ✅ Thread-safe: Context isolation + reference counting + mutex

**Implementation priority**: 案3.2 > 案2 > 案3.1

**Next steps**:
1. Implement Phase 0 proof-of-concept for 案3.2
2. Test critical edge cases (C methods, visibility, nested activate)
3. Benchmark real-world performance
4. Compare against 案2 for "test helper" use cases (where 案2 may still be simpler)
5. Consider hybrid: 案2 for test files, 案3.2 for production code interception

---

## 🎓 Reality Check: How Picotorokko Gem Actually Solved the Problem

### Context: After Merging origin/main (Session 7)

After designing 案2, 案3.1, and 案3.2, we merged `origin/main` (commit b9a63b0) which contains the **actual implementation** of how the Picotorokko gem solved the Production Code Boundary Problem.

**Key changes in origin/main**:
- Commit 4815ae5: "Phase 0 (INFRASTRUCTURE-SYSTEM-MOCKING-REFACTOR) COMPLETED"
- Added `lib/picotorokko/executor.rb` (75 lines)
- Refactored `lib/picotorokko/env.rb` to use executor abstraction
- Updated `test/commands/env_test.rb` to use MockExecutor
- Removed SystemCommandMocking module (Refinements-based mocking)
- Added `docs/architecture/executor-abstraction-design.md` documentation (later moved from `docs/PHASE_0_EXECUTOR_ABSTRACTION.md`)

### The Actual Solution: Dependency Injection Pattern

**What was implemented**: **案2's "Option 2: Production Code Refactoring (Dependency Injection)"**

This is the exact approach documented in REALITY_MARBLE_TODO.md at line 499-530 under "Production Code Boundary Problem → Option 2".

#### Architecture

```ruby
# lib/picotorokko/executor.rb (NEW)
module Picotorokko
  module Executor
    def execute(command, working_dir = nil)
      raise NotImplementedError
    end
  end

  class ProductionExecutor
    include Executor
    def execute(command, working_dir = nil)
      stdout, stderr, status = Open3.capture3(command)
      raise "Command failed..." unless status.success?
      [stdout, stderr]
    end
  end

  class MockExecutor
    include Executor
    def initialize
      @calls = []
      @results = {}
    end

    def execute(command, working_dir = nil)
      @calls << { command: command, working_dir: working_dir }
      if @results[command]
        stdout, stderr, should_fail = @results[command]
        raise "Command failed..." if should_fail
        return [stdout, stderr]
      end
      ["", ""]  # Default success
    end

    def set_result(command, stdout: "", stderr: "", fail: false)
      @results[command] = [stdout, stderr, fail]
    end

    attr_reader :calls
  end
end
```

#### Refactored Production Code

```ruby
# lib/picotorokko/env.rb (REFACTORED)
module Picotorokko
  class Env
    class << self
      # Executor management (NEW)
      def set_executor(executor)
        @executor = executor
      end

      def executor
        @executor ||= ProductionExecutor.new
      end

      # Refactored to use executor (BEFORE: system() calls)
      def clone_repo(repo_url, dest_path, commit)
        cmd = "git clone #{Shellwords.escape(repo_url)} #{Shellwords.escape(dest_path)}"
        executor.execute(cmd)  # ← NEW: Uses injected executor

        cmd = "git checkout #{Shellwords.escape(commit)}"
        executor.execute(cmd, dest_path)
      end

      def execute_with_esp_env(command, working_dir = nil)
        executor.execute(command, working_dir)  # ← NEW
      end
    end
  end
end
```

#### Test Usage

```ruby
# test/commands/env_test.rb (UPDATED)
test "clone_repo raises error when git clone fails" do
  # 1. Create mock executor
  mock_executor = Picotorokko::MockExecutor.new

  # 2. Configure failure
  mock_executor.set_result(
    "git clone https://github.com/test/repo.git dest",
    fail: true,
    stderr: "fatal: could not read Username"
  )

  # 3. Inject mock (save original for restoration)
  original_executor = Picotorokko::Env.executor
  Picotorokko::Env.set_executor(mock_executor)

  begin
    # 4. Test failure path
    error = assert_raise(RuntimeError) do
      Picotorokko::Env.clone_repo("https://github.com/test/repo.git", "dest", "abc1234")
    end

    # 5. Verify
    assert_include error.message, "Command failed"
    assert_equal 1, mock_executor.calls.length
    assert_include mock_executor.calls[0][:command], "git clone"
  ensure
    # 6. Restore original executor
    Picotorokko::Env.set_executor(original_executor)
  end
end
```

### Why This Approach Was Chosen

**Decision rationale** (documented in `docs/architecture/executor-abstraction-design.md`):

1. ✅ **Testability**: 3 previously omitted tests (lines 1206, 1239, 1275) now passing
2. ✅ **Branch coverage**: Error handling paths now testable
3. ✅ **No global pollution**: Mock is scoped to individual tests (explicit injection)
4. ✅ **Clear ownership**: Each test explicitly manages executor lifecycle
5. ✅ **Industry standard**: DI is well-understood pattern
6. ✅ **Production code clarity**: `executor.execute()` makes external dependency explicit

**What was rejected**:
- ❌ **Refinements (案2)**: Cannot cross file boundaries
- ❌ **TracePoint (案3/案3.1/案3.2)**: Too complex for this specific use case

### Comparison: Reality Marble Proposals vs Actual Solution

| Aspect | 案2 (Refinements) | 案3.2 (Upfront) | **Actual (DI)** |
|--------|-------------------|-----------------|-----------------|
| **File boundary** | ❌ Cannot cross | ✅ Can cross | ✅ Not applicable |
| **First call** | ✅ Intercepted | ✅ Intercepted | ✅ Controlled |
| **Complexity** | 🟢 Low | 🟡 Medium-High | 🟢 **Very Low** |
| **Production changes** | ✅ None needed | ✅ None needed | ⚠️ **Requires refactor** |
| **Test explicitness** | 🟡 `using` declaration | 🟡 `activate` block | ✅ **Explicit injection** |
| **Scope** | 🟢 Lexical (safe) | ⚠️ Global (guarded) | 🟢 **Test-local** |
| **Performance** | 🟡 ~161ns/call | ✅ ~50ns/call | ✅ **~10ns/call** (direct call) |
| **Maintenance** | 🟡 Moderate | 🔴 High | 🟢 **Low** |
| **Learning curve** | 🟡 Refinements | 🔴 TracePoint magic | 🟢 **Standard OOP** |

### Key Insights

#### 1. Context Matters

**Reality Marble focus**: Generic mocking library for any Ruby project
**picotorokko gem context**: Internal testing of 10-20 system commands in a single codebase

**Verdict**: For picotorokko gem's specific use case, **DI is simpler and sufficient**.

#### 2. "Perfect is the Enemy of Good"

**Reality Marble ambition**: Zero-intrusion, no production code changes
**picotorokko gem reality**: Small, focused refactor (75-line abstraction) solved the problem completely

**Verdict**: **Pragmatic DI beats ambitious but complex solutions** for this scope.

#### 3. Reality Marble Still Has Value

**Where DI falls short**:
- ❌ Cannot mock third-party gems (no control over their code)
- ❌ Cannot mock standard library calls (`File.read`, `Dir.glob`) without extensive refactoring
- ❌ Requires production code modification (not acceptable for libraries)

**Where Reality Marble excels**:
- ✅ **Library/gem development**: Cannot modify user's production code
- ✅ **Third-party mocking**: Mock gems you don't control
- ✅ **Exploratory testing**: Rapidly mock without refactoring

**Example use case**:
```ruby
# Testing a gem that uses Net::HTTP internally (you can't modify gem code)
http_marble = RealityMarble.chant do
  mock Net::HTTP, :get do |uri|
    '{"status": "mocked"}'
  end
end

http_marble.activate do
  # ThirdPartyGem internally calls Net::HTTP.get
  result = ThirdPartyGem.fetch_data("https://api.example.com")
  assert_equal "mocked", JSON.parse(result)["status"]
end
```

### Recommendation: When to Use Which Approach

#### Use DI Pattern (Actual pra Solution) When:
- ✅ You control the production codebase
- ✅ Only a few methods need mocking (10-20 commands)
- ✅ Team values explicitness and simplicity
- ✅ Mocking is internal to your project

**Implementation cost**: Low (one-time 75-line abstraction + per-method refactor)

#### Use Reality Marble (案3.2) When:
- ✅ Developing a library/gem (cannot modify user code)
- ✅ Need to mock third-party dependencies
- ✅ Hundreds of methods need mocking (high DI refactor cost)
- ✅ Exploratory testing / rapid prototyping
- ✅ Want a reusable mocking solution across projects

**Implementation cost**: High (complex registry, visibility preservation, C methods)

#### Never Use (Rejected):
- ❌ 案2 (Refinements): Production Code Boundary Problem is fatal
- ❌ 案3/案3.1 (TracePoint throw/catch): Ensure blocks not executed, first call timing issue

### Updated Reality Marble Roadmap

**Phase 0**: Proof-of-concept for 案3.2
- Focus: C methods, visibility, nested activate
- Goal: Validate complexity vs. value tradeoff

**Phase 1**: Minimal viable implementation
- Core: Upfront redefinition, Thread-local guard, restoration
- Scope: Ruby methods only (defer C methods)

**Phase 2**: Production hardening
- Add: C method support, visibility preservation, emergency restore
- Test: Concurrent activation, nested contexts, edge cases

**Phase 3**: Ecosystem integration
- Documentation: Clear use case guidance (when DI is better)
- Examples: Third-party gem mocking, library development

**Decision gate**: After Phase 0 PoC, **reassess if complexity is justified** compared to DI pattern.

### Conclusion: Lessons Learned

1. **DI is often good enough** — For internal projects with controlled codebases, simple beats clever.

2. **Reality Marble has a niche** — Library development, third-party mocking, exploratory testing justify the complexity.

3. **案3.2 is the right architecture** — If Reality Marble is built, 案3.2 (Upfront Bulk Redefinition) is the only viable approach.

4. **Don't build it unless needed** — picotorokko gem chose wisely: solve the specific problem (3 failing tests) with the simplest solution (DI).

**Final verdict**: Reality Marble remains **a valid design exercise** and **potential future gem**, but for picotorokko gem specifically, **DI was the correct choice**.

---

## 🌑 案4: Prism AST Transformation + Black Magic Hybrid (Ruby 3.4+ Era)

### Motivation: The Next Generation Approach

After exploring Refinements (案2), TracePoint interception (案3/案3.1), and method redefinition (案3.2), and seeing how picotorokko solved it pragmatically with DI, **let's push the boundaries** with Ruby 3.4+'s cutting-edge features.

**User's vision**:
> 「TracePoint、Refinements、メタプログラミング、Prismでのparse/構文木レベルの加工を駆使して、特殊なmockメソッドを用いず、特定のテストファイル・テストケースだけに閉じたmock/stubを実現する、Ruby3.4以降専用の新時代のライブラリ」

**Translation**: "A next-generation library using TracePoint, Refinements, metaprogramming, and Prism AST manipulation—requiring NO special mock methods, scoped only to specific test files/cases, Ruby 3.4+ exclusive."

### The Black Magic Stack

**案4 combines ALL the dark arts**:
1. **Prism** (Ruby 3.3+): AST parsing and transformation at load-time
2. **Refinements** (Ruby 2.0+): Lexical scoping for safe method overrides
3. **TracePoint** (Ruby 1.9+): Runtime call interception and monitoring
4. **Metaprogramming**: `define_method`, `class_eval`, `instance_exec`
5. **Ruby 3.4+**: Frozen string literals, pattern matching, improved AST APIs

### Core Idea: Transparent Test-Time Source Rewriting

**The magic**: User writes normal test code, but Reality Marble *transforms* it at load-time to inject mocking infrastructure—**invisibly**.

```ruby
# USER WRITES (no changes needed, no mock API):
class GitTest < Test::Unit::TestCase
  def test_git_clone_success
    system('git clone https://example.com/repo.git dest')
    assert File.exist?('dest/.git')
  end
end

# REALITY MARBLE TRANSFORMS (transparent to user):
class GitTest < Test::Unit::TestCase
  def test_git_clone_success
    __rm_context = RealityMarble.test_context(self)
    __rm_context.activate do
      system('git clone https://example.com/repo.git dest')  # ← Mocked via Refinements
      assert File.exist?('dest/.git')                         # ← Also mocked
    end
  ensure
    __rm_context.teardown
  end
end
```

**Key insight**: Test code looks unchanged, but Reality Marble injects context management via Prism AST rewriting.

### Architecture

#### Phase 1: Load-Time Interception (Prism Hook)

When `require 'reality_marble'` is executed:

```ruby
# lib/reality_marble.rb
require 'prism'

module RealityMarble
  # Hook into Ruby's require mechanism
  module RequireHook
    def require(path)
      if test_file?(path)
        # Intercept test file loading
        source = File.read(resolve_path(path))
        transformed = RealityMarble::ASTTransformer.transform(source, path)

        # Evaluate transformed code instead of original
        eval(transformed, TOPLEVEL_BINDING, path, 1)
        true
      else
        super
      end
    end

    private

    def test_file?(path)
      path.end_with?('_test.rb') || path.include?('/test/')
    end
  end

  # Install hook globally
  Object.prepend(RequireHook)
end
```

#### Phase 2: AST Transformation (Prism Parser)

Parse test file and inject Reality Marble infrastructure:

```ruby
module RealityMarble
  class ASTTransformer
    def self.transform(source, filename)
      parsed = Prism.parse(source)
      rewriter = TestMethodRewriter.new(filename)

      # Visit AST and rewrite test methods
      rewriter.visit(parsed.value)

      # Generate transformed source
      rewriter.result
    end
  end

  class TestMethodRewriter < Prism::Visitor
    def initialize(filename)
      @filename = filename
      @transformed_source = []
    end

    def visit_def_node(node)
      method_name = node.name

      if test_method?(method_name)
        # Wrap test method body with Reality Marble context
        @transformed_source << generate_wrapped_method(node)
      else
        # Keep original method as-is
        @transformed_source << node.source
      end

      super
    end

    private

    def test_method?(name)
      name.to_s.start_with?('test_')
    end

    def generate_wrapped_method(node)
      # Extract method body
      body_source = extract_body_source(node)

      # Wrap with Reality Marble context
      <<~RUBY
        def #{node.name}
          __rm_context = RealityMarble.test_context(self, :#{node.name})
          __rm_context.activate do
            #{body_source}
          end
        ensure
          __rm_context.teardown
        end
      RUBY
    end

    def extract_body_source(node)
      # Extract original method body source
      node.body&.location&.slice || ""
    end
  end
end
```

#### Phase 3: Runtime Context (Refinements + TracePoint)

Reality Marble context manages mocking infrastructure:

```ruby
module RealityMarble
  class TestContext
    def initialize(test_case, test_method)
      @test_case = test_case
      @test_method = test_method
      @refinement = build_refinement
      @trace = Trace.new
    end

    def activate(&block)
      # Enable Refinements for this test
      @test_case.singleton_class.class_eval do
        using @refinement
      end

      # Enable TracePoint for monitoring
      trace_point = TracePoint.new(:call) do |tp|
        @trace.record(tp) if mockable_method?(tp)
      end

      trace_point.enable

      begin
        yield
      ensure
        trace_point.disable
      end
    end

    def teardown
      @trace.clear
    end

    private

    def build_refinement
      trace = @trace

      Module.new do
        refine Kernel do
          def system(cmd)
            # Auto-mock system() calls
            trace.record_call(Kernel, :system, cmd)

            # Return mocked result based on test expectations
            RealityMarble.mock_result_for(Kernel, :system, cmd) || super
          end
        end

        refine File.singleton_class do
          def read(path)
            # Auto-mock File.read calls
            trace.record_call(File, :read, path)

            RealityMarble.mock_result_for(File, :read, path) || super
          end

          def exist?(path)
            # Auto-mock File.exist? calls
            trace.record_call(File, :exist?, path)

            RealityMarble.mock_result_for(File, :exist?, path) || super
          end
        end
      end
    end

    def mockable_method?(tp)
      MOCKABLE_METHODS.include?([tp.defined_class, tp.method_id])
    end

    MOCKABLE_METHODS = [
      [Kernel, :system],
      [Kernel, :`],
      [File, :read],
      [File, :write],
      [File, :exist?],
      [Dir, :glob],
      # ... etc
    ]
  end
end
```

#### Phase 4: Expectation DSL (Optional, for advanced users)

While default behavior is transparent, power users can set expectations:

```ruby
# In test setup or before_all
RealityMarble.expect(Kernel, :system) do |cmd|
  case cmd
  when /git clone/ then true
  when /git checkout/ then false
  else nil  # Fall through to original
  end
end

RealityMarble.expect(File, :exist?) do |path|
  path == 'dest/.git'  # Mock this specific path
end
```

### Key Advantages of 案4

| Aspect | 案2 (Refinements) | 案3.2 (Upfront) | DI (Actual) | **案4 (Prism Hybrid)** |
|--------|-------------------|-----------------|-------------|------------------------|
| **User code changes** | ⚠️ `using` per file | ✅ None | ❌ Refactor needed | ✅ **None (transparent)** |
| **File boundary** | ❌ Cannot cross | ✅ Can cross | ✅ Not applicable | ✅ **Can cross (Refinements)** |
| **Scope** | 🟢 Lexical | ⚠️ Global (guarded) | 🟢 Test-local | 🟢 **Test-method-local** |
| **Mock API** | ⚠️ `refine`/`def` | ⚠️ `activate` | ⚠️ Inject executor | ✅ **None (auto)** |
| **Ruby 3.4+ features** | ❌ Not leveraged | ❌ Not leveraged | ❌ Not leveraged | ✅ **Prism, frozen strings** |
| **Black magic level** | 🟡 Medium | 🟡 Medium | 🟢 None | 🔴 **MAXIMUM** |
| **Debugging** | 🟢 Easy | 🟡 Moderate | 🟢 Easy | 🔴 **Nightmare** |
| **Cool factor** | 🟡 Moderate | 🟡 Moderate | 😴 Boring | 🌟 **LEGENDARY** |

### Critical Challenges

#### Challenge 1: Source Location Mismatch 🔴 CRITICAL

**Problem**: Transformed code has different line numbers than original.

**Impact**: Stack traces point to wrong lines, debugging is nearly impossible.

**Example**:
```ruby
# Original (user writes):
def test_foo
  system('git')  # Line 5
  assert true
end

# Transformed (Reality Marble generates):
def test_foo
  __rm_context = RealityMarble.test_context(self, :test_foo)  # Line 5
  __rm_context.activate do                                     # Line 6
    system('git')  # Line 7 (was line 5!)
    assert true    # Line 8 (was line 6!)
  end
ensure
  __rm_context.teardown
end
```

**Mitigation options**:
1. Preserve line numbers with `eval(code, binding, filename, original_line)`
2. Generate source map (like JavaScript transpilers)
3. Use `set_trace_func` to correct stack traces on-the-fly

**Verdict**: 🟡 Solvable but complex

#### Challenge 2: Editor Support ❌ IMPOSSIBLE

**Problem**: IDEs/editors see original code, but Ruby executes transformed code.

**Impact**:
- Autocomplete broken (doesn't know about `__rm_context`)
- Go-to-definition jumps to wrong location
- Linters complain about undefined variables

**Mitigation**: Document as "use plain text editor" or "disable linting in tests"

**Verdict**: 🔴 Fundamental limitation

#### Challenge 3: Prism API Stability ⚠️ RISKY

**Problem**: Prism is relatively new (Ruby 3.3+), APIs may change.

**Impact**: Reality Marble breaks on Ruby version updates.

**Mitigation**: Pin to specific Prism versions, provide migration guides.

**Verdict**: 🟡 Manageable with version pinning

#### Challenge 4: Performance Overhead 🟡 MODERATE

**Costs**:
- Load-time: Prism parsing + AST rewriting (~10-50ms per test file)
- Runtime: Refinements + TracePoint (~50-5000ns per call)

**Impact**: Test suite 10-20% slower.

**Verdict**: 🟡 Acceptable for test context

#### Challenge 5: Metaprogramming Complexity 🔴 EXTREME

**Problem**: Multiple layers of indirection (Prism → Refinements → TracePoint → Metaprogramming).

**Impact**:
- Extremely difficult to maintain
- Bug fixes require deep Ruby internals knowledge
- Contributors must understand 4+ advanced Ruby features

**Verdict**: 🔴 Only for Ruby wizards

### When to Use 案4

**Use 案4 when**:
- ✅ You want **zero test code changes** (transparent mocking)
- ✅ You need to mock **third-party gems** (Refinements reach them)
- ✅ You're comfortable with **bleeding-edge Ruby** (3.4+)
- ✅ You value **coolness** over **simplicity**
- ✅ Your team has **Ruby black magic expertise**

**DO NOT use 案4 when**:
- ❌ You need **debuggable tests** (stack traces will lie)
- ❌ Your team values **maintainability** (this is a nightmare)
- ❌ You want **editor support** (won't work)
- ❌ You're on Ruby <3.4 (Prism not available)
- ❌ You prefer **pragmatic solutions** (use DI or 案3.2)

### Proof of Concept: Minimal 案4

Here's a minimal PoC to validate the approach:

```ruby
# lib/reality_marble.rb
require 'prism'

module RealityMarble
  @mock_expectations = {}

  class << self
    attr_reader :mock_expectations

    def expect(klass, method, &block)
      @mock_expectations[[klass, method]] = block
    end

    def mock_result_for(klass, method, *args)
      expectation = @mock_expectations[[klass, method]]
      expectation&.call(*args)
    end
  end

  # Prism transformer
  class TestTransformer
    def self.transform(source)
      parsed = Prism.parse(source)
      # ... (AST transformation logic)
    end
  end

  # Require hook
  module RequireHook
    def require(path)
      if path.end_with?('_test.rb')
        source = File.read(path + '.rb')
        transformed = TestTransformer.transform(source)
        eval(transformed, TOPLEVEL_BINDING, path, 1)
        true
      else
        super
      end
    end
  end

  Object.prepend(RequireHook)
end
```

### Recommendation: 案4 is a Research Project

**Verdict**: 🧪 **案4 is fascinating but impractical for production use.**

**Rationale**:
1. Debugging is prohibitively difficult (source location mismatch)
2. Editor support is impossible (transformed code invisible)
3. Maintenance burden is extreme (4+ advanced Ruby features)
4. Prism API stability is uncertain (Ruby 3.3+ only)

**Better path**:
- **For picotorokko**: Stick with DI (proven, simple, works)
- **For general library**: Use 案3.2 (practical, fast, safe)
- **For research**: Implement 案4 as academic exercise/proof-of-concept

**However**: If you're building a **Ruby metaprogramming showcase** or **want to push Ruby's limits**, 案4 is the ultimate challenge. Just don't use it in production. 😈

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

### Phase 6: Integration with picotorokko gem (This Project)

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

## Migration Guide (for picotorokko gem)

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

- [ ] picotorokko gem migration complete (Phase 6)
- [ ] Blog post written (Japanese + English)
- [ ] Community feedback collected
- [ ] GitHub issues addressed
- [ ] v0.2.0 planning (based on feedback)

---

## Contact & Contribution

**Maintainer**: bash0C7 (from picotorokko gem project)
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
- Most picotorokko gem tests use Test::Unit
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
