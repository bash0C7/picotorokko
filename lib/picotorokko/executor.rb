require "open3"

module Picotorokko
  # 外部コマンド実行の抽象化層
  # ProductionExecutor: 実際のコマンド実行（Open3 使用）
  # MockExecutor: テスト用のモック実行
  #
  # 共通の戻り値：[stdout_string, stderr_string]
  # エラー時：RuntimeError をthrow（exit code != 0）

  # 外部コマンド実行インターフェース
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
  class ProductionExecutor
    include Executor

    # @rbs (String, String | nil) -> [String, String]
    def execute(command, working_dir = nil)
      execute_block = lambda do
        stdout, stderr, status = Open3.capture3(command)

        raise "Command failed (exit #{status.exitstatus}): #{command}\nStderr: #{stderr}" unless status.success?

        [stdout, stderr]
      end

      working_dir ? Dir.chdir(working_dir) { execute_block.call } : execute_block.call
    end
  end

  # テスト用：コマンド記録と結果制御
  class MockExecutor
    include Executor

    # @rbs () -> void
    def initialize
      @calls = []
      @results = {} # command => [stdout, stderr, should_fail]
    end

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
    # @return [Array<Hash>] 各呼び出しの { command:, working_dir: }
    attr_reader :calls

    # コマンド実行結果を事前設定
    # @param command [String] コマンド文字列
    # @param stdout [String] 標準出力
    # @param stderr [String] 標準エラー
    # @param fail [Boolean] 失敗を模擬するか
    # @rbs (String, stdout: String, stderr: String, fail: bool) -> void
    def set_result(command, stdout: "", stderr: "", fail: false)
      @results[command] = [stdout, stderr, fail]
    end
  end
end
