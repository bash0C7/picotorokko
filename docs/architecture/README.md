# Architecture Documentation

This directory contains design documentation for key architectural patterns and decisions in the picotorokko gem.

## Documents

### [Executor Abstraction for System Command Testing](executor-abstraction-design.md)

**Problem**: Ruby Refinements' lexical scoping limitation prevents effective mocking of `system()` calls across code boundaries.

**Solution**: Dependency injection pattern with abstracted executor interface, enabling testable design without global state pollution.

**Key Concepts**:
- ProductionExecutor using Open3.capture3
- MockExecutor for test isolation
- Dependency injection via Picotorokko::Env

**When to Reference**:
- Understanding how system commands are executed in tests
- Implementing new commands that need testing
- Designing test helpers for command execution

---

### [Prism-Based Rakefile Parser for Dynamic Task Generation](prism-rakefile-parser-design.md)

**Problem**: Device commands need to delegate to R2P2-ESP32 Rakefile tasks, including dynamically generated tasks via `.each` loops, while preventing arbitrary command execution.

**Solution**: AST-based static analysis using Prism to extract task whitelist, without executing any code.

**Key Concepts**:
- Prism visitor pattern for AST traversal
- Pattern expansion for dynamic task generation
- Whitelist-based validation in method_missing
- Security through limitation (no eval)

**When to Reference**:
- Understanding how device task delegation works
- Modifying device command behavior
- Extending task parsing for new patterns

---

### [AST-Based Template Engine](AST_TEMPLATE_ENGINE_SPEC.md)

**Problem**: ERB-based template generation breaks syntax validity and lacks semantic understanding, making templates fragile and hard to maintain.

**Solution**: Syntax-aware template transformation using AST parsers (Prism for Ruby, Psych for YAML, regex for C) with placeholder-based substitution.

**Key Concepts**:
- Ruby templates: Prism AST visitor pattern with code generation
- YAML templates: Recursive object traversal with Psych
- C templates: String substitution with regex
- Unified Engine interface for all template types

**When to Reference**:
- Understanding mrbgem template generation
- Adding new template types
- Debugging template transformation issues
- Implementing custom template engines

---

## Related Phases

These architecture documents support ongoing feature development:

- **Phase 0** (completed): Executor abstraction foundation for testable command execution
- **Phase 1** (in progress): Device integration using executor pattern
- **Phase 5** (completed): Prism parser implementation for dynamic Rake task extraction

---

## Design Principles

All architecture documents in this directory embody these principles:

1. **Evidence-Based**: Decisions documented with specific problems and measured results
2. **Sustainable**: Focus on long-term maintainability, not short-term convenience
3. **Minimal**: Complexity only where necessary; simplicity by default
4. **Testable**: Design enables comprehensive test coverage
5. **Secure**: Security considerations explicitly addressed

---

## Contributing

When creating new architecture documents:

1. Start with **Problem Statement** - what was the challenge?
2. Explain the **Solution** - what pattern/approach was chosen?
3. Document **Key Design Decisions** - why this way and not alternatives?
4. Reference **Concrete Examples** - show real usage from the codebase
5. Include **Related Work** - how does this connect to other systems?

This format helps future developers understand not just *what* was built, but *why*.
