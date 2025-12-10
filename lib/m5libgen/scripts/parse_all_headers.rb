#!/usr/bin/env ruby
# frozen_string_literal: true

# Parse all headers and show which succeed/fail

require_relative "../lib/m5libgen/repository_manager"
require_relative "../lib/m5libgen/header_reader"
require_relative "../lib/m5libgen/libclang_parser"
require "tmpdir"
require "fileutils"

def parse_all_headers
  tmpdir = Dir.mktmpdir("m5unified_parse_all")
  repo_path = File.join(tmpdir, "m5unified")

  begin
    # Clone M5Unified
    puts "📦 Cloning M5Unified repository..."
    repo = M5LibGen::RepositoryManager.new(repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")

    # Read all headers
    header_reader = M5LibGen::HeaderReader.new(repo_path)
    headers = header_reader.list_headers

    puts "\n🔍 Parsing #{headers.length} headers..."
    puts "=" * 100
    puts

    success_count = 0
    fail_count = 0
    all_classes = []

    headers.each do |header|
      next if header.include?("lgfx") || header.include?("LGFX")

      header_name = header.sub(repo_path, "")

      begin
        parser = M5LibGen::LibClangParser.new(header, include_paths: [File.join(repo_path, "src")])
        classes = parser.extract_classes

        if classes.empty?
          puts "⚠️  #{header_name} - 0 classes"
        else
          puts "✅ #{header_name} - #{classes.length} classes"
          classes.each do |klass|
            klass[:source_file] = File.basename(header)
            all_classes << klass
            puts "   - #{klass[:name]} (#{klass[:methods].length} methods)"
          end
        end
        success_count += 1
      rescue StandardError => e
        puts "❌ #{header_name} - ERROR: #{e.message}"
        fail_count += 1
      end
    end

    puts
    puts "=" * 100
    puts "SUMMARY"
    puts "=" * 100
    puts "Success: #{success_count}"
    puts "Failed: #{fail_count}"
    puts "Total classes extracted: #{all_classes.length}"
    puts "Total methods: #{all_classes.sum { |c| c[:methods].length }}"
    puts

    # Check for utility/power classes specifically
    power_classes = all_classes.select { |c| c[:source_file].start_with?("AXP", "IP5", "AW3", "BQ2", "INA") }
    puts "Power utility classes found: #{power_classes.length}"
    power_classes.each do |klass|
      puts "  - #{klass[:name]} (#{klass[:methods].length} methods) from #{klass[:source_file]}"
    end
  ensure
    FileUtils.rm_rf(tmpdir)
  end
end

parse_all_headers if __FILE__ == $PROGRAM_NAME
