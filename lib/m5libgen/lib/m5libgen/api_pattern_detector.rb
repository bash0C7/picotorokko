# frozen_string_literal: true

module M5LibGen
  # Detects and handles M5Unified-specific API patterns
  class ApiPatternDetector
    # Button class singletons in M5Unified
    BUTTON_SINGLETONS = %w[BtnA BtnB BtnC BtnPWR].freeze

    def initialize(cpp_data)
      @cpp_data = cpp_data
    end

    # Detect all M5Unified-specific patterns
    def detect_patterns
      {
        button_classes: detect_button_classes,
        singleton_mappings: generate_singleton_mappings,
        display_classes: detect_display_classes,
        predicate_methods: detect_predicate_methods
      }
    end

    # Find Button class definitions
    def detect_button_classes
      @cpp_data.select { |klass| klass[:name] == "Button" }.map { |k| k[:name] }
    end

    # Find Display class definitions
    def detect_display_classes
      @cpp_data.select { |klass| klass[:name] =~ /Display|Screen/ }.map { |k| k[:name] }
    end

    # Generate singleton mappings (Button → BtnA, BtnB, BtnC)
    def generate_singleton_mappings
      {
        "Button" => BUTTON_SINGLETONS
      }
    end

    # Detect methods that should have ? suffix (predicates)
    def detect_predicate_methods
      predicates = []

      @cpp_data.each do |klass|
        klass[:methods].each do |method|
          next unless predicate_method?(method)

          predicates << {
            class: klass[:name],
            method: method[:name],
            ruby_name: rubify_method_name(method[:name])
          }
        end
      end

      predicates
    end

    # Check if method is a predicate (bool return or specific naming)
    def predicate_method?(method)
      # Check return type
      return true if method[:return_type] == "bool"

      # Check naming patterns
      method_name = method[:name]
      method_name.start_with?("is", "has", "can", "should", "was") ||
        method_name.end_with?("ed", "able")
    end

    # Convert method name to Ruby idiom (add ? suffix for predicates)
    def rubify_method_name(method_name)
      "#{method_name}?"
    end

    # Generate Ruby-friendly API wrappers
    def generate_ruby_wrappers
      wrappers = []

      @cpp_data.each do |klass|
        # Skip Button class (handled via singletons)
        next if klass[:name] == "Button"

        klass[:methods].each do |method|
          wrapper = {
            class: klass[:name],
            cpp_method: method[:name],
            ruby_method: predicate_method?(method) ? rubify_method_name(method[:name]) : method[:name],
            is_predicate: predicate_method?(method)
          }
          wrappers << wrapper
        end
      end

      wrappers
    end
  end
end
