module Picotorokko
  # BuildConfigApplier: Insert mrbgem definitions into build_config/*.rb files
  # Adds conf.gem lines inside MRuby::Build.new block with marker comments
  class BuildConfigApplier
    def self.apply(content, gems)
      new(content, gems).apply
    end

    def initialize(content, gems)
      @content = content
      @gems = gems
    end

    def apply
      # Find MRuby::Build.new block and insert gems
      insert_gems_into_build_block(@content)
    end

    private

    def insert_gems_into_build_block(content)
      lines = content.split("\n")
      build_start = find_build_start(lines)

      return content unless build_start

      # Remove existing marker section if present
      lines = remove_existing_marker(lines, build_start)

      build_end = find_build_end(lines, build_start)
      return content unless build_end

      # Insert new marker section
      gem_lines = generate_gem_lines
      marker_lines = [
        "  # === BEGIN Mrbgemfile generated ===",
        *gem_lines,
        "  # === END Mrbgemfile generated ==="
      ]

      # Insert before the closing "end"
      lines.insert(build_end, *marker_lines)
      lines.join("\n")
    end

    def remove_existing_marker(lines, _build_start)
      begin_marker = lines.find_index { |line| line.include?("# === BEGIN Mrbgemfile generated ===") }
      return lines unless begin_marker

      end_marker = lines.find_index { |line| line.include?("# === END Mrbgemfile generated ===") }
      return lines unless end_marker && end_marker > begin_marker

      # Remove from begin to end inclusive
      lines[begin_marker..end_marker] = []
      lines
    end

    def find_build_start(lines)
      lines.find_index { |line| line.match?(/MRuby::Build\.new\s+do\s*\|conf\|/) }
    end

    def find_build_end(lines, start_index)
      depth = 0
      start_index.upto(lines.length - 1) do |index|
        line = lines[index]
        # Count opening keywords: do, {
        depth += line.scan(/\bdo\b/).length
        depth += line.count("{")
        # Count closing keywords: end, }
        depth -= line.scan(/\bend\b/).length
        depth -= line.count("}")

        # When depth reaches 0 after the starting line, we found the closing end
        return index if depth.zero? && index > start_index
      end
      nil
    end

    def generate_gem_lines
      @gems.map { |gem| "  #{format_gem_line(gem)}" }
    end

    def format_gem_line(gem)
      source_line = case gem[:source_type]
                    when :github
                      "conf.gem github: \"#{gem[:source]}\""
                    when :core
                      "conf.gem core: \"#{gem[:source]}\""
                    when :path
                      "conf.gem path: \"#{gem[:source]}\""
                    when :git
                      "conf.gem git: \"#{gem[:source]}\""
                    end

      # Add optional parameters
      params = []
      params << "branch: \"#{gem[:branch]}\"" if gem[:branch]
      params << "ref: \"#{gem[:ref]}\"" if gem[:ref]
      params << "cmake: \"#{gem[:cmake]}\"" if gem[:cmake]

      params.empty? ? source_line : "#{source_line}, #{params.join(", ")}"
    end
  end
end
