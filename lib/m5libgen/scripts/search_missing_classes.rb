#!/usr/bin/env ruby
# frozen_string_literal: true

# Search for potentially missing classes

require_relative "../lib/m5libgen/repository_manager"
require_relative "../lib/m5libgen/header_reader"
require "tmpdir"
require "fileutils"

def search_missing_classes
  tmpdir = Dir.mktmpdir("m5unified_missing")
  repo_path = File.join(tmpdir, "m5unified")

  begin
    # Clone M5Unified
    puts "📦 Cloning M5Unified repository..."
    repo = M5LibGen::RepositoryManager.new(repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")

    # Read all headers (including LGFX/utility)
    header_reader = M5LibGen::HeaderReader.new(repo_path)
    headers = header_reader.list_headers

    # Also search in utility directory
    utility_headers = Dir.glob(File.join(repo_path, "src", "utility", "**", "*.h*"))
    all_headers = (headers + utility_headers).uniq

    puts "\n🔍 Searching for missing classes in #{all_headers.length} headers..."
    puts "=" * 100
    puts

    missing_classes = [
      "Display_Class",
      "In_I2C",
      "Ex_I2C",
      "AXP192_Class",
      "AXP2101_Class",
      "IP5306_Class"
    ]

    missing_classes.each do |class_name|
      puts "Searching for: #{class_name}"

      found_in = []

      all_headers.each do |header|
        begin
          content = File.read(header, encoding: "UTF-8")

          # Search for class/struct definition
          if content =~ /\b(class|struct)\s+#{Regexp.escape(class_name)}\b/
            found_in << {
              path: header.sub(repo_path, ""),
              type: $1,
              full_path: header
            }
          end

          # Search for typedef
          if content =~ /typedef\s+.*\s+#{Regexp.escape(class_name)}\b/
            found_in << {
              path: header.sub(repo_path, ""),
              type: "typedef",
              full_path: header
            }
          end
        rescue => e
          # Skip problematic files
        end
      end

      if found_in.empty?
        puts "  ❌ NOT FOUND in any header"
      else
        puts "  ✅ FOUND in #{found_in.length} file(s):"
        found_in.each do |location|
          type_str = (location[:type] || "unknown").ljust(10)
          puts "     #{type_str} #{location[:path]}"

          # Check if it's in a skipped directory
          if location[:path].include?("lgfx") || location[:path].include?("LGFX")
            puts "       ⚠️  In LGFX directory (currently skipped)"
          elsif location[:path].include?("utility")
            puts "       ⚠️  In utility directory (may be skipped)"

            # Try to parse it
            begin
              parser = M5LibGen::LibClangParser.new(
                location[:full_path],
                include_paths: [File.join(repo_path, "src")]
              )
              classes = parser.extract_classes
              target = classes.find { |c| c[:name] == class_name }

              if target
                puts "       ✅ Extractable! Has #{target[:methods].length} methods"
              else
                puts "       ❌ Not extractable by parser"
              end
            rescue => e
              puts "       ❌ Parser error: #{e.message}"
            end
          end
        end
      end

      puts
    end

    # Also search for "In_I2C" and "Ex_I2C" as potential aliases or members
    puts "=" * 100
    puts "🔍 Searching for I2C-related patterns..."
    puts "=" * 100
    puts

    all_headers.each do |header|
      next if header.include?("lgfx") || header.include?("LGFX")

      begin
        content = File.read(header, encoding: "UTF-8")

        # Search for In_I2C or Ex_I2C mentions
        if content.include?("In_I2C") || content.include?("Ex_I2C")
          puts "Found I2C pattern in: #{header.sub(repo_path, "")}"

          # Extract lines containing these patterns
          content.lines.each_with_index do |line, idx|
            if line.include?("In_I2C") || line.include?("Ex_I2C")
              puts "  Line #{idx + 1}: #{line.strip}"
            end
          end
          puts
        end
      rescue => e
        # Skip
      end
    end

  ensure
    FileUtils.rm_rf(tmpdir)
  end
end

if __FILE__ == $0
  search_missing_classes
end
