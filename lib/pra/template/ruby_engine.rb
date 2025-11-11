require "prism"

module Pra
  module Template
    # Prism AST ベースのRubyテンプレートエンジン
    # テンプレート内の TEMPLATE_* 定数をプレースホルダとして認識し、置換する
    class RubyTemplateEngine
      def initialize(template_path, variables)
        @template_path = template_path
        @variables = variables
      end

      # テンプレートをレンダリングして結果の文字列を返す
      #
      # @return [String] レンダリング後のRubyコード
      # @raise [StandardError] テンプレートまたは出力が無効なRubyの場合
      def render
        # テンプレートを読み込み、有効性を検証
        template_source = File.read(@template_path, encoding: "UTF-8")
        verify_template_validity!(template_source)

        # AST を解析してプレースホルダを検出
        parse_result = Prism.parse(template_source)
        visitor = PlaceholderVisitor.new(@variables)
        parse_result.value.accept(visitor)

        # プレースホルダを置換
        output = apply_replacements(template_source, visitor.replacements)

        # 出力の有効性を検証
        verify_output_validity!(output)

        output
      end

      private

      # テンプレートが有効なRubyコードであることを確認
      def verify_template_validity!(source)
        result = Prism.parse(source)
        return if result.success?

        raise "テンプレートが無効なRubyコードです: #{@template_path}"
      end

      # 出力が有効なRubyコードであることを確認
      def verify_output_validity!(source)
        result = Prism.parse(source)
        return if result.success?

        raise "レンダリング後のコードが無効なRubyコードです"
      end

      # 検出されたプレースホルダを置換
      #
      # @param source [String] 元のソースコード
      # @param replacements [Array] 置換情報の配列
      # @return [String] 置換後のコード
      def apply_replacements(source, replacements)
        output = source.dup

        # オフセットを保持するため、逆順で置換
        replacements.sort_by { |r| -r[:range].begin }.each do |replacement|
          output[replacement[:range]] = replacement[:new_value]
        end

        output
      end
    end

    # TEMPLATE_* プレースホルダを検出するVisitor
    class PlaceholderVisitor < Prism::Visitor
      attr_reader :replacements

      def initialize(variables)
        super()
        @variables = variables
        @replacements = []
      end

      def visit_constant_read_node(node)
        const_name = node.name.to_s
        if const_name.start_with?("TEMPLATE_")
          var_name = const_name.sub(/^TEMPLATE_/, "").downcase.to_sym
          if @variables.key?(var_name)
            @replacements << {
              range: node.location.start_offset...node.location.end_offset,
              old_value: const_name,
              new_value: @variables[var_name].to_s
            }
          end
        end

        super
      end
    end
  end
end
