module Picotorokko
  # BuildConfigApplier: Insert mrbgem definitions into build_config/*.rb files
  # Uses Prism AST to find MRuby::Build.new block and insert conf.gem lines
  class BuildConfigApplier
    def self.apply(content, gems)
      new(content, gems).apply
    end

    def initialize(content, gems)
      @content = content
      @gems = gems
    end

    def apply
      # Parse with Prism to find MRuby::Build.new block
      result = Prism.parse(@content)
      return @content unless result.success?

      extractor = BuildBlockExtractor.new
      result.value.accept(extractor)

      return @content unless extractor.build_block_found?

      # Remove existing marker section and insert new gems
      modified = remove_existing_marker(@content)
      insert_gems_at_block_end(modified, extractor)
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

    def insert_gems_at_block_end(content, _extractor)
      lines = content.split("\n")

      # Find the line with the closing "end" of the MRuby::Build block
      # The extractor found the block, so we locate it and insert before the final "end"
      build_end_line = find_build_block_end_line(lines)
      return content unless build_end_line

      gem_lines = generate_gem_lines
      marker_lines = [
        "  # === BEGIN Mrbgemfile generated ===",
        *gem_lines,
        "  # === END Mrbgemfile generated ==="
      ]

      lines.insert(build_end_line, *marker_lines)
      lines.join("\n")
    end

    def find_build_block_end_line(lines)
      # Find "MRuby::Build.new do |conf|" and match the closing "end"
      build_start = lines.find_index { |line| line.match?(/MRuby::Build\.new\s+do\s*\|conf\|/) }
      return nil unless build_start

      depth = 0
      build_start.upto(lines.length - 1) do |index|
        line = lines[index]
        depth += line.scan(/\bdo\b/).length + line.count("{")
        depth -= line.scan(/\bend\b/).length + line.count("}")

        return index if depth.zero? && index > build_start
      end
      nil
    end

    def generate_gem_lines
      @gems.map { |gem| "  #{format_gem_line(gem)}" }
    end

    def format_gem_line(gem)
      source_line = "conf.gem #{gem[:source_type]}: \"#{gem[:source]}\""
      params = format_optional_params(gem)
      params.empty? ? source_line : "#{source_line}, #{params.join(", ")}"
    end

    def format_optional_params(gem)
      params = []
      params << "branch: \"#{gem[:branch]}\"" if gem[:branch]
      params << "ref: \"#{gem[:ref]}\"" if gem[:ref]
      params << "cmake: \"#{gem[:cmake]}\"" if gem[:cmake]
      params
    end
  end

  # Visitor to find MRuby::Build.new blocks
  class BuildBlockExtractor < Prism::Visitor
    attr_reader :build_block_found

    def initialize
      super
      @build_block_found = false
    end

    def build_block_found?
      @build_block_found
    end

    def visit_call_node(node)
      # Check if this is MRuby::Build.new do |conf| block
      @build_block_found = true if mrbuild_new?(node)
      super
    end

    private

    def mrbuild_new?(node)
      # Check method: new
      return false unless node.name == :new

      # Check if receiver is MRuby::Build constant path
      return false unless node.receiver

      receiver_code = receiver_slice(node.receiver)
      receiver_code == "MRuby::Build"
    end

    def receiver_slice(receiver)
      case receiver
      when Prism::ConstantPathNode, Prism::ConstantReadNode
        receiver.slice
      end
    rescue StandardError
      nil
    end
  end
end
