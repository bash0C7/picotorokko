#!/usr/bin/env ruby
# frozen_string_literal: true

# Inspect AXP192_Class.hpp to understand why it's not being extracted

require_relative "../lib/m5libgen/repository_manager"
require "tmpdir"
require "fileutils"

def inspect_axp192
  tmpdir = Dir.mktmpdir("m5unified_axp192")
  repo_path = File.join(tmpdir, "m5unified")

  begin
    # Clone M5Unified
    puts "📦 Cloning M5Unified repository..."
    repo = M5LibGen::RepositoryManager.new(repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")

    # Read AXP192_Class.hpp
    axp192_path = File.join(repo_path, "src", "utility", "power", "AXP192_Class.hpp")
    content = File.read(axp192_path, encoding: "UTF-8")

    puts "\n📄 AXP192_Class.hpp content:"
    puts "=" * 100
    puts

    # Show first 100 lines
    content.lines.take(100).each_with_index do |line, idx|
      puts "#{(idx + 1).to_s.rjust(3)}: #{line}"
    end

    puts
    puts "=" * 100
    puts "ANALYSIS:"
    puts "=" * 100

    # Check for namespace
    if content.include?("namespace")
      puts "✅ Contains namespace declarations"
      content.scan(/namespace\s+(\w+)/).each do |match|
        puts "   - namespace #{match[0]}"
      end
    end

    # Check for class definition
    if content =~ /class\s+AXP192_Class/
      puts "✅ Contains 'class AXP192_Class' definition"
    else
      puts "❌ No 'class AXP192_Class' found"
    end

    # Check for inheritance
    if content =~ /class\s+AXP192_Class\s*:\s*public\s+(\w+)/
      puts "✅ Inherits from: #{$1}"
    end

  ensure
    FileUtils.rm_rf(tmpdir)
  end
end

if __FILE__ == $0
  inspect_axp192
end
