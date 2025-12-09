#!/usr/bin/env ruby
# frozen_string_literal: true

# Analyze classes with 0 methods to determine if they should have methods

require_relative "../lib/m5libgen/repository_manager"
require_relative "../lib/m5libgen/header_reader"
require_relative "../lib/m5libgen/libclang_parser"
require "tmpdir"
require "fileutils"

def analyze_zero_method_classes
  tmpdir = Dir.mktmpdir("m5unified_zero_analysis")
  repo_path = File.join(tmpdir, "m5unified")

  begin
    # Clone M5Unified
    puts "📦 Cloning M5Unified repository..."
    repo = M5LibGen::RepositoryManager.new(repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")

    # Read all headers
    header_reader = M5LibGen::HeaderReader.new(repo_path)
    headers = header_reader.list_headers

    # Target classes with 0 methods
    target_classes = ["config_t", "imu_3d_t", "point_t", "speaker_config_t"]

    puts "\n" + "=" * 80
    puts "ANALYZING CLASSES WITH 0 METHODS"
    puts "=" * 80
    puts

    target_classes.each do |class_name|
      # Find the header containing this class
      header_path = headers.find do |h|
        content = File.read(h, encoding: "UTF-8")
        content.include?("struct #{class_name}") || content.include?("class #{class_name}")
      end

      unless header_path
        puts "❌ #{class_name} not found in any header"
        next
      end

      puts "📄 #{File.basename(header_path)} - #{class_name}"
      puts "-" * 80

      # Read the actual class definition with UTF-8 encoding
      content = File.read(header_path, encoding: "UTF-8")

      # Find the class/struct definition
      if content =~ /(struct|class)\s+#{Regexp.escape(class_name)}\s*\{([^}]*)\}/m
        class_type = $1
        class_body = $2

        # Count methods in body
        method_count = class_body.scan(/\w+\s+\w+\s*\([^)]*\)/).length
        member_count = class_body.scan(/\w+\s+\w+\s*;/).length

        puts "  Type: #{class_type}"
        puts "  Methods found in source: #{method_count}"
        puts "  Member variables: #{member_count}"

        # Show first few lines
        lines = class_body.lines.take(10).map(&:strip).reject(&:empty?)
        puts "  Content preview:"
        lines.each { |line| puts "    #{line}" }
        puts "    ..." if class_body.lines.length > 10

        if method_count == 0
          puts "  ✅ CORRECT: This is a data structure (no methods expected)"
        else
          puts "  ❌ PROBLEM: Has #{method_count} methods but not extracted!"
        end
      else
        puts "  ⚠️  Could not find class definition"
      end

      puts
    end

  ensure
    FileUtils.rm_rf(tmpdir)
  end
end

if __FILE__ == $0
  analyze_zero_method_classes
end
