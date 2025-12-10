#!/usr/bin/env ruby
# frozen_string_literal: true

# Verify what LibClangParser actually extracts for zero-method classes

require_relative "../lib/m5libgen/repository_manager"
require_relative "../lib/m5libgen/header_reader"
require_relative "../lib/m5libgen/libclang_parser"
require "tmpdir"
require "fileutils"

def verify_zero_method_extraction
  tmpdir = Dir.mktmpdir("m5unified_verify")
  repo_path = File.join(tmpdir, "m5unified")

  begin
    # Clone M5Unified
    puts "📦 Cloning M5Unified repository..."
    repo = M5LibGen::RepositoryManager.new(repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")

    # Read all headers
    header_reader = M5LibGen::HeaderReader.new(repo_path)
    headers = header_reader.list_headers

    # Target classes with 0 methods from analysis
    target_classes = %w[config_t imu_3d_t point_t speaker_config_t]

    puts "\n#{"=" * 80}"
    puts "VERIFYING LIBCLANGPARSER EXTRACTION FOR ZERO-METHOD CLASSES"
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

      # Use LibClangParser to extract what it finds
      begin
        parser = M5LibGen::LibClangParser.new(header_path, include_paths: [File.join(repo_path, "src")])
        classes = parser.extract_classes

        # Find our target class
        target = classes.find { |c| c[:name] == class_name }

        if target
          puts "  ✅ Class found by parser"
          puts "  Methods extracted: #{target[:methods].length}"

          if target[:methods].empty?
            puts "  → This is correctly identified as a data structure"
          else
            puts "  → Parser found these methods:"
            target[:methods].each do |method|
              params = method[:parameters].map { |p| "#{p[:type]} #{p[:name]}" }.join(", ")
              puts "    - #{method[:return_type]} #{method[:name]}(#{params})"
            end
          end
        else
          puts "  ⚠️  Class NOT found by parser (might be nested or typedef)"
        end
      rescue StandardError => e
        puts "  ❌ Parser error: #{e.message}"
      end

      puts
    end
  ensure
    FileUtils.rm_rf(tmpdir)
  end
end

verify_zero_method_extraction if __FILE__ == $PROGRAM_NAME
