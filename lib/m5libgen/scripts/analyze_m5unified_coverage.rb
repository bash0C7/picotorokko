#!/usr/bin/env ruby
# frozen_string_literal: true

# M5Unified coverage analysis script
# Analyzes actual M5Unified repository to identify what's missing

require_relative "../lib/m5libgen/repository_manager"
require_relative "../lib/m5libgen/header_reader"
require_relative "../lib/m5libgen/libclang_parser"
require "tmpdir"
require "fileutils"

def analyze_m5unified_coverage
  tmpdir = Dir.mktmpdir("m5unified_analysis")
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
    puts "📄 Found #{headers.length} header files\n\n"

    # Parse all classes
    all_classes = []
    skipped_headers = []

    headers.each do |header|
      # Skip LovyanGFX for now
      if header.include?("lgfx") || header.include?("LGFX")
        skipped_headers << header
        next
      end

      begin
        parser = M5LibGen::LibClangParser.new(header, include_paths: [File.join(repo_path, "src")])
        classes = parser.extract_classes

        classes.each do |klass|
          klass[:source_file] = File.basename(header)
          all_classes << klass
        end
      rescue => e
        puts "⚠️  Error parsing #{File.basename(header)}: #{e.message}"
        skipped_headers << header
      end
    end

    # Analysis
    puts "=" * 80
    puts "M5UNIFIED COVERAGE ANALYSIS"
    puts "=" * 80
    puts

    # Overall stats
    total_classes = all_classes.length
    classes_with_methods = all_classes.select { |c| c[:methods].length > 0 }.length
    total_methods = all_classes.sum { |c| c[:methods].length }

    puts "📊 OVERALL STATISTICS:"
    puts "  Classes extracted: #{total_classes}"
    puts "  Classes with methods: #{classes_with_methods}"
    puts "  Total methods: #{total_methods}"
    puts "  Coverage: #{(classes_with_methods.to_f / total_classes * 100).round(1)}%"
    puts

    # Classes without methods (missing coverage)
    classes_without_methods = all_classes.select { |c| c[:methods].empty? }
    if classes_without_methods.any?
      puts "❌ CLASSES WITH 0 METHODS (#{classes_without_methods.length}):"
      classes_without_methods.each do |klass|
        puts "  - #{klass[:name]} (#{klass[:source_file]})"
      end
      puts
    end

    # Top classes by method count
    puts "🏆 TOP 10 CLASSES BY METHOD COUNT:"
    all_classes
      .select { |c| c[:methods].length > 0 }
      .sort_by { |c| -c[:methods].length }
      .take(10)
      .each_with_index do |klass, idx|
        puts "  #{idx + 1}. #{klass[:name]}: #{klass[:methods].length} methods (#{klass[:source_file]})"
      end
    puts

    # Critical classes check
    puts "🎯 CRITICAL CLASSES CHECK:"
    critical_classes = {
      "M5Unified" => "Main API class",
      "Button_Class" => "Button input",
      "Display" => "Display output",
      "Touch_Class" => "Touch input",
      "Speaker_Class" => "Audio output",
      "IMU_Class" => "IMU sensor",
      "Power_Class" => "Power management"
    }

    critical_classes.each do |class_name, description|
      klass = all_classes.find { |c| c[:name] == class_name }
      if klass
        status = klass[:methods].length > 0 ? "✅" : "❌"
        puts "  #{status} #{class_name} (#{description}): #{klass[:methods].length} methods"
      else
        puts "  ❓ #{class_name} (#{description}): NOT FOUND"
      end
    end
    puts

    # Skipped files
    if skipped_headers.any?
      puts "⏭️  SKIPPED FILES (#{skipped_headers.length}):"
      skipped_headers.take(10).each do |header|
        puts "  - #{File.basename(header)}"
      end
      puts "  ... and #{skipped_headers.length - 10} more" if skipped_headers.length > 10
      puts
    end

    # Detailed class list with method counts
    puts "📋 ALL EXTRACTED CLASSES:"
    all_classes
      .sort_by { |c| [-c[:methods].length, c[:name]] }
      .each do |klass|
        method_count = klass[:methods].length
        status = method_count > 0 ? "✅" : "❌"
        puts "  #{status} #{klass[:name]}: #{method_count} methods (#{klass[:source_file]})"
      end
    puts

    # Missing coverage analysis
    missing_coverage_pct = ((total_classes - classes_with_methods).to_f / total_classes * 100).round(1)
    puts "=" * 80
    puts "REMAINING WORK:"
    puts "  Missing coverage: #{missing_coverage_pct}%"
    puts "  Classes needing methods: #{total_classes - classes_with_methods}"
    puts "=" * 80
    puts

    all_classes

  ensure
    FileUtils.rm_rf(tmpdir)
  end
end

if __FILE__ == $0
  analyze_m5unified_coverage
end
