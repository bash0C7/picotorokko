#!/usr/bin/env ruby
# frozen_string_literal: true

# Search for Display_Class in M5Unified repository

require_relative "../lib/m5libgen/repository_manager"
require_relative "../lib/m5libgen/header_reader"
require "tmpdir"
require "fileutils"

def search_display_class
  tmpdir = Dir.mktmpdir("m5unified_display_search")
  repo_path = File.join(tmpdir, "m5unified")

  begin
    # Clone M5Unified
    puts "📦 Cloning M5Unified repository..."
    repo = M5LibGen::RepositoryManager.new(repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")

    # Read all headers (including LGFX)
    header_reader = M5LibGen::HeaderReader.new(repo_path)
    headers = header_reader.list_headers

    puts "\n🔍 Searching for Display classes in all headers..."
    puts "=" * 80
    puts

    display_mentions = []

    headers.each do |header|
      content = File.read(header, encoding: "UTF-8")

      # Search for various Display patterns
      if content =~ /class\s+(Display\w*)/
        display_mentions << {
          file: File.basename(header),
          path: header,
          class_name: $1,
          type: "class"
        }
      end

      if content =~ /typedef\s+.*\s+(Display\w*)/
        display_mentions << {
          file: File.basename(header),
          path: header,
          class_name: $1,
          type: "typedef"
        }
      end

      # Check for M5.Display patterns
      if content.include?("M5.Display")
        display_mentions << {
          file: File.basename(header),
          path: header,
          class_name: "Display (M5.Display reference)",
          type: "usage"
        }
      end
    end

    if display_mentions.empty?
      puts "❌ No Display classes found!"
    else
      puts "✅ Found #{display_mentions.length} Display-related mentions:"
      puts
      display_mentions.uniq { |m| [m[:file], m[:class_name]] }.each do |mention|
        puts "  #{mention[:type].upcase.ljust(10)} #{mention[:class_name].ljust(30)} in #{mention[:file]}"

        # Check if it's in LGFX (skipped) directory
        if mention[:path].include?("lgfx") || mention[:path].include?("LGFX")
          puts "            ⚠️  File is in LGFX directory (currently skipped)"
        end
      end
    end

    puts
    puts "=" * 80
    puts "🔍 Checking M5Unified.hpp for Display member..."
    puts "=" * 80
    puts

    m5unified_header = headers.find { |h| h.end_with?("M5Unified.hpp") }
    if m5unified_header
      content = File.read(m5unified_header, encoding: "UTF-8")

      # Find Display member in M5Unified class
      if content =~ /(\w+[\s\*&]*)\s+Display\s*;/
        puts "✅ Found Display member in M5Unified class:"
        puts "   Type: #{$1}"
        puts "   Member: Display"
        puts
        puts "This means Display is likely a typedef or instance of another class."
        puts "Searching for the actual type definition..."

        # Search for this type definition
        type_name = $1.strip.gsub(/[\s\*&]/, "")
        puts
        puts "Looking for class/typedef: #{type_name}"

        type_header = headers.find do |h|
          c = File.read(h, encoding: "UTF-8")
          c.include?("class #{type_name}") || c.include?("typedef") && c.include?(type_name)
        end

        if type_header
          puts "  ✅ Found in: #{File.basename(type_header)}"
          if type_header.include?("lgfx") || type_header.include?("LGFX")
            puts "  ⚠️  This is in LGFX (LovyanGFX) - graphics library"
          end
        end
      end
    end

  ensure
    FileUtils.rm_rf(tmpdir)
  end
end

if __FILE__ == $0
  search_display_class
end
