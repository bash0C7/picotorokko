# {{MRBGEM_NAME}}

Application-specific PicoRuby mrbgem for ESP32.

## Usage

```ruby
{{CLASS_NAME}}.version
```

## Development

Edit `src/{{C_PREFIX}}.c` to add more class methods.

The mrbgem is automatically registered in `build_config/xtensa-esp.rb` and `CMakeLists.txt` via the patch system. Customize patches in the `patch/` directory as needed.
