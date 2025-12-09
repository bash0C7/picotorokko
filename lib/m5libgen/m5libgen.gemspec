# frozen_string_literal: true

require_relative "lib/m5libgen/version"

Gem::Specification.new do |spec|
  spec.name = "m5libgen"
  spec.version = M5LibGen::VERSION
  spec.authors = ["bash0C7"]
  spec.email = ["bash0c7@example.com"]

  spec.summary = "M5Unified C++ Library to PicoRuby mrbgem Generator"
  spec.description = <<~DESC
    Automatically generates PicoRuby mrbgems for wrapping the M5Unified C++ library.
    Uses libclang for accurate C++ AST parsing and generates complete mrbgem packages
    with C bindings, C++ wrappers, and CMake configuration for ESP32 builds.
  DESC
  spec.homepage = "https://github.com/bash0C7/picotorokko"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bash0C7/picotorokko"
  spec.metadata["changelog_uri"] = "https://github.com/bash0C7/picotorokko/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "bin/*", "README.md", "TODO.md", "LICENSE"]
  spec.bindir = "bin"
  spec.executables = ["m5libgen"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ffi-clang", "~> 0.10.0"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.81"
  spec.add_development_dependency "test-unit", "~> 3.7"
end
