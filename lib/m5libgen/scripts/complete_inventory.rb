#!/usr/bin/env ruby
# frozen_string_literal: true

# Complete M5Unified class and method inventory

require_relative "../lib/m5libgen/repository_manager"
require_relative "../lib/m5libgen/header_reader"
require_relative "../lib/m5libgen/libclang_parser"
require "tmpdir"
require "fileutils"

def complete_inventory
  tmpdir = Dir.mktmpdir("m5unified_inventory")
  repo_path = File.join(tmpdir, "m5unified")

  begin
    # Clone M5Unified
    puts "📦 Cloning M5Unified repository..."
    repo = M5LibGen::RepositoryManager.new(repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")
    puts "✅ Clone complete\n\n"

    # Read all headers
    header_reader = M5LibGen::HeaderReader.new(repo_path)
    headers = header_reader.list_headers

    # Parse all classes (skip LGFX)
    all_classes = []
    headers.each do |header|
      next if header.include?("lgfx") || header.include?("LGFX")

      begin
        parser = M5LibGen::LibClangParser.new(header, include_paths: [File.join(repo_path, "src")])
        classes = parser.extract_classes
        classes.each do |klass|
          klass[:source_file] = File.basename(header)
          all_classes << klass
        end
      rescue => e
        # Skip problematic headers
      end
    end

    puts "=" * 100
    puts "COMPLETE M5UNIFIED CLASS AND METHOD INVENTORY"
    puts "=" * 100
    puts

    # Sort by method count (descending)
    all_classes.sort_by! { |c| -c[:methods].length }

    total_methods = 0

    all_classes.each_with_index do |klass, idx|
      method_count = klass[:methods].length
      total_methods += method_count

      if method_count > 0
        puts "#{(idx + 1).to_s.rjust(2)}. #{klass[:name].ljust(30)} #{method_count.to_s.rjust(3)} methods  (#{klass[:source_file]})"

        # Show first 5 methods as sample
        klass[:methods].take(5).each do |method|
          params = method[:parameters].map { |p| "#{p[:type]} #{p[:name]}" }.join(", ")
          modifiers = []
          modifiers << "static" if method[:is_static]
          modifiers << "virtual" if method[:is_virtual]
          modifiers << "const" if method[:is_const]
          modifier_str = modifiers.empty? ? "" : " [#{modifiers.join(", ")}]"
          puts "    - #{method[:return_type]} #{method[:name]}(#{params})#{modifier_str}"
        end
        puts "    ... (#{method_count - 5} more methods)" if method_count > 5
        puts
      else
        puts "#{(idx + 1).to_s.rjust(2)}. #{klass[:name].ljust(30)}   0 methods  (#{klass[:source_file]}) [DATA STRUCTURE]"
      end
    end

    puts "=" * 100
    puts "SUMMARY"
    puts "=" * 100
    puts "Total classes: #{all_classes.length}"
    puts "Functional classes (methods > 0): #{all_classes.count { |c| c[:methods].length > 0 }}"
    puts "Data structures (methods = 0): #{all_classes.count { |c| c[:methods].empty? }}"
    puts "Total methods: #{total_methods}"
    puts

    # Check if we're missing any common M5Unified classes
    puts "=" * 100
    puts "EXPECTED CLASSES CHECK"
    puts "=" * 100

    expected_classes = [
      "M5Unified",
      "Button_Class",
      "Touch_Class",
      "Speaker_Class",
      "Mic_Class",
      "IMU_Class",
      "Power_Class",
      "RTC_Class",
      "I2C_Class",
      "Display_Class",  # Might not exist (M5GFX)
      "In_I2C",
      "Ex_I2C",
      "AXP192_Class",
      "AXP2101_Class",
      "IP5306_Class"
    ]

    expected_classes.each do |expected|
      found = all_classes.find { |c| c[:name] == expected }
      if found
        puts "✅ #{expected.ljust(30)} FOUND (#{found[:methods].length} methods)"
      else
        puts "❌ #{expected.ljust(30)} NOT FOUND"
      end
    end

  ensure
    FileUtils.rm_rf(tmpdir)
  end
end

if __FILE__ == $0
  complete_inventory
end
