# Steep configuration for picotorokko gem
# Type checking with RBS files generated from rbs-inline annotations

D = Steep::Diagnostic

target :lib do
  signature "sig", "sig/rbs_collection"

  check "lib"

  # External gem type definitions via RBS Collection
  # Note: RBS Collection provides types for 54 gems including Thor, FileUtils, YAML, etc.
  # Generated from: rbs collection install

  # Ignore version file (typically just constant)
  ignore "lib/picotorokko/version.rb"

  # Diagnostic settings
  configure_code_diagnostics do |hash|
    hash[D::Ruby::NoMethod] = :error
    hash[D::Ruby::UnresolvedOverloading] = :error
    hash[D::Ruby::IncompatibleAssignment] = :error
    hash[D::Ruby::UnsupportedSyntax] = :error
    hash[D::Ruby::FallbackAny] = :warning
  end
end

target :test do
  signature "sig", "sig/rbs_collection", "sig/test"

  check "test"

  # Test code is checked but with relaxed rules
  configure_code_diagnostics do |hash|
    hash[D::Ruby::NoMethod] = :warning
    hash[D::Ruby::UnresolvedOverloading] = :warning
    hash[D::Ruby::IncompatibleAssignment] = :warning
  end
end
