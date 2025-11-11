require "erb"

module Pra
  module Template
    # 汎用テキストテンプレートエンジン
    # Markdownやその他のテキストファイル向けのフォールバック
    # .erb ファイルの場合は ERB を処理
    # その他のファイルの場合は {{VARIABLE_NAME}} プレースホルダを置換
    class StringTemplateEngine
      def initialize(template_path, variables)
        @template_path = template_path
        @variables = variables
      end

      # テンプレートをレンダリングして結果の文字列を返す
      #
      # @return [String] レンダリング後の文字列
      def render
        source = File.read(@template_path, encoding: "UTF-8")

        # .erb ファイルの場合は ERB を処理
        if @template_path.end_with?(".erb")
          render_erb(source)
        else
          render_placeholders(source)
        end
      end

      private

      def render_erb(source)
        context_obj = Object.new
        @variables.each do |key, value|
          context_obj.define_singleton_method(key) { value }
        end

        erb = ERB.new(source, trim_mode: "-")
        erb.result(context_obj.instance_eval { binding })
      end

      def render_placeholders(source)
        # {{VAR_NAME}} パターンのプレースホルダを置換
        @variables.each do |key, value|
          placeholder = "{{#{key.to_s.upcase}}}"
          source.gsub!(placeholder, value.to_s)
        end

        source
      end
    end
  end
end
