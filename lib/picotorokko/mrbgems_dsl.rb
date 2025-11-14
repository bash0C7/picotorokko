module Picotorokko
  # MrbgemsDSL: Parser for Mrbgemfile with Ruby DSL evaluation
  # Converts Mrbgemfile syntax into structured gem specifications
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

    # @rbs (**Hash[Symbol, String]) -> void
    def gem(**params)
      source_type, source = detect_source_type(params)
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
