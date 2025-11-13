# PicoRuby ptrk User Testing Playground

This directory is a sandbox for testing the `picotorokko` (ptrk) gem **as a PicoRuby application developer would use it**.

From the user's perspective, they have already installed the `picotorokko` gem and are now creating new PicoRuby projects.

## Setup

```bash
cd /home/user/picotorokko/playground
bundle install
```

This sets up the local development environment with the development version of picotorokko.

## Quick Start

Create your first PicoRuby project:

```bash
cd /home/user/picotorokko/playground
ptrk init my-first-app
cd my-first-app
```

You should see a complete project structure with:
- `.picoruby-env.yml` — Environment configuration
- `CLAUDE.md` — Development guidelines
- `storage/home/` — Application code directory
- `patch/` — Customization patches
- `.github/workflows/` — CI/CD templates
- `Gemfile` — Ruby dependencies

## Testing Scenarios

### Scenario 1: Basic Project Initialization ✅

Create a new PicoRuby project:

```bash
ptrk init hello-picoruby
cd hello-picoruby
ls -la
```

**Expected Results**:
- ✅ Project created in `./hello-picoruby/` (not current directory)
- ✅ All required directories exist: `storage/home/`, `patch/`, `ptrk_env/`, `.github/workflows/`
- ✅ Template files generated: `.picoruby-env.yml`, `README.md`, `CLAUDE.md`, `Gemfile`
- ✅ `.picoruby-env.yml` is valid YAML format
- ✅ Documentation is clear and actionable

### Scenario 2: Project with GitHub Actions CI/CD

Initialize with CI/CD workflows:

```bash
ptrk init my-app-with-ci --with-ci
cd my-app-with-ci
ls -la .github/workflows/
```

**Expected Results**:
- ✅ `.github/workflows/` directory is created
- ✅ GitHub Actions workflow files are present
- ✅ Workflow YAML is valid

### Scenario 3: Project with Single mrbgem

Create project with custom mrbgem:

```bash
ptrk init my-app-with-gem --with-mrbgem MyGem
cd my-app-with-gem
find . -name "*MyGem*" -o -path "*/mrbgems/*" | head -20
```

**Expected Results**:
- ✅ `mrbgems/` directory is created
- ✅ `MyGem` template exists with proper structure
- ✅ Ruby code template is included

### Scenario 4: Project with Multiple mrbgems

Initialize with multiple gems:

```bash
ptrk init multi-gem-app --with-mrbgem Sensor --with-mrbgem Display --with-mrbgem Controller
cd multi-gem-app
ls mrbgems/
```

**Expected Results**:
- ✅ All three mrbgems (Sensor, Display, Controller) are created
- ✅ Each has independent template structure
- ✅ No naming conflicts

### Scenario 5: Project in Custom Directory

Create project at specific path:

```bash
mkdir -p /tmp/picoruby-projects
ptrk init my-project --path /tmp/picoruby-projects
ls -la /tmp/picoruby-projects/my-project/
```

**Expected Results**:
- ✅ Project created at `/tmp/picoruby-projects/my-project/`
- ✅ Full project structure is present
- ✅ Path option works correctly

### Scenario 6: Custom Author Name

Specify author explicitly:

```bash
ptrk init alice-project --author "Alice Wonderland"
cd alice-project
grep -i "alice\|author" README.md CLAUDE.md | head -5
```

**Expected Results**:
- ✅ "Alice Wonderland" appears in README.md and CLAUDE.md
- ✅ Specified author overrides auto-detection
- ✅ Properly formatted in documentation

### Scenario 7: Complete Feature Set

Use all options together:

```bash
ptrk init full-featured-app \
  --with-ci \
  --with-mrbgem MySensor \
  --with-mrbgem MyDisplay \
  --author "Bob Developer" \
  --path /tmp/picoruby-projects

cd /tmp/picoruby-projects/full-featured-app
echo "=== Project Structure ===" && ls -la
echo "=== mrbgems ===" && ls mrbgems/
echo "=== GitHub Workflows ===" && ls .github/workflows/ || echo "No workflows"
echo "=== Author ===" && grep -i "bob" CLAUDE.md | head -3
```

**Expected Results**:
- ✅ Project at `/tmp/picoruby-projects/full-featured-app/`
- ✅ Both MySensor and MyDisplay mrbgems exist
- ✅ `.github/workflows/` directory present
- ✅ "Bob Developer" appears in documentation

## Environment Configuration Testing

After project initialization, test environment setup:

```bash
cd hello-picoruby

# 1. Create an environment
ptrk env set main --commit abc1234567890123456789012345678901234567

# 2. List environments
ptrk env list

# 3. Show environment details
ptrk env show main

# 4. View environment configuration
cat .picoruby-env.yml
```

**Expected Results**:
- ✅ Environment created successfully
- ✅ `.picoruby-env.yml` is updated
- ✅ `ptrk env list` shows "main"
- ✅ `ptrk env show main` displays commit hash correctly

## Documentation Validation

Verify generated documentation quality:

```bash
cd hello-picoruby

# Check README quality
head -50 README.md

# Check development guidelines
head -50 CLAUDE.md

# Check environment template
cat .picoruby-env.yml
```

**Validation Items**:
- ✅ README.md contains practical quick-start guide
- ✅ CLAUDE.md clearly explains development workflow
- ✅ `.picoruby-env.yml` is valid YAML format
- ✅ All documentation is clear and actionable

## Important Notes for Testing

1. **Always specify a project name** when running `ptrk init`
   - ✅ Correct: `ptrk init my-app`
   - ❌ Avoid: `ptrk init` (without project name)

2. **Project name restrictions**
   - Alphanumeric characters, dashes, and underscores only
   - Example valid names: `my-app`, `my_app`, `myapp123`

3. **Author name auto-detection**
   - Default: Auto-detected from git config
   - Override: Use `--author "Your Name"` flag

4. **mrbgem naming**
   - Follow CamelCase convention: `MyGem` not `my_gem` or `my-gem`
   - Each mrbgem must have unique name

5. **Path option behavior**
   - If `--path` is not specified, uses current directory as base
   - Project is always created in subdirectory named after PROJECT_NAME
   - Result: `{base_path}/{project_name}/`

## Test Completion Checklist

Track your testing progress:

- [ ] Scenario 1: Basic initialization
- [ ] Scenario 2: CI/CD workflows
- [ ] Scenario 3: Single mrbgem
- [ ] Scenario 4: Multiple mrbgems
- [ ] Scenario 5: Custom path
- [ ] Scenario 6: Custom author
- [ ] Scenario 7: All options combined
- [ ] Environment configuration testing
- [ ] Documentation validation
- [ ] All generated projects removed (cleanup)

## Reporting Issues

If you find unexpected behaviors or issues:

1. Note the exact command executed
2. Document expected vs. actual behavior
3. Include error messages (if any)
4. Reference which scenario from this guide
5. Report findings with context for gem improvement

## Cleanup

After testing, remove generated projects:

```bash
cd /home/user/picotorokko/playground
rm -rf my-first-app hello-picoruby my-app-with-ci my-app-with-gem multi-gem-app alice-project
rm -rf /tmp/picoruby-projects  # If created
```

---

**Note**: This playground directory contains ONLY this README.md file. All test projects are created as subdirectories here. No other permanent files should be committed to this directory.

**Happy Testing!** ピョン！
