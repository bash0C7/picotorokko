module Picotorokko
  # MrbgemsDSL: Parser for Mrbgemfile with Ruby DSL evaluation
  # Converts Mrbgemfile syntax into structured gem specifications
  class MrbgemsDSL
    def initialize(dsl_code, config_name)
      @dsl_code = dsl_code
      @config_name = config_name
      @gems = []
      @build_config_files = []
    end

    def gems
      evaluate_dsl
      @gems
    end

    def mrbgems
      yield self
    end

    # conf メソッドエイリアス（conf.gem を使用可能にする）
    def conf
      self
    end

    # gem メソッド：単一の mrbgem を追加
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

    # build_config_files メソッド：条件分岐用
    def build_config_files
      [@config_name]
    end

    private

    def evaluate_dsl
      instance_eval(@dsl_code, __FILE__)
    end

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
