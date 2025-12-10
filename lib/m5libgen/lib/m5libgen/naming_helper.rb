# frozen_string_literal: true

module M5LibGen
  # Shared naming utilities for consistent function and parameter naming
  module NamingHelper
    # Sanitize parameter name to valid C++ identifier
    def sanitize_parameter_name(name, index)
      # Check if name is invalid (nil, empty, or contains invalid characters)
      if name.nil? || name.empty? || name.match?(/[.\->\s\[\]()]/)
        "param_#{index}"
      else
        name
      end
    end

    # Normalize C++ type name for use in function naming
    def normalize_type_for_naming(cpp_type)
      # Remove const, &, *, spaces and convert to simple identifier
      normalized = cpp_type.strip
      normalized = normalized.gsub(/^const\s+/, "")      # Remove const prefix
      normalized = normalized.gsub(/[&*\s]+$/, "")       # Remove &, *, spaces at end
      normalized = normalized.gsub(/\s+/, "")            # Remove all spaces
      normalized = normalized.gsub(/::|<|>|,/, "_")      # Replace ::, <, >, , with _
      normalized = normalized.gsub(/[^a-zA-Z0-9_]/, "")  # Remove non-alphanumeric
      normalized.downcase
    end

    # Generate unique function name based on class, method, and parameter types
    # This is the CANONICAL naming function used by both C++ wrapper and C bindings
    def generate_unique_function_name(class_name, method)
      base_name = "m5unified_#{class_name.downcase}_#{method[:name].downcase}"

      if method[:parameters].empty?
        return "#{base_name}_void"
      end

      # Generate type signature from parameter types
      type_signature = method[:parameters].map do |p|
        normalize_type_for_naming(p[:type])
      end.join("_")

      "#{base_name}_#{type_signature}"
    end

    # Generate sanitized parameter list for function signature
    def generate_sanitized_params(method)
      if method[:parameters].empty?
        "void"
      else
        method[:parameters].map.with_index do |p, idx|
          sanitized_name = sanitize_parameter_name(p[:name], idx)
          "#{p[:type]} #{sanitized_name}"
        end.join(", ")
      end
    end

    # Get sanitized parameter names for function call
    def get_sanitized_param_names(method)
      method[:parameters].map.with_index do |p, idx|
        sanitize_parameter_name(p[:name], idx)
      end.join(", ")
    end
  end
end
