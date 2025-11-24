# rbs_inline: enabled

module Picotorokko
  # MrbgemsDSL: Parser for Mrbgemfile with Ruby DSL evaluation
  # Converts Mrbgemfile syntax into structured gem specifications
  # @rbs < Object
  class MrbgemsDSL
    # @rbs (String, String) -> void
    def initialize(dsl_code, config_name)
      @dsl_code = dsl_code
      @config_name = config_name
      @gems = []
      @build_config_files = []
    end

    # @rbs () -> Array[Hash[Symbol, (String | Symbol | nil)]]
    def gems
      evaluate_dsl
      @gems
    end

    # @rbs () { (self) -> void } -> void
    def mrbgems
      yield self
    end

    # @rbs () -> self
    def conf
      self
    end

    # @rbs (String | nil, **Hash[Symbol, String]) -> void
    def gem(path_or_name = nil, **params)
      # If first arg is a string (path), treat as path gem
      if path_or_name && params.empty?
        source_type = :path
        source = path_or_name
      else
        source_type, source = detect_source_type(params)
      end

      gem_spec = {
        source_type: source_type,
        source: source,
        branch: params[:branch],
        ref: params[:ref],
        cmake: params[:cmake]
      }
      @gems << gem_spec
    end

    # @rbs () -> Array[String]
    def build_config_files
      [@config_name]
    end

    private

    # @rbs () -> untyped
    def evaluate_dsl
      instance_eval(@dsl_code, __FILE__)
    end

    # @rbs (Hash[Symbol, untyped]) -> [Symbol, String]
    def detect_source_type(params)
      if params[:github]
        [:github, params[:github]]
      elsif params[:core]
        [:core, params[:core]]
      elsif params[:path]
        [:path, params[:path]]
      elsif params[:git]
        [:git, params[:git]]
      else
        raise ArgumentError, "Unknown source type in gem specification: #{params.keys.inspect}"
      end
    end
  end
end
