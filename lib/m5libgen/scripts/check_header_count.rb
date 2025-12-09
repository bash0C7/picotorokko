#!/usr/bin/env ruby
# frozen_string_literal: true

# Check which headers are being read

require_relative "../lib/m5libgen/repository_manager"
require_relative "../lib/m5libgen/header_reader"
require "tmpdir"
require "fileutils"

def check_header_count
  tmpdir = Dir.mktmpdir("m5unified_headers")
  repo_path = File.join(tmpdir, "m5unified")

  begin
    # Clone M5Unified
    puts "📦 Cloning M5Unified repository..."
    repo = M5LibGen::RepositoryManager.new(repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")

    # Read headers using HeaderReader
    header_reader = M5LibGen::HeaderReader.new(repo_path)
    headers = header_reader.list_headers

    puts "\n📋 HeaderReader found #{headers.length} headers:"
    puts "=" * 100
    puts

    # Categorize headers
    utility_headers = headers.select { |h| h.include?("/utility/") }
    lgfx_headers = headers.select { |h| h.include?("lgfx") || h.include?("LGFX") }
    main_headers = headers - utility_headers - lgfx_headers

    puts "Main headers (#{main_headers.length}):"
    main_headers.each { |h| puts "  #{h.sub(repo_path, "")}" }
    puts

    puts "Utility headers (#{utility_headers.length}):"
    utility_headers.each { |h| puts "  #{h.sub(repo_path, "")}" }
    puts

    puts "LGFX headers (#{lgfx_headers.length}):"
    lgfx_headers.each { |h| puts "  #{h.sub(repo_path, "")}" }
    puts

    # Check for power utility classes
    puts "=" * 100
    puts "🔋 Power utility class headers:"
    puts "=" * 100
    puts

    power_headers = utility_headers.select { |h| h.include?("/power/") }
    power_headers.each do |header|
      puts File.basename(header)
    end
  ensure
    FileUtils.rm_rf(tmpdir)
  end
end

check_header_count if __FILE__ == $PROGRAM_NAME
