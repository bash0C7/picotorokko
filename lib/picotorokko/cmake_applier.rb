module Picotorokko
  # CMakeApplier: Insert CMake directives into CMakeLists.txt
  # Adds raw CMake strings for C source files and compilation flags
  class CMakeApplier
    def self.apply(content, cmake_directives)
      new(content, cmake_directives).apply
    end

    def initialize(content, cmake_directives)
      @content = content
      @cmake_directives = cmake_directives
    end

    def apply
      # Remove existing marker section if present
      content = remove_existing_marker(@content)

      # If no directives, return unchanged
      return content if @cmake_directives.empty?

      # Generate new marker section
      marker_lines = generate_marker_section

      # Append to end
      if content.empty?
        marker_lines.join("\n")
      else
        "#{content}\n#{marker_lines.join("\n")}"
      end
    end

    private

    def remove_existing_marker(content)
      lines = content.split("\n")

      begin_idx = lines.find_index { |line| line.include?("# === BEGIN Mrbgemfile generated ===") }
      return content unless begin_idx

      end_idx = lines.find_index { |line| line.include?("# === END Mrbgemfile generated ===") }
      return content unless end_idx && end_idx > begin_idx

      # Remove marker section
      lines[begin_idx..end_idx] = []
      lines.join("\n")
    end

    def generate_marker_section
      [
        "# === BEGIN Mrbgemfile generated ===",
        *@cmake_directives,
        "# === END Mrbgemfile generated ==="
      ]
    end
  end
end
