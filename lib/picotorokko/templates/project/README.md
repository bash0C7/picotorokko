# {{PROJECT_NAME}}

A PicoRuby application for ESP32 development using the `picotorokko` (ptrk) build system.

**Created**: {{CREATED_AT}}
**Author**: {{AUTHOR}}

## Quick Start

### 1. Setup Environment

First, fetch the latest repository versions automatically:

```bash
ptrk env latest
```

Or, create an environment with specific repository commits:

```bash
ptrk env set main --commit <R2P2-ESP32-hash>
```

Optionally, specify different commits for picoruby-esp32 and picoruby:

```bash
ptrk env set main \
  --commit <R2P2-hash> \
  --esp32-commit <picoruby-esp32-hash> \
  --picoruby-commit <picoruby-hash>
```

### 2. Build Application

```bash
ptrk device build
```

This clones repositories, applies patches, and builds firmware for your application.

### 3. Flash to Device

```bash
ptrk device flash
```

### 4. Monitor Serial Output

```bash
ptrk device monitor
```

## Project Structure

- **`storage/home/`** — Your PicoRuby application code (git-managed)
- **`patch/`** — Customizations to R2P2-ESP32 and dependencies (git-managed)
- **`.cache/`** — Immutable repository snapshots (git-ignored)
- **`build/`** — Active build working directory (git-ignored)
- **`ptrk_env/`** — Environment metadata (git-ignored)

## Documentation

- **`SPEC.md`** — Complete specification of ptrk commands (in picotorokko gem)
- **`CLAUDE.md`** — Development guidelines and conventions
- **[picotorokko README](https://github.com/picoruby/picotorokko)** — Gem documentation and examples

## Common Tasks

### List Defined Environments

```bash
ptrk env list
```

### Show Current Environment Details

```bash
ptrk env show main
```

### Export Changes as Patches

After editing files in `build/current/`, export changes:

```bash
ptrk env patch_export main
```

Then commit:

```bash
git add patch/ storage/home/
git commit -m "Update patches and application code"
```

### Switch Between Environments

First, create the new environment:

```bash
ptrk env set development --commit <hash>
```

Then, rebuild with the new environment:

```bash
ptrk device build
```

## Troubleshooting

For detailed troubleshooting and advanced usage, see the picotorokko gem documentation.

### Environment Not Found

Check available environments:

```bash
ptrk env list
```

Create a new one:

```bash
ptrk env set myenv --commit <hash>
```

### Build Fails

Try rebuilding from scratch:

```bash
ptrk device build
```

If the issue persists, verify the environment is correctly set:

```bash
ptrk env show main
```

## Support

For issues with the picotorokko gem, see:
- GitHub: https://github.com/picoruby/picotorokko/issues
- Documentation: https://github.com/picoruby/picotorokko#readme

For PicoRuby and R2P2-ESP32 issues, see:
- PicoRuby: https://github.com/picoruby/picoruby
- R2P2-ESP32: https://github.com/picoruby/R2P2-ESP32
