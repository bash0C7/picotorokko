module Pra
  module Template
    # C コード用のテンプレートエンジン
    # シンプルな文字列置換アプローチを使用
    # TEMPLATE_* パターンの識別子を変数値で置換する
    class CTemplateEngine
      def initialize(template_path, variables)
        @template_path = template_path
        @variables = variables
      end

      # テンプレートをレンダリングして結果のCコード文字列を返す
      #
      # @return [String] レンダリング後のCコード
      def render
        source = File.read(@template_path, encoding: "UTF-8")

        # 各変数についてプレースホルダを置換
        @variables.each do |key, value|
          placeholder = "TEMPLATE_#{key.to_s.upcase}"
          source.gsub!(placeholder, value.to_s)
        end

        source
      end
    end
  end
end
