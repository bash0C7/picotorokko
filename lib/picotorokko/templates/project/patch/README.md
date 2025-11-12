# Patch Management

This directory contains customizations and patches to R2P2-ESP32 and its dependencies.

## Structure

```
patch/
├── R2P2-ESP32/         # Patches to R2P2-ESP32 repository
├── picoruby-esp32/     # Patches to picoruby-esp32 (nested in R2P2-ESP32/components)
└── picoruby/           # Patches to picoruby (nested in R2P2-ESP32/components/picoruby-esp32)
```

## Usage

### Export Changes

After modifying files in `build/current/R2P2-ESP32/`, export changes to this directory:

```bash
ptrk patch export
```

### Apply Patches

Patches are automatically applied when setting up a build environment:

```bash
ptrk build setup
```

To manually apply patches:

```bash
ptrk patch apply
```

### View Differences

Check what changes exist between your patches and the current build:

```bash
ptrk patch diff
```

## Best Practices

1. **Keep patches focused**: Each patch file should represent a single logical change
2. **Document patches**: Add comments explaining why each patch exists
3. **Test across versions**: Verify patches apply correctly to different R2P2-ESP32 versions
4. **Minimize patches**: Try to use features in R2P2-ESP32 before patching
5. **Version tracking**: Note which R2P2-ESP32 versions each patch applies to

## Example: Customizing Hardware Configuration

If you need to modify ESP32 pin assignments or hardware settings:

1. Edit in `build/current/R2P2-ESP32/` (e.g., `sdkconfig.defaults`)
2. Build and test
3. Export patches: `ptrk patch export`
4. Commit to git: `git add patch/` && `git commit -m "..."`
5. Patches automatically apply when switching environments

## Troubleshooting

### Patches Not Applying

```bash
# Check patch status
ptrk patch diff

# Re-apply patches
ptrk build clean
ptrk build setup
```

### Merge Conflicts

If a patch fails to apply to a different R2P2-ESP32 version:

1. Resolve in `build/` manually
2. Re-export: `ptrk patch export`
3. Commit changes

## References

- **`ptrk patch export`** — Export changes from build/ to patch/
- **`ptrk patch apply`** — Apply patches from patch/ to build/
- **`ptrk patch diff`** — Show patch differences
- **SPEC.md** — Full patch management documentation
