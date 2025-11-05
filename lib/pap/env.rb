# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'time'
require 'shellwords'

module Pap
  # PicoRuby環境管理モジュール
  module Env
    # ルートディレクトリ
    PROJECT_ROOT = Dir.pwd
    CACHE_DIR = File.join(PROJECT_ROOT, '.cache')
    BUILD_DIR = File.join(PROJECT_ROOT, 'build')
    PATCH_DIR = File.join(PROJECT_ROOT, 'patch')
    STORAGE_HOME = File.join(PROJECT_ROOT, 'storage', 'home')
    ENV_FILE = File.join(PROJECT_ROOT, '.picoruby-env.yml')

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
      # ====== YAML操作 ======

      # .picoruby-env.yml を読み込み
      def load_env_file
        return {} unless File.exist?(ENV_FILE)
        YAML.load_file(ENV_FILE) || {}
      end

      # .picoruby-env.yml に保存
      def save_env_file(data)
        FileUtils.mkdir_p(File.dirname(ENV_FILE))
        File.write(ENV_FILE, YAML.dump(data))
      end

      # 環境定義を読み込み
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

      # 現在の環境名を取得
      def get_current_env
        data = load_env_file
        data['current']
      end

      # 現在の環境名を設定
      def set_current_env(env_name)
        data = load_env_file
        data['current'] = env_name
        save_env_file(data)
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
        unless system("git clone #{Shellwords.escape(repo_url)} #{Shellwords.escape(dest_path)}")
          raise "Failed to clone repository"
        end

        # 指定コミットにチェックアウト
        Dir.chdir(dest_path) do
          unless system("git checkout #{Shellwords.escape(commit)}")
            raise "Failed to checkout commit #{commit}"
          end
        end
      end

      # リポジトリをクローン＆submodule初期化
      def clone_with_submodules(repo_url, dest_path, commit)
        clone_repo(repo_url, dest_path, commit)

        Dir.chdir(dest_path) do
          # Submodule初期化
          unless system('git submodule update --init --recursive')
            raise "Failed to initialize submodules"
          end
        end
      end

      # コミット情報からcommit-hash形式を生成
      def get_commit_hash(repo_path, commit)
        Dir.chdir(repo_path) do
          short_hash = `git rev-parse --short=7 #{Shellwords.escape(commit)}`.strip
          timestamp_str = `git show -s --format=%ci #{Shellwords.escape(commit)}`.strip
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
        r2p2_timestamp = get_timestamp(repo_path)
        info['R2P2-ESP32'] = "#{r2p2_short}-#{r2p2_timestamp}"

        # Level 1: components/picoruby-esp32
        esp32_path = File.join(repo_path, 'components', 'picoruby-esp32')
        if Dir.exist?(esp32_path)
          esp32_short = `git -C #{Shellwords.escape(esp32_path)} rev-parse --short=7 HEAD`.strip
          esp32_timestamp = get_timestamp(esp32_path)
          info['picoruby-esp32'] = "#{esp32_short}-#{esp32_timestamp}"

          # Level 2: picoruby-esp32/picoruby
          picoruby_path = File.join(esp32_path, 'picoruby')
          if Dir.exist?(picoruby_path)
            picoruby_short = `git -C #{Shellwords.escape(picoruby_path)} rev-parse --short=7 HEAD`.strip
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

      # キャッシュディレクトリを取得
      def get_cache_path(repo_name, commit_hash)
        File.join(CACHE_DIR, repo_name, commit_hash)
      end

      # ビルドディレクトリを取得
      def get_build_path(env_hash)
        File.join(BUILD_DIR, env_hash)
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

      # ESP-IDF環境変数設定
      def setup_esp_idf_env
        homebrew_openssl = '/opt/homebrew/opt/openssl'
        esp_idf_path = ENV['IDF_PATH'] || "#{ENV['HOME']}/esp/esp-idf"

        env_vars = {
          'PATH' => "#{homebrew_openssl}/bin:#{ENV['PATH']}",
          'LDFLAGS' => "-L#{homebrew_openssl}/lib #{ENV['LDFLAGS']}",
          'CPPFLAGS' => "-I#{homebrew_openssl}/include #{ENV['CPPFLAGS']}",
          'CFLAGS' => "-I#{homebrew_openssl}/include #{ENV['CFLAGS']}",
          'PKG_CONFIG_PATH' => "#{homebrew_openssl}/lib/pkgconfig:#{ENV['PKG_CONFIG_PATH']}",
          'GRPC_PYTHON_BUILD_SYSTEM_OPENSSL' => '1',
          'GRPC_PYTHON_BUILD_SYSTEM_ZLIB' => '1',
          'ESPBAUD' => '115200',
          'IDF_PATH' => esp_idf_path
        }

        env_vars.each { |key, value| ENV[key] = value }
      end

      # ESP-IDF環境でコマンド実行
      def execute_with_esp_env(command, working_dir = nil)
        esp_idf_path = ENV['IDF_PATH'] || "#{ENV['HOME']}/esp/esp-idf"

        setup_script = <<~SCRIPT
          export PATH="/opt/homebrew/opt/openssl/bin:$PATH"
          export LDFLAGS="-L/opt/homebrew/opt/openssl/lib $LDFLAGS"
          export CPPFLAGS="-I/opt/homebrew/opt/openssl/include $CPPFLAGS"
          export CFLAGS="-I/opt/homebrew/opt/openssl/include $CFLAGS"
          export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl/lib/pkgconfig:$PKG_CONFIG_PATH"
          export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
          export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
          export ESPBAUD=115200
          . #{Shellwords.escape(esp_idf_path)}/export.sh
          #{command}
        SCRIPT

        if working_dir
          Dir.chdir(working_dir) do
            success = system('bash', '-c', setup_script)
            raise "Command failed: #{command}" unless success
          end
        else
          success = system('bash', '-c', setup_script)
          raise "Command failed: #{command}" unless success
        end
      end
    end
  end
end
