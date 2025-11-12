# Steep configuration for picotorokko gem
# Type checking with RBS files generated from rbs-inline annotations

D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "lib"

  # External gem type definitions (from stdlib and bundled gems)
  library "pathname"
  library "optparse"
  library "thor"
  library "yaml"
  library "fileutils"
  library "open-uri"
  library "net/http"
  library "tempfile"
  library "fileutils"
  library "logger"

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
  signature "sig", "sig/test"

  check "test"

  library "test-unit"
  library "tmpdir"
  library "fileutils"
  library "pathname"

  # Test code is checked but with relaxed rules
  configure_code_diagnostics do |hash|
    hash[D::Ruby::NoMethod] = :warning
    hash[D::Ruby::UnresolvedOverloading] = :warning
    hash[D::Ruby::IncompatibleAssignment] = :warning
  end
end
