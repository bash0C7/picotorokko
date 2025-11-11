require "yaml"

module Pra
  module Template
    # Psych ベースの YAML テンプレートエンジン
    # テンプレート内の __PTRK_TEMPLATE_* プレースホルダを置換する
    #
    # 注意: Psych の制限により、置換時にコメントは失われます
    class YamlTemplateEngine
      def initialize(template_path, variables)
        @template_path = template_path
        @variables = variables
      end

      # テンプレートをレンダリングして結果のYAML文字列を返す
      #
      # @return [String] レンダリング後のYAML
      def render
        # YAMLファイルを読み込み
        yaml_data = YAML.load_file(@template_path)

        # プレースホルダを再帰的に置換
        replace_placeholders!(yaml_data, @variables)

        # YAMLとしてダンプ
        YAML.dump(yaml_data, indentation: 2, line_width: -1)
      end

      private

      # オブジェクト内のプレースホルダを再帰的に置換
      #
      # @param obj オブジェクト（Hash, Array, String など）
      # @param variables [Hash] 置換変数
      # @return 置換後のオブジェクト
      def replace_placeholders!(obj, variables)
        case obj
        when Hash
          obj.transform_values! { |v| replace_placeholders!(v, variables) }
        when Array
          obj.map! { |v| replace_placeholders!(v, variables) }
        when String
          replace_string_placeholder(obj, variables)
        else
          obj
        end
      end

      # 文字列内のプレースホルダを置換
      #
      # @param str [String] 対象文字列
      # @param variables [Hash] 置換変数
      # @return [String] 置換後の文字列
      def replace_string_placeholder(str, variables)
        # __PTRK_TEMPLATE_VAR_NAME__ パターンをマッチ
        if str.match?(/\A__PTRK_TEMPLATE_\w+__\z/)
          var_name = str[16..-3].downcase.to_sym # 前後16文字と後ろ2文字を削除
          variables.fetch(var_name, str)
        else
          str
        end
      end
    end
  end
end
