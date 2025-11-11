# PicoRuby Method Database

This directory contains JSON files with method support information for PicoRuby.

## Initial Setup Required

The JSON data files (`picoruby_supported_methods.json`, `picoruby_unsupported_methods.json`)
are **not included** by default to keep the template lightweight and ensure you always have
the latest PicoRuby method definitions.

**Generate the database:**

```bash
pra rubocop update
```

Or manually:

```bash
ruby scripts/update_methods.rb
```

## File Structure

### picoruby_supported_methods.json
Methods that are available in PicoRuby. Example:

```json
{
  "Array": {
    "instance": ["each", "map", "select", "size", "[]", "[]=", ...],
    "class": ["new", "[]"]
  },
  "String": {
    "instance": ["upcase", "downcase", "size", ...],
    "class": ["new"]
  }
}
```

### picoruby_unsupported_methods.json
Methods available in CRuby but NOT in PicoRuby. Used by RuboCop Cop:

```json
{
  "Array": {
    "instance": ["combination", "permutation", "repeated_permutation", ...],
    "class": []
  },
  "String": {
    "instance": ["unicode_normalize", "encode", "gsub!", ...],
    "class": []
  }
}
```

## Updating the Database

When PicoRuby is updated or you want to refresh the method list:

```bash
pra rubocop update
```

This will:
1. Clone/pull the latest picoruby.github.io
2. Extract method definitions from RBS documentation
3. Compare with CRuby methods
4. Regenerate the JSON files
