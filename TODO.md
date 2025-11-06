# TODO: Project Maintenance Tasks

## Code Quality: RuboCop Integration (High Priority)

### Investigation Complete ✓
- [x] Current RuboCop version: 1.21 (outdated, latest: 1.81.7 as of 2025-10-31)
- [x] Status: Installed but **not executed** in default or CI tasks
- [x] Config: Minimal (.rubocop.yml exists with 9 lines, needs expansion)
- [x] Extensions: Not installed (rubocop-performance, rubocop-rake needed)
- [x] Test framework: test-unit (not minitest)
- [x] Ruby version: 3.4 in CI, 3.1+ in gemspec

### Phase 1: Update Dependencies ✅
**Goal**: Upgrade RuboCop and add performance/rake plugins for 2025 best practices

- [x] Centralize all dependencies to pra.gemspec (gemspec-first approach)
  - [x] Add `spec.add_development_dependency "rubocop", "~> 1.81"`
  - [x] Add `spec.add_development_dependency "rubocop-performance", "~> 1.26"`
  - [x] Add `spec.add_development_dependency "rubocop-rake", "~> 0.7"`
  - [x] Minimize Gemfile to `source` + `gemspec` only
  - [x] Document gemspec centralization rule in CLAUDE.md

- [ ] Run bundle install to fetch new versions (待機中 - 他環境で実行)
  - [ ] Execute: `bundle install`
  - [ ] Verify Gemfile.lock is updated with new dependencies
  - [ ] Verify bundle exec works: `bundle exec rubocop --version`

### Phase 2: Expand .rubocop.yml Configuration
**Goal**: Modern 2025 configuration that enforces quality without sacrificing Ruby flexibility

- [ ] Expand .rubocop.yml with comprehensive configuration
  - [ ] Upgrade AllCops section
    - [ ] Change TargetRubyVersion: 3.4 (was 3.1, aligns with CI Ruby 3.4)
    - [ ] Add `NewCops: enable` for automatic adoption of new cops in future versions
  - [ ] Add extension plugin loading
    ```yaml
    require:
      - rubocop-performance
      - rubocop-rake
    ```
  - [ ] Add safe exclusions to prevent false positives
    - Exclude paths: vendor/, build/, .cache/, patch/, storage/ directories
  - [ ] Configure practical metrics thresholds (Ruby flexibility vs enforcement)
    - [ ] Metrics/MethodLength: Max 30 (default 10 is too strict for this project)
    - [ ] Metrics/ClassLength: Max 300 (default 100 is too strict)
    - [ ] Metrics/AbcSize: Max 30 (default 17 is too strict, complex logic exists)
    - [ ] Metrics/ParameterLists: Max 5 (default 4, allow reasonable parameter counts)
  - [ ] Allow Japanese comments in code
    - [ ] Disable Style/AsciiComments (project uses Japanese for clarity)
  - [ ] Preserve existing string style conventions
    - [ ] Keep Style/StringLiterals: double_quotes
    - [ ] Keep Style/StringLiteralsInInterpolation: double_quotes
  - [ ] Reference sources: RuboCop 1.81 docs, Shopify Ruby style guide, Ruby community best practices

### Phase 3: Handle Existing Code Violations
**Goal**: Clean integration with baseline configuration to prevent CI failures

- [ ] Generate baseline violations config
  - [ ] Run: `rubocop --auto-gen-config --no-exclude-limit` (force-exclude all current violations)
  - [ ] Creates .rubocop_todo.yml with exceptions for all current violations
  - [ ] Review generated file and commit it

- [ ] Auto-fix all safe, auto-correctable violations
  - [ ] Run: `rubocop -A --auto-correct-all` (applies safe auto-fixes)
  - [ ] Review Git diff to see changed files (should be primarily whitespace/style)
  - [ ] Verify no behavior changes: Run full test suite `bundle exec rake test`
  - [ ] Commit auto-fixed changes: "Apply automatic RuboCop style corrections"

- [ ] Verify setup and document remaining issues
  - [ ] Run clean rubocop: `bundle exec rubocop`
  - [ ] Should show no errors (violations are in .rubocop_todo.yml)
  - [ ] List and document any remaining violations that cannot be auto-fixed

### Phase 4: Integrate into Rake and CI Tasks
**Goal**: Automated quality checking in development workflow and CI pipeline

