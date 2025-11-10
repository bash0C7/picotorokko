
require_relative "lib/pra/version"

Gem::Specification.new do |spec|
  spec.name = "picotorokko"
  spec.version = Pra::VERSION
  spec.authors = ["bash0C7"]
  spec.email = ["ksb.4038.nullpointer+github@gmail.com"]

  spec.summary = "Multi-version build system for ESP32 + PicoRuby development"
  spec.description = "pra is a multi-version build system for ESP32 + PicoRuby development that manages multiple versions of R2P2-ESP32 and its nested submodules in parallel, allowing easy switching and validation across versions.\n\nNOTE: This gem targets Ruby 3.4+ where frozen_string_literal is the default behavior. Ruby 3.3 is partially supported for legacy environments."
  spec.homepage = "https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit"
  spec.metadata["changelog_uri"] = "https://github.com/bash0C7/picoruby-application-on-r2p2-esp32-development-kit/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "thor", "~> 1.3"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "test-unit", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.81"
  spec.add_development_dependency "rubocop-performance", "~> 1.26"
  spec.add_development_dependency "rubocop-rake", "~> 0.7"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-cobertura", "~> 3.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
