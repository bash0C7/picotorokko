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
- 🔧 Available manual tasks: `rake rubocop` (linting, not in CI)
