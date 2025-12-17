require "erb"

module Picotorokko
  module Template
    # テキストテンプレートエンジン
    # Markdownやその他のテキストファイル向けのERBエンジン
    class StringTemplateEngine
      # @rbs (String, Hash[Symbol, untyped]) -> void
      def initialize(template_path, variables)
        @template_path = template_path
        @variables = variables
      end

      # テンプレートをレンダリングして結果の文字列を返す
      #
      # @return [String] レンダリング後の文字列
      # @rbs () -> String
      def render
        source = File.read(@template_path, encoding: "UTF-8")

        context_obj = Object.new
        @variables.each do |key, value|
          context_obj.define_singleton_method(key) { value }
        end

        erb = ERB.new(source, trim_mode: "-")
        erb.result(context_obj.instance_eval { binding })
      end
    end
  end
end
