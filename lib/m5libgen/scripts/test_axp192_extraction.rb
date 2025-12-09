#!/usr/bin/env ruby
# frozen_string_literal: true

# Test AXP192 extraction specifically

require_relative "../lib/m5libgen/repository_manager"
require_relative "../lib/m5libgen/libclang_parser"
require "tmpdir"
require "fileutils"

def test_axp192_extraction
  tmpdir = Dir.mktmpdir("m5unified_axp192_test")
  repo_path = File.join(tmpdir, "m5unified")

  begin
    # Clone M5Unified
    puts "📦 Cloning M5Unified repository..."
    repo = M5LibGen::RepositoryManager.new(repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")

    # Parse AXP192_Class.hpp
    axp192_path = File.join(repo_path, "src", "utility", "power", "AXP192_Class.hpp")

    puts "\n🔍 Parsing AXP192_Class.hpp..."
    puts "=" * 100
    puts "File: #{axp192_path}"
    puts "Exists: #{File.exist?(axp192_path)}"
    puts

    parser = M5LibGen::LibClangParser.new(axp192_path, include_paths: [File.join(repo_path, "src")])
    classes = parser.extract_classes

    puts "Classes extracted: #{classes.length}"
    puts

    if classes.empty?
      puts "❌ NO CLASSES EXTRACTED!"
      puts
      puts "Debugging: Check file content patterns..."

      content = File.read(axp192_path, encoding: "UTF-8")

      # Check for class keyword
      if content.include?("class AXP192_Class")
        puts "✅ Contains 'class AXP192_Class'"
      end

      # Check for namespace
      if content.include?("namespace m5")
        puts "✅ Contains 'namespace m5'"
      end

      # Check if regex would match
      pattern = /(?:class|struct)\s+(\w+)\s*\{/
      matches = content.scan(pattern)
      puts "Regex matches: #{matches.length}"
      matches.each { |m| puts "  - #{m[0]}" }

    else
      puts "✅ CLASSES EXTRACTED:"
      classes.each do |klass|
        puts "  - #{klass[:name]} (#{klass[:methods].length} methods)"
        klass[:methods].take(5).each do |method|
          puts "      #{method[:return_type]} #{method[:name]}()"
        end
      end
    end

  ensure
    FileUtils.rm_rf(tmpdir)
  end
end

if __FILE__ == $0
  test_axp192_extraction
end
