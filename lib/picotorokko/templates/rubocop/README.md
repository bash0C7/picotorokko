# PicoRuby RuboCop Configuration

RuboCop configuration with custom cop for PicoRuby development.

## Quick Start

### 1. Generate method database (required before first use)

```bash
pra rubocop update
```

This will:
- Clone picoruby.github.io (if not already cloned)
- Extract method definitions from PicoRuby RBS docs
- Generate `data/picoruby_supported_methods.json`
- Generate `data/picoruby_unsupported_methods.json`

### 2. Run RuboCop

```bash
bundle exec rubocop
```

### 3. Fix violations

```bash
bundle exec rubocop --autocorrect-all
```

## Understanding Warnings

### PicoRuby/UnsupportedMethod

This custom cop warns when you use a method that **might not be available** in PicoRuby.

**Example**:
```
app.rb:15:5: W: PicoRuby/UnsupportedMethod: Method `String#unicode_normalize` may not be supported in PicoRuby.
    str.unicode_normalize
```

**Why warning, not error?**
- Not all PicoRuby environments have the same features
- You may have extended PicoRuby with custom mrbgems
- Some methods might work despite the warning

**How to handle**:

1. **Option A: Use an alternative method**
   ```ruby
   # Before (may not work)
   str.unicode_normalize

   # After (known to work)
   str.upcase
   ```

2. **Option B: Disable the check for this line**
   ```ruby
   str.unicode_normalize # rubocop:disable PicoRuby/UnsupportedMethod
   ```

3. **Option C: Disable for a block**
   ```ruby
   # rubocop:disable PicoRuby/UnsupportedMethod
   result = str.unicode_normalize
   result += str.gsub(/a/, 'b')  # Also disabled
   # rubocop:enable PicoRuby/UnsupportedMethod
   ```

## Updating the Database

When PicoRuby releases new features:

```bash
pra rubocop update
```

This will fetch the latest method definitions from picoruby.github.io.

## Configuration

Edit `.rubocop.yml` to customize:

- **Severity**: Change `warning` to `convention` (less important) or `error` (block merge)
- **Exclude**: Add paths to skip checking
- **TargetRubyVersion**: Set to your Ruby version

## Troubleshooting

### "PicoRuby method database not found"

Run:
```bash
pra rubocop update
```

### RuboCop doesn't load the custom cop

Check:
1. `.rubocop.yml` exists in project root
2. `lib/rubocop/cop/picoruby/unsupported_method.rb` exists
3. Run `bundle exec rubocop --show-cops PicoRuby` to verify

### Method is marked unsupported but actually works

The warning is based on official RBS documentation from picoruby.github.io.
If a method works in your environment, you can safely disable the warning.

## References

- [PicoRuby Official Documentation](https://picoruby.org)
- [picoruby.github.io RBS Docs](https://github.com/picoruby/picoruby.github.io)
- [RuboCop Documentation](https://docs.rubocop.org)
