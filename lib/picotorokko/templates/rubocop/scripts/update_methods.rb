#!/usr/bin/env ruby
# frozen_string_literal: true

# PicoRuby method database updater
# Usage: ruby scripts/update_methods.rb
# Generates data/picoruby_supported_methods.json and data/picoruby_unsupported_methods.json

require 'English'
require 'json'
require 'fileutils'
require 'tmpdir'

# Updates PicoRuby method database from RBS documentation
#
# This script clones/pulls picoruby.github.io, extracts method definitions
# from RBS docs, and generates JSON files of supported/unsupported methods.
class MethodDatabaseUpdater
  # Configuration
  PICORUBY_REPO = 'https://github.com/picoruby/picoruby.github.io.git'
  WORK_DIR_NAME = 'picoruby_github_io_tmp'
  SCRIPT_DIR = File.expand_path(__dir__)
  TEMPLATE_DIR = File.expand_path('..', SCRIPT_DIR)
  DATA_DIR = File.join(TEMPLATE_DIR, 'data')

  # Core classes to analyze
  CORE_CLASSES = %w[
    Array String Hash Integer Float Symbol Regexp Range
    Enumerable Numeric Kernel File Dir
  ].freeze

  def initialize
    @work_dir = File.join(Dir.tmpdir, WORK_DIR_NAME)
  end

  def run
    puts '🚀 Starting PicoRuby method database update...'

    begin
      clone_or_pull_repo
      picoruby_methods = extract_picoruby_methods
      cruby_methods = extract_cruby_methods
      unsupported = calculate_unsupported(cruby_methods, picoruby_methods)

      save_data(picoruby_methods, unsupported)
      display_summary(picoruby_methods, unsupported)

      puts '✅ Database update completed successfully!'
    rescue StandardError => e
      puts "❌ Error: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  private

  # ========== Repository Management ==========

  def clone_or_pull_repo
    if Dir.exist?(@work_dir)
      puts '📦 Repository already cloned. Pulling latest changes...'
      Dir.chdir(@work_dir) do
        cmd = 'git pull origin main'
        result = system("#{cmd} 2>/dev/null")
        unless result
          exit_status = $CHILD_STATUS.exitstatus if $CHILD_STATUS
          raise "Command failed (exit status: #{exit_status || 'unknown'}): #{cmd}"
        end
      end
    else
      puts '📥 Cloning picoruby.github.io repository...'
      FileUtils.mkdir_p(File.dirname(@work_dir))
      cmd = "git clone #{PICORUBY_REPO} #{@work_dir}"
      result = system("#{cmd} 2>/dev/null")
      unless result
        exit_status = $CHILD_STATUS.exitstatus if $CHILD_STATUS
        raise "Command failed (exit status: #{exit_status || 'unknown'}): #{cmd}"
      end
    end
  end

  # ========== Data Extraction ==========

  def extract_picoruby_methods
    puts '🔍 Extracting PicoRuby methods from RBS documentation...'

    rbs_doc_dir = File.join(@work_dir, 'pages', 'rbs_doc')
    raise "RBS doc directory not found at #{rbs_doc_dir}" unless Dir.exist?(rbs_doc_dir)

    methods = {}

    Dir.glob(File.join(rbs_doc_dir, '*.md')).each do |file|
      class_name = File.basename(file, '.md')

      # Extract methods from this file
      file_methods = parse_rbs_doc(file, class_name)
      methods[class_name] = file_methods if file_methods.any?
    end

    methods
  end

  def parse_rbs_doc(file, _class_name)
    content = File.read(file)
    methods = { instance: [], class: [], includes: [] }

    # Extract section headings and method signatures
    current_section = nil

    content.each_line do |line|
      # Detect sections
      if line =~ /^## (Singleton methods|Instance methods|Attr accessors|Include)/
        current_section = ::Regexp.last_match(1).downcase.tr(' ', '_').to_sym
        next
      end

      # Detect method names (H3 headings)
      next unless line =~ /^### (\w+)/

      method_name = ::Regexp.last_match(1)
      case current_section
      when :singleton_methods
        methods[:class] << method_name unless methods[:class].include?(method_name)
      when :instance_methods
        methods[:instance] << method_name unless methods[:instance].include?(method_name)
      when :attr_accessors
        # Attr accessors are also instance methods
        methods[:instance] << method_name unless methods[:instance].include?(method_name)
      when :include
        methods[:includes] << method_name unless methods[:includes].include?(method_name)
      end
    end

    methods
  end

  def extract_cruby_methods
    puts '🔍 Extracting CRuby core class methods...'

    methods = {}

    CORE_CLASSES.each do |class_name|
      klass = Object.const_get(class_name)
      methods[class_name] = {
        instance: klass.instance_methods(false).sort.map(&:to_s),
        class: (klass.methods - Class.methods).sort.map(&:to_s)
      }
    rescue NameError => e
      puts "⚠️  Warning: Could not load #{class_name} - #{e.message}"
    end

    methods
  end

  # ========== Data Processing ==========

  def calculate_unsupported(cruby_methods, picoruby_methods)
    puts '📊 Calculating unsupported methods...'

    unsupported = {}

    cruby_methods.each do |class_name, cruby_data|
      picoruby_data = picoruby_methods[class_name] || { instance: [], class: [] }

      unsupported_instance = cruby_data[:instance] - picoruby_data[:instance]
      unsupported_class = cruby_data[:class] - picoruby_data[:class]

      next unless unsupported_instance.any? || unsupported_class.any?

      unsupported[class_name] = {
        instance: unsupported_instance,
        class: unsupported_class
      }
    end

    unsupported
  end

  # ========== File Output ==========

  def save_data(picoruby_methods, unsupported)
    FileUtils.mkdir_p(DATA_DIR)

    # Save supported methods
    supported_path = File.join(DATA_DIR, 'picoruby_supported_methods.json')
    File.write(supported_path, JSON.pretty_generate(picoruby_methods))
    puts "💾 Saved: #{supported_path}"

    # Save unsupported methods
    unsupported_path = File.join(DATA_DIR, 'picoruby_unsupported_methods.json')
    File.write(unsupported_path, JSON.pretty_generate(unsupported))
    puts "💾 Saved: #{unsupported_path}"
  end

  def display_summary(picoruby_methods, unsupported)
    puts "\n📈 Summary:"
    total_supported = picoruby_methods.values.sum { |h| h[:instance].size + h[:class].size }
    total_unsupported = unsupported.values.sum { |h| h[:instance].size + h[:class].size }

    puts "  ✅ Supported: #{total_supported} methods across #{picoruby_methods.size} classes"
    puts "  ⚠️  Unsupported: #{total_unsupported} methods"
  end
end

# Run if executed directly
MethodDatabaseUpdater.new.run if __FILE__ == $PROGRAM_NAME
