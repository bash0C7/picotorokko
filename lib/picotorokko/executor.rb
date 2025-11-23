require "open3"
require "bundler"

# rbs_inline: enabled

module Picotorokko
  # 外部コマンド実行の抽象化層
  # ProductionExecutor: 実際のコマンド実行（Open3 使用）
  # MockExecutor: テスト用のモック実行
  #
  # 共通の戻り値：[stdout_string, stderr_string]
  # エラー時：RuntimeError をthrow（exit code != 0）

  # 外部コマンド実行インターフェース
  # @rbs < Object
  module Executor
    # コマンドを実行し、stdout と stderr を返す
    # @param command [String] 実行するコマンド
    # @param working_dir [String, nil] 実行時のワーキングディレクトリ
    # @return [Array<String>] [stdout, stderr]
    # @raise [RuntimeError] コマンド失敗時（exit code != 0）
    # @rbs (String, String | nil) -> [String, String]
    def execute(command, working_dir = nil)
      raise NotImplementedError
    end
  end

  # 本番環境用：実際のコマンド実行
  # @rbs < Object
  class ProductionExecutor
    include Executor

    # コマンドを実行し、stdout と stderr を返す
    # Run in isolated environment (Bundler cleared) to avoid interference from ptrk's bundler
    # @rbs (String, String | nil) -> [String, String]
    def execute(command, working_dir = nil)
      execute_block = lambda do
        Bundler.with_unbundled_env do
          stdout, stderr, status = Open3.capture3(command)

          raise "Command failed (exit #{status.exitstatus}): #{command}\nStderr: #{stderr}" unless status.success?

          [stdout, stderr]
        end
      end

      working_dir ? Dir.chdir(working_dir) { execute_block.call } : execute_block.call
    end
  end

  # テスト用：コマンド記録と結果制御
  # @rbs < Object
  class MockExecutor
    include Executor

    # 初期化：コマンド記録用の内部状態
    # @rbs () -> void
    def initialize
      @calls = []
      @results = {} # command => [stdout, stderr, should_fail]
    end

    # コマンドを実行し、事前設定された結果を返す
    # @rbs (String, String | nil) -> [String, String]
    def execute(command, working_dir = nil)
      @calls << { command: command, working_dir: working_dir }

      if @results[command]
        stdout, stderr, should_fail = @results[command]
        raise "Command failed: #{command}\n#{stderr}" if should_fail

        return [stdout, stderr]
      end

      ["", ""] # デフォルト：成功、空の出力
    end

    # テストから呼び出されたコマンドのリスト
    # @rbs () -> Array[Hash[Symbol, String | nil]]
    attr_reader :calls

    # コマンド実行結果を事前設定
    # @rbs (String, stdout: String, stderr: String, fail: bool) -> void
    def set_result(command, stdout: "", stderr: "", fail: false)
      @results[command] = [stdout, stderr, fail]
    end
  end
end
