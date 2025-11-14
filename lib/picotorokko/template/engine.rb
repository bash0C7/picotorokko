require_relative "ruby_engine"
require_relative "yaml_engine"
require_relative "c_engine"
require_relative "string_engine"

module Picotorokko
  # Template rendering system with support for multiple file formats
  # Provides unified interface for AST-based and string-based template processing
  module Template
    # 統一的なテンプレートレンダリングインターフェース
    # ファイル拡張子に基づいて適切なエンジンを選択し、テンプレートを処理する
    class Engine
      # テンプレートファイルを指定された変数で処理し、レンダリング結果を返す
      #
      # @param template_path [String] テンプレートファイルのパス
      # @param variables [Hash] テンプレートに展開する変数（キー: シンボル）
      # @return [String] レンダリング後の文字列
      # @rbs (String, Hash[Symbol, untyped]) -> String
      def self.render(template_path, variables)
        engine_class = select_engine(template_path)
        engine_class.new(template_path, variables).render
      end

      # ファイル拡張子に基づいて適切なテンプレートエンジンを選択
      #
      # @param template_path [String] テンプレートファイルのパス
      # @return [Class] エンジンクラス
      # @rbs (String) -> Class
      def self.select_engine(template_path)
        extension = File.extname(template_path)
        case extension
        when ".rb", ".rake"
          RubyTemplateEngine
        when ".yml", ".yaml"
          YamlTemplateEngine
        when ".c", ".h"
          CTemplateEngine
        else
          StringTemplateEngine
        end
      end
    end

    # テストで Ptrk 名前空間を使用するためのエイリアス
    Ptrk = Picotorokko unless defined?(Ptrk)
  end
end
