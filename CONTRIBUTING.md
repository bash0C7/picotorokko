# Contributing to pra

Thank you for your interest in contributing to pra!

## Development Setup

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/picoruby-application-on-r2p2-esp32-development-kit.git
   cd picoruby-application-on-r2p2-esp32-development-kit
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Run tests:
   ```bash
   bundle exec rake test
   ```

## Setting Up Git Hooks

Git hooks help catch code quality issues before pushing to the remote. The repository includes a pre-commit hook that automatically runs checks on your local machine.

### Automatic Setup

The git hooks are located in `.git/hooks/` and are automatically executable. They will run before each commit.

### Manual Hook Setup (if needed)

If the hooks are not executable, make them executable manually:

```bash
chmod +x .git/hooks/pre-commit
```

### What the Pre-Commit Hook Does

Before each commit, the pre-commit hook automatically runs:

1. **RuboCop** - Auto-fix code style violations
2. **Test Suite** - Run all tests to ensure nothing is broken

If either step fails, the commit is blocked until issues are resolved.

### Running Checks Manually

You can also run the checks manually before committing:

```bash
# Run RuboCop + tests (same as pre-commit hook)
bundle exec rake pre-commit

# Or run them separately:
bundle exec rubocop -A     # Auto-fix style issues
bundle exec rake test      # Run tests only
```

### Bypassing the Hook (Not Recommended)

If you need to bypass the pre-commit hook for testing purposes only, use:

```bash
git commit --no-verify
```

**Note**: This should only be used in exceptional cases. All commits to the main branch still go through CI checks.

## Running Tests

We use test-unit for testing. To run the test suite:

```bash
bundle exec rake test
```

### Test Coverage

We aim for 90% code coverage. Coverage reports are generated automatically when running tests:

```bash
bundle exec rake test
# Coverage report: coverage/index.html
```

SimpleCov will fail the build if coverage drops below 90%.

## Code Style

We use RuboCop for code style enforcement. Check and auto-fix style issues before submitting:

```bash
bundle exec rubocop -A
```

RuboCop runs automatically in CI as part of `bundle exec rake ci`.

## Submitting Changes

1. Create a new branch for your feature or bugfix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and add tests

3. Ensure all tests pass and coverage is maintained:
   ```bash
   bundle exec rake test
   ```

4. Commit your changes with a clear message:
   ```bash
   git commit -m "Add feature: description of your changes"
   ```

5. Push to your fork and create a pull request

## Release Process

Releases are managed through GitHub Actions with manual workflow dispatch.

### Prerequisites

- Maintainer access to the repository
- `RUBYGEMS_API_KEY` configured in GitHub Secrets

### Creating a Release

1. Go to **Actions** → **Release** workflow in GitHub
2. Click **Run workflow**
3. Enter the version number (e.g., `0.2.0`)
4. Choose whether to perform a dry run (recommended first)
5. Click **Run workflow**

The workflow will:
- Validate version format (must be X.Y.Z)
- Update `lib/pra/version.rb`
- Run test suite
- Build the gem
- Commit version bump to main branch
- Create a Git tag
- Publish to RubyGems.org
- Create GitHub Release with auto-generated notes

### Dry Run

Before releasing, it's recommended to do a dry run:
1. Run the workflow with **dry_run** checked
2. Review the dry run output
3. If everything looks good, run again without dry run

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

## Setting Up RubyGems API Key

For maintainers releasing to RubyGems:

1. Generate API key from [RubyGems.org](https://rubygems.org/profile/api_keys)
2. Add as `RUBYGEMS_API_KEY` in GitHub repository secrets
3. The release workflow will use this key automatically

## Branch Protection Settings

To ensure code quality, configure branch protection rules for the `main` branch:

### Setting Up Branch Protection

1. Go to **Settings** → **Branches** in the GitHub repository
2. Click **Add branch protection rule**
3. Enter `main` as the branch name pattern
4. Configure the following settings:

#### Required Status Checks

- ☑️ **Require status checks to pass before merging**
  - ☑️ **Require branches to be up to date before merging**
  - Add required status check: `test` (from the Ruby CI workflow)

#### Additional Recommended Settings

- ☑️ **Require a pull request before merging**
  - Require approvals: 1 (optional for small teams)
- ☑️ **Require conversation resolution before merging**
- ☑️ **Do not allow bypassing the above settings** (for stricter enforcement)

### What This Prevents

- Merging PRs with failing tests
- Merging PRs with insufficient test coverage (CI enforces 80% line coverage minimum)
- Merging without code review (if approvals are required)
- Force pushes to main branch

### CI Workflow Details

The `test` job in `.github/workflows/main.yml` runs:
- Full test suite via `bundle exec rake ci`
- Coverage validation (minimum 80% line coverage, 50% branch coverage)
- Codecov upload for coverage tracking

When the `test` job fails, the PR cannot be merged until issues are resolved.

## Questions?

Feel free to open an issue for questions or discussions!
