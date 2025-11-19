# rbs_inline: enabled

require "English"
require "fileutils"
require "yaml"
require "time"
require "shellwords"
require_relative "executor"

module Picotorokko
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
      "R2P2-ESP32" => "https://github.com/picoruby/R2P2-ESP32.git",
      "picoruby-esp32" => "https://github.com/picoruby/picoruby-esp32.git",
      "picoruby" => "https://github.com/picoruby/picoruby.git"
    }.freeze

    # Submodule パス（3段階）
    SUBMODULE_PATHS = {
      "R2P2-ESP32" => "components/picoruby-esp32",
      "picoruby-esp32" => "picoruby"
    }.freeze

    # ====== CRITICAL FIX: Cache initial project root ======
    # PROBLEM: Dynamic methods using Dir.pwd break when tests chdir
    # - export_repo_changes does Dir.chdir(work_path)
    # - Inside that, Picotorokko::Env.patch_dir calls Dir.pwd
    # - Gets wrong path (work_path/ptrk_env/patch instead of original/ptrk_env/patch)
    # - Test assertion fails: Dir.exist?(patch_dir) returns false
    #
    # SOLUTION: Cache the initial project_root once, then use cached value
    # Only reset in tests via @reset_cached_root call
    @cached_project_root = Dir.pwd.freeze
    @reset_cached_root_enabled = true

    class << self
      # ====== Executor（外部コマンド実行） ======
      # NOTE: Configurable for testing (MockExecutor) and production (ProductionExecutor)

      # Set custom executor for testing (MockExecutor) or production
      # @rbs (Executor) -> void
      def set_executor(executor)
        @executor = executor
      end

      # Get current executor instance (defaults to ProductionExecutor)
      # @rbs () -> Executor
      def executor
        @executor ||= ProductionExecutor.new
      end

      # ====== Dynamic Directory Paths (Cache-based) ======
      # NOTE: Caches initial project_root to prevent Dir.chdir interference
      # This ensures patch_dir, cache_dir always point to the original project root
      # not the current working directory

      # Get project root directory (caches initial Dir.pwd)
      # @rbs () -> String
      def project_root
        @project_root ||= Dir.pwd
      end

      # Reset cached project_root for testing
      # @rbs () -> void
      def reset_cached_root!
        return unless @reset_cached_root_enabled

        @project_root = Dir.pwd
      end

      # Get cache directory path for immutable repository copies
      # @rbs () -> String
      def cache_dir
        File.join(project_root, ENV_DIR, ".cache")
      end

      # Get patch directory path for storing repository changes
      # @rbs () -> String
      def patch_dir
        File.join(project_root, ENV_DIR, "patch")
      end

      # Get storage home directory path
      # @rbs () -> String
      def storage_home
        File.join(project_root, "storage", "home")
      end

      # Get environment definition file path (.picoruby-env.yml)
      # @rbs () -> String
      def env_file
        File.join(project_root, ENV_DIR, ".picoruby-env.yml")
      end

      # ====== Environment Name Validation ======

      # Validate environment name matches expected pattern
      # @rbs (String) -> void
      def validate_env_name!(name)
        return if name.match?(ENV_NAME_PATTERN)

        raise "Error: Invalid environment name '#{name}'. Must match pattern: #{ENV_NAME_PATTERN}"
      end

      # ====== Environment Definition (YAML) Operations ======

      # Load environment definitions from .picoruby-env.yml
      # @rbs () -> Hash[String, untyped]
      def load_env_file
        return {} unless File.exist?(env_file)

        YAML.load_file(env_file) || {}
      end

      # Save environment definitions to .picoruby-env.yml
      # @rbs (Hash[String, untyped]) -> void
      def save_env_file(data)
        FileUtils.mkdir_p(File.dirname(env_file))
        File.write(env_file, YAML.dump(data))
      end

      # Get specific environment definition by name
      # @rbs (String) -> Hash[String, untyped] | nil
      def get_environment(env_name)
        data = load_env_file
        environments = data["environments"] || {}
        environments[env_name]
      end

      # Create or update environment definition
      # @rbs (String, Hash[String, untyped], Hash[String, untyped], Hash[String, untyped], notes: String) -> void
      def set_environment(env_name, r2p2_info, esp32_info, picoruby_info, notes: "")
        data = load_env_file
        data["environments"] ||= {}

        data["environments"][env_name] = {
          "R2P2-ESP32" => r2p2_info,
          "picoruby-esp32" => esp32_info,
          "picoruby" => picoruby_info,
          "created_at" => Time.now.to_s,
          "notes" => notes
        }

        save_env_file(data)
      end

      # Get current environment (deprecated - always returns nil)
      # @rbs () -> nil
      def get_current_env
        nil
      end

      # Set current environment (deprecated - no-op for backward compatibility)
      # @rbs (String) -> void
      def set_current_env(_env_name)
        # No-op: current environment logic removed in Phase 4.1
      end

      # ====== Git Operations ======

      # Fetch remote commit hash from git repository URL
      # @rbs (String, String) -> String | nil
      def fetch_remote_commit(repo_url, ref = "HEAD")
        output = `git ls-remote #{Shellwords.escape(repo_url)} #{Shellwords.escape(ref)}`
        return nil if output.empty?

        output.split.first[0..6] # 7-digit commit hash
      end

      # Clone repository to specified path and checkout commit
      # @rbs (String, String, String) -> void
      def clone_repo(repo_url, dest_path, commit)
        return if Dir.exist?(dest_path)

        puts "Cloning #{repo_url} to #{dest_path}..."
        cmd = "git clone --filter=blob:none #{Shellwords.escape(repo_url)} #{Shellwords.escape(dest_path)}"
        executor.execute(cmd)

        # 指定コミットにチェックアウト
        cmd = "git checkout #{Shellwords.escape(commit)}"
        executor.execute(cmd, dest_path)
      end

      # Clone repository and initialize all submodules recursively
      # @rbs (String, String, String) -> void
      def clone_with_submodules(repo_url, dest_path, commit)
        clone_repo(repo_url, dest_path, commit)

        # Initialize submodules
        cmd = "git submodule update --init --recursive"
        executor.execute(cmd, dest_path)
      end

      # Clone repository to cache directory with full submodule initialization (3 levels)
      # Stores immutable copies for use in build environments
      # @rbs (String, String, String, String) -> String
      def cache_clone_with_submodules(repo_name, repo_url, commit_sha, timestamp)
        commit_hash = "#{commit_sha}-#{timestamp}"
        cache_path = get_cache_path(repo_name, commit_hash)

        # Skip if already cached
        return cache_path if Dir.exist?(cache_path)

        FileUtils.mkdir_p(File.dirname(cache_path))
        clone_with_submodules(repo_url, cache_path, commit_sha)

        cache_path
      end

      # Generate commit-hash string from commit reference (short hash + timestamp)
      # @rbs (String, String) -> String
      def get_commit_hash(repo_path, commit)
        Dir.chdir(repo_path) do
          short_hash = `git rev-parse --short=7 #{Shellwords.escape(commit)}`.strip
          raise "Failed to get commit hash for '#{commit}' in repository: #{repo_path}" if short_hash.empty?

          timestamp_str = `git show -s --format=%ci #{Shellwords.escape(commit)}`.strip
          raise "Failed to get commit hash for '#{commit}' in repository: #{repo_path}" if timestamp_str.empty?

          timestamp = Time.parse(timestamp_str).strftime("%Y%m%d_%H%M%S")
          "#{short_hash}-#{timestamp}"
        end
      end

      # Traverse nested submodules (3 levels deep) and collect commit info
      # Returns [info_hash, warnings_array]
      # @rbs (String) -> [Hash[String, String], Array[String]]
      def traverse_submodules_and_validate(repo_path)
        info = {}
        warnings = []

        # Collect R2P2-ESP32 info
        r2p2_short = `git -C #{Shellwords.escape(repo_path)} rev-parse --short=7 HEAD`.strip
        raise "Failed to get commit hash from git repository: #{repo_path}" if r2p2_short.empty?

        r2p2_timestamp = get_timestamp(repo_path)
        info["R2P2-ESP32"] = "#{r2p2_short}-#{r2p2_timestamp}"

        # Level 1: components/picoruby-esp32
        esp32_path = File.join(repo_path, "components", "picoruby-esp32")
        if Dir.exist?(esp32_path)
          esp32_short = `git -C #{Shellwords.escape(esp32_path)} rev-parse --short=7 HEAD`.strip
          raise "Failed to get commit hash from git repository: #{esp32_path}" if esp32_short.empty?

          esp32_timestamp = get_timestamp(esp32_path)
          info["picoruby-esp32"] = "#{esp32_short}-#{esp32_timestamp}"

          # Level 2: picoruby-esp32/picoruby
          picoruby_path = File.join(esp32_path, "picoruby")
          if Dir.exist?(picoruby_path)
            picoruby_short = `git -C #{Shellwords.escape(picoruby_path)} rev-parse --short=7 HEAD`.strip
            raise "Failed to get commit hash from git repository: #{picoruby_path}" if picoruby_short.empty?

            picoruby_timestamp = get_timestamp(picoruby_path)
            info["picoruby"] = "#{picoruby_short}-#{picoruby_timestamp}"

            # Warn about Level 3+ submodules
            if has_submodules?(picoruby_path)
              warnings << "WARNING: Found submodule(s) in picoruby (4th level and beyond) - not handled by this tool"
            end
          end
        end

        [info, warnings]
      end

      # ====== Utilities ======

      # Get commit timestamp from repository (local timezone)
      # @rbs (String) -> String
      def get_timestamp(repo_path)
        timestamp_str = `git -C #{Shellwords.escape(repo_path)} show -s --format=%ci HEAD`.strip
        raise "Failed to get timestamp from git repository: #{repo_path}" if timestamp_str.empty?

        Time.parse(timestamp_str).strftime("%Y%m%d_%H%M%S")
      end

      # Fetch repository information from remote URL
      # Clones repo, gets commit info, then cleans up
      # @rbs (String, String) -> Hash[String, String]
      def fetch_repo_info(repo_name, repo_url)
        Dir.mktmpdir do |tmpdir|
          clone_path = File.join(tmpdir, repo_name)

          # Clone repository
          clone_cmd = "git clone --filter=blob:none --depth 1 " \
                      "#{Shellwords.escape(repo_url)} #{Shellwords.escape(clone_path)}"
          unless system(clone_cmd, out: File::NULL, err: File::NULL)
            raise "Command failed: #{clone_cmd}"
          end

          # Get commit hash
          short_hash = `git -C #{Shellwords.escape(clone_path)} rev-parse --short=7 HEAD`.strip
          raise "Failed to get commit hash from #{repo_url}" if short_hash.empty?

          # Get timestamp
          timestamp_str = `git -C #{Shellwords.escape(clone_path)} show -s --format=%ci HEAD`.strip
          raise "Failed to get timestamp from #{repo_url}" if timestamp_str.empty?

          timestamp = Time.parse(timestamp_str).strftime("%Y%m%d_%H%M%S")

          { "commit" => short_hash, "timestamp" => timestamp }
        end
      end

      # Check if repository has .gitmodules file
      # @rbs (String) -> bool
      def has_submodules?(repo_path)
        gitmodules_path = File.join(repo_path, ".gitmodules")
        File.exist?(gitmodules_path)
      end

      # Generate environment hash string from three repo info strings
      # @rbs (String, String, String) -> String
      def generate_env_hash(r2p2_info, esp32_info, picoruby_info)
        "#{r2p2_info}_#{esp32_info}_#{picoruby_info}"
      end

      # Compute environment hash values from environment name
      # Returns [r2p2_hash, esp32_hash, picoruby_hash, env_hash] or nil
      # @rbs (String) -> Array[String] | nil
      def compute_env_hash(env_name)
        env_config = get_environment(env_name)
        return nil unless env_config

        r2p2_hash = "#{env_config["R2P2-ESP32"]["commit"]}-#{env_config["R2P2-ESP32"]["timestamp"]}"
        esp32_hash = "#{env_config["picoruby-esp32"]["commit"]}-#{env_config["picoruby-esp32"]["timestamp"]}"
        picoruby_hash = "#{env_config["picoruby"]["commit"]}-#{env_config["picoruby"]["timestamp"]}"

        env_hash = generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
        [r2p2_hash, esp32_hash, picoruby_hash, env_hash]
      end

      # Get cache path for immutable repository copy
      # @rbs (String, String) -> String
      def get_cache_path(repo_name, commit_hash)
        File.join(cache_dir, repo_name, commit_hash)
      end

      # Get build environment path (working directory for environment)
      # @rbs (String) -> String
      def get_build_path(env_name)
        # Phase 4: Build path uses env_name instead of env_hash
        # Pattern: ptrk_env/{env_name} instead of build/{env_hash}
        File.join(project_root, ENV_DIR, env_name)
      end

      # Create symbolic link (replace if exists)
      # @rbs (String, String) -> void
      def create_symlink(target, link)
        FileUtils.rm_f(link) if File.exist?(link) || File.symlink?(link)
        FileUtils.ln_s(target, link)
      end

      # Read symlink target path
      # @rbs (String) -> String | nil
      def read_symlink(link)
        return nil unless File.symlink?(link)

        File.readlink(link)
      end

      # Execute command via R2P2-ESP32 Rakefile with ESP-IDF environment
      # NOTE: ESP-IDF setup is R2P2-ESP32 Rakefile responsibility
      # ptrk gem only invokes Rake in R2P2-ESP32 directory
      # @rbs (String, String | nil) -> void
      def execute_with_esp_env(command, working_dir = nil)
        executor.execute(command, working_dir)
      end
    end

    # 後方互換性のための定数インターフェース
    # MODULE レベルで定義：モジュール上の定数ルックアップで呼び出される
    # （既存コードで Picotorokko::Env::PROJECT_ROOT のような参照があった場合）
    # NOTE: CRITICAL FIX - Use project_root method, not Dir.pwd directly
    # This ensures const_missing returns cached values, consistent with dynamic methods
    def self.const_missing(name)
      case name
      when :PROJECT_ROOT
        project_root
      when :CACHE_DIR
        cache_dir
      when :PATCH_DIR
        patch_dir
      when :STORAGE_HOME
        storage_home
      when :ENV_FILE
        env_file
      when :BUILD_DIR
        File.join(project_root, "build")
      else
        super
      end
    end
  end
end
