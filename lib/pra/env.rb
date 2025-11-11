
require 'English'
require 'fileutils'
require 'yaml'
require 'time'
require 'shellwords'

module Pra
  # PicoRuby環境定義・ビルド環境管理モジュール
  #
  # 用語の定義:
  # - 環境定義（Environment Definition）: .picoruby-env.yml に保存されたメタデータ（コミットハッシュとタイムスタンプ）
  # - ビルド環境（Build Environment）: build/ ディレクトリに構築されたワーキングディレクトリ（実ファイル）
  # - キャッシュ（Cache）: .cache/ ディレクトリに保存された不変のリポジトリコピー
  module Env
    # ptrk env directory name
    ENV_DIR = "ptrk_env".freeze
    # ptrk env name pattern validation (lowercase alphanumeric, dash, underscore)
    ENV_NAME_PATTERN = /^[a-z0-9_-]+$/

    # リポジトリ定義
    REPOS = {
      'R2P2-ESP32' => 'https://github.com/picoruby/R2P2-ESP32.git',
      'picoruby-esp32' => 'https://github.com/picoruby/picoruby-esp32.git',
      'picoruby' => 'https://github.com/picoruby/picoruby.git'
    }.freeze

    # Submodule パス（3段階）
    SUBMODULE_PATHS = {
      'R2P2-ESP32' => 'components/picoruby-esp32',
      'picoruby-esp32' => 'picoruby'
    }.freeze

    class << self
      # ====== ダイナミックディレクトリパス ======
      # NOTE: メソッドとして定義することで、Dir.pwd の変更が自動的に反映される
      # これにより、テストの setup/teardown で Dir.chdir したときに
      # ファイルパス定数が古い値を参照する問題が解決される

      # ルートディレクトリ（現在の作業ディレクトリ）
      def project_root
        Dir.pwd
      end

      # キャッシュディレクトリ
      def cache_dir
        File.join(project_root, ENV_DIR, '.cache')
      end

      # パッチディレクトリ
      def patch_dir
        File.join(project_root, ENV_DIR, 'patch')
      end

      # ストレージホームディレクトリ
      def storage_home
        File.join(project_root, 'storage', 'home')
      end

      # 環境定義ファイルパス
      def env_file
        File.join(project_root, ENV_DIR, '.picoruby-env.yml')
      end

      # ====== 環境名検証 ======

      # 環境名が有効なパターンか検証
      # @param name [String] 検証する環境名
      # @raise [RuntimeError] 無効な環境名の場合
      def validate_env_name!(name)
        return if name.match?(ENV_NAME_PATTERN)
        raise "Error: Invalid environment name '#{name}'. Must match pattern: #{ENV_NAME_PATTERN}"
      end

      # ====== 環境定義（YAML）操作 ======

      # .picoruby-env.yml を読み込み（環境定義のメタデータ）
      def load_env_file
        return {} unless File.exist?(env_file)
        YAML.load_file(env_file) || {}
      end

      # .picoruby-env.yml に保存
      def save_env_file(data)
        FileUtils.mkdir_p(File.dirname(env_file))
        File.write(env_file, YAML.dump(data))
      end

      # 指定された名前の環境定義を読み込み（.picoruby-env.yml から）
      def get_environment(env_name)
        data = load_env_file
        environments = data['environments'] || {}
        environments[env_name]
      end

      # 環境定義を追加/更新
      def set_environment(env_name, r2p2_info, esp32_info, picoruby_info, notes: '')
        data = load_env_file
        data['environments'] ||= {}

        data['environments'][env_name] = {
          'R2P2-ESP32' => r2p2_info,
          'picoruby-esp32' => esp32_info,
          'picoruby' => picoruby_info,
          'created_at' => Time.now.to_s,
          'notes' => notes
        }

        save_env_file(data)
      end

      # Phase 4.1: Current環境ロジック廃止
      # get_current_env は常にnilを返す（暗黙のカレント環境は存在しない）
      def get_current_env
        nil
      end

      # Phase 4.1: Current環境ロジック廃止
      # set_current_env は何もしない（後方互換性のためメソッドのみ残す）
      def set_current_env(_env_name)
        # No-op: current environment logic removed in Phase 4.1
      end

      # ====== Git操作 ======

      # リモートからコミット情報を取得（git ls-remote使用）
      def fetch_remote_commit(repo_url, ref = 'HEAD')
        output = `git ls-remote #{Shellwords.escape(repo_url)} #{Shellwords.escape(ref)} 2>/dev/null`
        return nil if output.empty?
        output.split.first[0..6] # 7桁のコミットハッシュ
      end

      # リポジトリをクローン
      def clone_repo(repo_url, dest_path, commit)
        return if Dir.exist?(dest_path)

        puts "Cloning #{repo_url} to #{dest_path}..."
        cmd = "git clone #{Shellwords.escape(repo_url)} #{Shellwords.escape(dest_path)}"
        unless system(cmd)
          raise "Command failed (exit status: #{$CHILD_STATUS.exitstatus}): #{cmd}"
        end

        # 指定コミットにチェックアウト
        Dir.chdir(dest_path) do
          cmd = "git checkout #{Shellwords.escape(commit)}"
          unless system(cmd)
            raise "Command failed (exit status: #{$CHILD_STATUS.exitstatus}): #{cmd}"
          end
        end
      end

      # リポジトリをクローン＆submodule初期化
      def clone_with_submodules(repo_url, dest_path, commit)
        clone_repo(repo_url, dest_path, commit)

        Dir.chdir(dest_path) do
          # Submodule初期化
          cmd = 'git submodule update --init --recursive'
          unless system(cmd)
            raise "Command failed (exit status: #{$CHILD_STATUS.exitstatus}): #{cmd} (in #{dest_path})"
          end
        end
      end

      # コミット情報からcommit-hash形式を生成
      def get_commit_hash(repo_path, commit)
        Dir.chdir(repo_path) do
          short_hash = `git rev-parse --short=7 #{Shellwords.escape(commit)}`.strip
          if short_hash.empty?
            raise "Failed to get commit hash for '#{commit}' in repository: #{repo_path}"
          end

          timestamp_str = `git show -s --format=%ci #{Shellwords.escape(commit)}`.strip
          if timestamp_str.empty?
            raise "Failed to get commit hash for '#{commit}' in repository: #{repo_path}"
          end

          timestamp = Time.parse(timestamp_str).strftime('%Y%m%d_%H%M%S')
          "#{short_hash}-#{timestamp}"
        end
      end

      # Submodule 3段階トラバース
      def traverse_submodules_and_validate(repo_path)
        info = {}
        warnings = []

        # R2P2-ESP32の情報取得
        r2p2_short = `git -C #{Shellwords.escape(repo_path)} rev-parse --short=7 HEAD`.strip
        if r2p2_short.empty?
          raise "Failed to get commit hash from git repository: #{repo_path}"
        end
        r2p2_timestamp = get_timestamp(repo_path)
        info['R2P2-ESP32'] = "#{r2p2_short}-#{r2p2_timestamp}"

        # Level 1: components/picoruby-esp32
        esp32_path = File.join(repo_path, 'components', 'picoruby-esp32')
        if Dir.exist?(esp32_path)
          esp32_short = `git -C #{Shellwords.escape(esp32_path)} rev-parse --short=7 HEAD`.strip
          if esp32_short.empty?
            raise "Failed to get commit hash from git repository: #{esp32_path}"
          end
          esp32_timestamp = get_timestamp(esp32_path)
          info['picoruby-esp32'] = "#{esp32_short}-#{esp32_timestamp}"

          # Level 2: picoruby-esp32/picoruby
          picoruby_path = File.join(esp32_path, 'picoruby')
          if Dir.exist?(picoruby_path)
            picoruby_short = `git -C #{Shellwords.escape(picoruby_path)} rev-parse --short=7 HEAD`.strip
            if picoruby_short.empty?
              raise "Failed to get commit hash from git repository: #{picoruby_path}"
            end
            picoruby_timestamp = get_timestamp(picoruby_path)
            info['picoruby'] = "#{picoruby_short}-#{picoruby_timestamp}"

            # Level 3以降: warning
            if has_submodules?(picoruby_path)
              warnings << "WARNING: Found submodule(s) in picoruby (4th level and beyond) - not handled by this tool"
            end
          end
        end

        [info, warnings]
      end

      # ====== ユーティリティ ======

      # Timestamp取得（ローカルタイムゾーン）
      def get_timestamp(repo_path)
        timestamp_str = `git -C #{Shellwords.escape(repo_path)} show -s --format=%ci HEAD`.strip
        if timestamp_str.empty?
          raise "Failed to get timestamp from git repository: #{repo_path}"
        end
        Time.parse(timestamp_str).strftime('%Y%m%d_%H%M%S')
      end

      # Submoduleの存在確認
      def has_submodules?(repo_path)
        gitmodules_path = File.join(repo_path, '.gitmodules')
        File.exist?(gitmodules_path)
      end

      # env-hash形式を生成
      def generate_env_hash(r2p2_info, esp32_info, picoruby_info)
        "#{r2p2_info}_#{esp32_info}_#{picoruby_info}"
      end

      # 環境名から3つのハッシュとenv_hashを計算
      # 戻り値: [r2p2_hash, esp32_hash, picoruby_hash, env_hash]
      def compute_env_hash(env_name)
        env_config = get_environment(env_name)
        return nil unless env_config

        r2p2_hash = "#{env_config['R2P2-ESP32']['commit']}-#{env_config['R2P2-ESP32']['timestamp']}"
        esp32_hash = "#{env_config['picoruby-esp32']['commit']}-#{env_config['picoruby-esp32']['timestamp']}"
        picoruby_hash = "#{env_config['picoruby']['commit']}-#{env_config['picoruby']['timestamp']}"

        env_hash = generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
        [r2p2_hash, esp32_hash, picoruby_hash, env_hash]
      end

      # キャッシュディレクトリパスを取得（不変リポジトリコピーの場所）
      def get_cache_path(repo_name, commit_hash)
        File.join(cache_dir, repo_name, commit_hash)
      end

      # ビルド環境ディレクトリパスを取得（ワーキングディレクトリの場所）
      def get_build_path(env_name)
        # Phase 4: Build path uses env_name instead of env_hash
        # Pattern: ptrk_env/{env_name} instead of build/{env_hash}
        File.join(project_root, ENV_DIR, env_name)
      end

      # Symlink操作
      def create_symlink(target, link)
        FileUtils.rm_f(link) if File.exist?(link) || File.symlink?(link)
        FileUtils.ln_s(target, link)
      end

      # Symlink先を取得
      def read_symlink(link)
        return nil unless File.symlink?(link)
        File.readlink(link)
      end

      # R2P2-ESP32 Rakefile でコマンド実行
      # NOTE: ESP-IDF 環境のセットアップは R2P2-ESP32 Rakefile が責任を持つ
      # pra gem は R2P2-ESP32 ディレクトリで Rake コマンドを実行するのみ
      # （直接 ESP-IDF に依存しない - CI 環境で ESP-IDF がない場合も対応可能）
      def execute_with_esp_env(command, working_dir = nil)
        execute_block = lambda do |_dir = nil|
          success = system(command)
          return if success

          exit_status = $CHILD_STATUS&.exitstatus || "unknown"
          location = working_dir ? " (in #{working_dir})" : ""
          raise "Command failed (exit status: #{exit_status}): #{command}#{location}"
        end

        working_dir ? Dir.chdir(working_dir, &execute_block) : execute_block.call
      end
    end

    # 後方互換性のための定数インターフェース
    # MODULE レベルで定義：モジュール上の定数ルックアップで呼び出される
    # （既存コードで Pra::Env::PROJECT_ROOT のような参照があった場合）
    def self.const_missing(name)
      case name
      when :PROJECT_ROOT
        Dir.pwd
      when :CACHE_DIR
        File.join(Dir.pwd, ENV_DIR, '.cache')
      when :PATCH_DIR
        File.join(Dir.pwd, ENV_DIR, 'patch')
      when :STORAGE_HOME
        File.join(Dir.pwd, 'storage', 'home')
      when :ENV_FILE
        File.join(Dir.pwd, ENV_DIR, '.picoruby-env.yml')
      when :BUILD_DIR
        File.join(Dir.pwd, 'build')
      else
        super
      end
    end
  end
end