- [ ] Update Rakefile for RuboCop execution
  - [ ] Keep `task default: %i[test]` unchanged (development speed priority, optional linting)
  - [ ] Update `task ci: :test` to `task ci: %i[test rubocop]` (enforce in CI)
  - [ ] Add new optional task: `desc "Run all quality checks"; task quality: %i[test rubocop]`
  - [ ] Ensure tasks run sequentially: test → rubocop (tests run first, then linting)

- [ ] Verify CI pipeline integration
  - [ ] Confirm .github/workflows/main.yml runs `bundle exec rake ci`
  - [ ] CI will automatically execute both test and rubocop tasks
  - [ ] No workflow file changes needed (leverage updated rake task)
  - [ ] Test in PR: Verify RuboCop step appears in GitHub Actions output

### Phase 5: Documentation and Team Guidance
**Goal**: Clear guidance for developers about RuboCop integration

- [ ] Update README.md with RuboCop section
  - [ ] Add "Code Quality" or "Linting" section explaining:
    - How to run linter locally: `bundle exec rubocop` or `rake rubocop`
    - How to auto-fix style issues: `rubocop -A`
    - How to ignore specific violations temporarily: `.rubocop_todo.yml` reference
    - What configurations are enforced and philosophy behind them
    - How to propose configuration exceptions with context
  - [ ] Link to RuboCop documentation for detailed rules

- [ ] Create/update CONTRIBUTING.md
  - [ ] Document RuboCop expectations for contributors
  - [ ] RuboCop runs automatically in CI (all PRs must pass)
  - [ ] Developers should run `rubocop -A` before submitting PRs to fix style issues
  - [ ] Explain .rubocop_todo.yml strategy for gradual violation reduction
  - [ ] Note about Japanese comments being allowed

- [ ] Create .rubocop_todo.md (Optional reference)
  - [ ] Document strategy for gradual resolution of .rubocop_todo.yml violations
  - [ ] Plan: Remove 1-2 cops per session from .rubocop_todo.yml as exceptions resolve
  - [ ] Similar to coverage maintenance: incremental improvement over time

### Phase 6: Validation Testing
**Goal**: Confirm everything works end-to-end before marking complete

- [ ] Test local development workflow
  - [ ] Run `bundle exec rake test` - Should pass all tests
  - [ ] Run `bundle exec rake rubocop` - Should pass (or show .rubocop_todo.yml violations)
  - [ ] Run `bundle exec rake ci` - Should execute both test and rubocop successfully
  - [ ] Manually run `rubocop -A --auto-correct-all` - Should have no errors

- [ ] Test CI pipeline with actual commit
  - [ ] Push test commit to feature branch with intentional RuboCop violation
  - [ ] Verify GitHub Actions workflow runs RuboCop step and fails on violation
  - [ ] Verify PR shows RuboCop failure
  - [ ] Fix violation and confirm PR passes
  - [ ] Test that auto-fixable violations are caught: Push code with spacing issue

- [ ] Verify team communication
  - [ ] Announce RuboCop enforcement in project discussions
  - [ ] Provide quick reference for developers: Common RuboCop violations and fixes
  - [ ] Link documentation in CONTRIBUTING.md

## Future Enhancements (Optional)

### CI/CD Integration

- [ ] Branch Protection Rules (Local execution with gh CLI)
  - [ ] Configure branch protection for `main` branch
  - [ ] Require status checks: `test` job must pass
  - [ ] Require branches to be up to date before merging
  - [ ] Optional: Require pull request reviews
  - [ ] Prevent force pushes and deletions

### CLI Command Structure Refactoring

- [ ] Consider renaming commands in future if needed (e.g., `pra build-env` or `pra workspace`)

- [ ] Enhance `pra build setup` for complete build preparation
  - [ ] Add PicoRuby build step (call `rake setup_esp32` via ESP-IDF env)
  - [ ] Ensure `pra build setup` handles all pre-build requirements
  - [ ] Update documentation to reflect `pra build setup` capabilities

- [ ] Update esp32-build.yml template for correct pra command flow
  - [ ] Ensure workflow uses: `pra cache fetch` → `pra build setup` → `pra device build`
  - [ ] Remove internal path exposure (`.cache/*/R2P2-ESP32`)
  - [ ] Remove redundant `pra patch apply` (already done in `pra build setup`)
  - [ ] Validate workflow aligns with local development workflow

- [ ] Add CI/CD update command
  - [ ] Implement `pra ci update` to refresh workflow template
