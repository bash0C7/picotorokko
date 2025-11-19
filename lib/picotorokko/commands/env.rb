require "English"
require "fileutils"
require "shellwords"
require "thor"
require "picotorokko/patch_applier"

module Picotorokko
  module Commands
    # Environment definition management commands
    # Manages environment metadata stored in .picoruby-env.yml
    # Note: This command manages environment definitions (metadata only).
    # Actual build environment (filesystem) is managed by 'ptrk build' commands
    # @rbs < Thor
    # rubocop:disable Metrics/ClassLength
    class Env < Thor
      # @rbs () -> bool
      def self.exit_on_failure?
        true
      end

      # List all defined environments from .picoruby-env.yml
      # @rbs () -> void
      desc "list", "List all defined environments"
      def list
        env_file = Picotorokko::Env.load_env_file
        environments = env_file["environments"] || {}

        if environments.empty?
          puts "No environments defined yet."
          puts "Run 'pra env latest' to create one automatically"
        else
          puts "Available environments:"
          environments.each do |env_name, env_config|
            puts "  - #{env_name}"
            if env_config.is_a?(Hash)
              puts "    Created: #{env_config["created_at"]}"
              puts "    R2P2-ESP32: #{env_config["R2P2-ESP32"]["commit"]}" if env_config["R2P2-ESP32"]
            end
          end
        end
      end

      # Display environment definition from .picoruby-env.yml
      # @rbs (String) -> void
      desc "show ENV_NAME", "Display environment definition from .picoruby-env.yml"
      def show(env_name)
        env_config = Picotorokko::Env.get_environment(env_name)
        return show_env_not_found(env_name) if env_config.nil?

        show_env_details(env_name, env_config)
      end

      # Create new environment definition with custom repository sources
      #
      # This command creates a new environment definition in .picoruby-env.yml with
      # explicit repository source specifications. It supports three source formats:
      #
      # **Auto-fetch mode** (no options):
      #   When called without any options, automatically fetches the latest commit
      #   from default upstream repositories (picoruby/R2P2-ESP32, etc.)
      #
      # **Explicit mode** (all three options required):
      #   When any option is specified, all three repository options must be provided.
      #   Supports three source format types:
      #
      #   1. **GitHub org/repo format**: `"owner/repository"`
      #      - Example: `--R2P2-ESP32 "picoruby/R2P2-ESP32"`
      #      - Fetches latest commit from GitHub (requires network access)
      #      - Stored as: `source: "https://github.com/owner/repository.git"`
      #
      #   2. **Local path format**: `"path:/absolute/or/relative/path"`
      #      - Example: `--picoruby "path:../picoruby-local"`
      #      - Uses current commit from local Git repository
      #      - Stored as: `source: "path:/absolute/or/relative/path"`
      #
      #   3. **Pinned commit format**: `"path:/path:COMMIT_SHA"`
      #      - Example: `--picoruby-esp32 "path:../picoruby-esp32:abc1234"`
      #      - Uses specified commit SHA from local repository (7+ characters)
      #      - Stored as: `source: "path:/path", commit: "abc1234"`
      #      - Useful for reproducible builds with specific commits
      #
      # **Format string parsing**:
      #   The command delegates format detection to `process_source`, which:
      #   - Checks for "path:" prefix → routes to `process_path_source`
      #   - Otherwise → routes to `process_github_source` (assumes org/repo)
      #   - Path format uses regex: `/^path:(.+):([a-f0-9]{7,})$/` for pinned commits
      #
      # **Relationship to other commands**:
      #   - Delegates to `auto_fetch_environment` when no options provided
      #   - Calls `process_source` for each repository option
      #   - Stores result via `Picotorokko::Env.set_environment`
      #
      # @param env_name [String] Name for the new environment definition
      #
      # @example Auto-fetch latest versions
      #   $ ptrk env set production
      #   # Creates environment with latest commits from default repos
      #
      # @example GitHub sources with explicit repos
      #   $ ptrk env set custom \
      #       --R2P2-ESP32 "myorg/R2P2-ESP32-fork" \
      #       --picoruby-esp32 "picoruby/picoruby-esp32" \
      #       --picoruby "picoruby/picoruby"
      #
      # @example Local development setup
      #   $ ptrk env set dev \
      #       --R2P2-ESP32 "path:../R2P2-ESP32" \
      #       --picoruby-esp32 "path:../picoruby-esp32" \
      #       --picoruby "path:../picoruby"
      #
      # @example Mixed sources with pinned commit
      #   $ ptrk env set stable \
      #       --R2P2-ESP32 "picoruby/R2P2-ESP32" \
      #       --picoruby-esp32 "path:../picoruby-esp32:a1b2c3d" \
      #       --picoruby "path:../picoruby:e4f5g6h"
      #
      # @return [void] Outputs success message and creates environment definition
      # @raise [RuntimeError] If only some options specified (all three required)
      # @raise [RuntimeError] If environment name is invalid (via validate_env_name!)
      #
      # @rbs (String) -> void
      desc "set ENV_NAME", "Create new environment with repository sources"
      option :"R2P2-ESP32", type: :string, desc: "org/repo or path:// for R2P2-ESP32"
      option :"picoruby-esp32", type: :string, desc: "org/repo or path:// for picoruby-esp32"
      option :picoruby, type: :string, desc: "org/repo or path:// for picoruby"
      def set(env_name)
        Picotorokko::Env.validate_env_name!(env_name)

        # Auto-fetch if no options specified
        if options[:"R2P2-ESP32"].nil? && options[:"picoruby-esp32"].nil? && options[:picoruby].nil?
          auto_fetch_environment(env_name)
          return
        end

        # All three options required if any is specified
        raise "Error: All three options required" if
          options[:"R2P2-ESP32"].nil? || options[:"picoruby-esp32"].nil? || options[:picoruby].nil?

        timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
        r2p2_info = process_source(options[:"R2P2-ESP32"], timestamp)
        esp32_info = process_source(options[:"picoruby-esp32"], timestamp)
        picoruby_info = process_source(options[:picoruby], timestamp)

        Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info,
                                         notes: "Environment created")
        puts "✓ Environment '#{env_name}' created"
      end

      no_commands do # rubocop:disable Metrics/BlockLength
        # Route source specification to appropriate handler (GitHub or local path)
        #
        # Detects source format type and delegates to specialized processors:
        # - Starts with "path:" → `process_path_source` (local repository)
        # - Otherwise → `process_github_source` (GitHub org/repo format)
        #
        # @param source_spec [String] Source specification (org/repo or path:...)
        # @param timestamp [String] Formatted timestamp (YYYYMMDD_HHMMSS)
        # @return [Hash{String => String}] Repository metadata with keys:
        #   - "source": Repository URL or path identifier
        #   - "commit": 7-character commit SHA
        #   - "timestamp": Formatted timestamp string
        #
        # @rbs (String, String) -> Hash[String, String]
        def process_source(source_spec, timestamp)
          if source_spec.start_with?("path:")
            process_path_source(source_spec, timestamp)
          else
            process_github_source(source_spec, timestamp)
          end
        end

        # Process GitHub org/repo format and fetch latest commit
        #
        # Converts "org/repo" to full GitHub URL and fetches remote HEAD commit.
        # Falls back to placeholder "abc1234" if fetch fails (graceful degradation).
        #
        # @param org_repo [String] GitHub organization/repository (e.g., "picoruby/picoruby")
        # @param timestamp [String] Formatted timestamp (YYYYMMDD_HHMMSS)
        # @return [Hash{String => String}] Repository metadata
        #   - "source": Full GitHub URL (https://github.com/org/repo.git)
        #   - "commit": 7-character commit SHA or "abc1234" if fetch failed
        #   - "timestamp": Provided timestamp string
        #
        # @rbs (String, String) -> Hash[String, String]
        def process_github_source(org_repo, timestamp)
          source_url = "https://github.com/#{org_repo}.git"
          commit = Picotorokko::Env.fetch_remote_commit(source_url) || "abc1234"
          { "source" => source_url, "commit" => commit, "timestamp" => timestamp }
        end

        # Process local path format (with or without pinned commit)
        #
        # Handles two path format variants:
        #   1. Pinned commit: "path:/local/dir:abc1234" (commit explicitly specified)
        #   2. Auto-detect: "path:/local/dir" (fetch current HEAD from repository)
        #
        # Format detection uses regex: `/^path:(.+):([a-f0-9]{7,})$/`
        # - Match → Extract path and commit from regex groups
        # - No match → Strip "path:" prefix and call `fetch_local_commit`
        #
        # @param path_spec [String] Path specification (path:/dir or path:/dir:SHA)
        # @param timestamp [String] Formatted timestamp (YYYYMMDD_HHMMSS)
        # @return [Hash{String => String}] Repository metadata
        #   - "source": Path identifier (preserved from input)
        #   - "commit": 7-character commit SHA (from spec or local Git)
        #   - "timestamp": Provided timestamp string
        #
        # @rbs (String, String) -> Hash[String, String]
        def process_path_source(path_spec, timestamp)
          if path_spec =~ /^path:(.+?):([a-f0-9]{7,})$/
            path = Regexp.last_match(1)
            commit = Regexp.last_match(2)
            source_key = "path:#{path}"
          else
            path = path_spec.sub(/^path:/, "")
            commit = fetch_local_commit(path)
            source_key = path_spec
          end
          { "source" => source_key, "commit" => commit, "timestamp" => timestamp }
        end

        # Fetch current HEAD commit SHA from local Git repository
        #
        # Executes `git rev-parse --short=7 HEAD` in the specified directory.
        # Validates that path exists before attempting Git command.
        #
        # @param path [String] Absolute or relative path to Git repository
        # @return [String] 7-character short commit SHA from repository HEAD
        # @raise [RuntimeError] If path does not exist
        #
        # @rbs (String) -> String
        def fetch_local_commit(path)
          raise "Error: Path does not exist" unless Dir.exist?(path)

          Dir.chdir(path) do
            commit = `git rev-parse --short=7 HEAD 2>/dev/null`.strip
            raise "Failed to get commit hash from git repository: #{path}" if commit.empty?

            commit
          end
        end

        # @rbs (String) -> void
        def auto_fetch_environment(env_name)
          timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
          repos_info = {}
          Picotorokko::Env::REPOS.each do |repo_name, repo_url|
            commit = Picotorokko::Env.fetch_remote_commit(repo_url, "HEAD") || "abc1234"
            repos_info[repo_name] = { "source" => repo_url, "commit" => commit, "timestamp" => timestamp }
          end
          Picotorokko::Env.set_environment(env_name, repos_info["R2P2-ESP32"],
                                           repos_info["picoruby-esp32"], repos_info["picoruby"])
          puts "✓ Environment '#{env_name}' created"
        end
      end

      # Remove and recreate environment definition with new timestamps
      # @rbs (String) -> void
      desc "reset ENV_NAME", "Remove and recreate environment definition"
      def reset(env_name)
        Picotorokko::Env.validate_env_name!(env_name)

        # Check if environment exists
        env_config = Picotorokko::Env.get_environment(env_name)
        raise "Error: Environment definition '#{env_name}' not found in .picoruby-env.yml" if env_config.nil?

        # Store original metadata before removal
        original_notes = env_config["notes"]

        # Remove and recreate with new timestamps
        r2p2_info = { "commit" => "placeholder", "timestamp" => Time.now.strftime("%Y%m%d_%H%M%S") }
        esp32_info = { "commit" => "placeholder", "timestamp" => Time.now.strftime("%Y%m%d_%H%M%S") }
        picoruby_info = { "commit" => "placeholder", "timestamp" => Time.now.strftime("%Y%m%d_%H%M%S") }

        notes = original_notes.to_s.empty? ? "Reset at #{Time.now}" : "#{original_notes} (reset at #{Time.now})"

        Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info, notes: notes)
        puts "✓ Environment definition '#{env_name}' has been reset"
      end

      # Export working changes from build environment to patch directory
      # @rbs (String) -> void
      desc "patch_export ENV_NAME", "Export changes from build environment to patch directory"
      def patch_export(env_name)
        env_config = Picotorokko::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        # Phase 4.1: Build path uses env_name directly
        build_path = Picotorokko::Env.get_build_path(env_name)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        puts "Exporting patches from: #{env_name}"

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          work_path = resolve_work_path(repo, build_path)
          next unless Dir.exist?(work_path)

          export_repo_changes(repo, work_path)
        end

        puts "\u2713 Patches exported"
      end

      # Apply stored patches to build environment
      # @rbs (String) -> void
      desc "patch_apply ENV_NAME", "Apply patches to build environment"
      def patch_apply(env_name)
        env_config = Picotorokko::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        # Phase 4.1: Build path uses env_name directly
        build_path = Picotorokko::Env.get_build_path(env_name)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        puts "  Applying patches..."

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          patch_repo_dir = File.join(Picotorokko::Env.patch_dir, repo)
          next unless Dir.exist?(patch_repo_dir)

          case repo
          when "R2P2-ESP32"
            work_path = File.join(build_path, "R2P2-ESP32")
          when "picoruby-esp32"
            work_path = File.join(build_path, "R2P2-ESP32", "components", "picoruby-esp32")
          when "picoruby"
            work_path = File.join(build_path, "R2P2-ESP32", "components", "picoruby-esp32", "picoruby")
          end

          next unless Dir.exist?(work_path)

          # Apply patches
          Picotorokko::PatchApplier.apply_patches_to_directory(patch_repo_dir, work_path)
          puts "    Applied #{repo}"
        end

        puts "  \u2713 Patches applied"
      end

      # Display differences between working changes and stored patches
      # @rbs (String) -> void
      desc "patch_diff ENV_NAME", "Display differences between working changes and stored patches"
      def patch_diff(env_name)
        env_config = Picotorokko::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        # Phase 4.1: Build path uses env_name directly
        build_path = Picotorokko::Env.get_build_path(env_name)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        puts "=== Patch Differences ===\n"

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          patch_repo_dir = File.join(Picotorokko::Env.patch_dir, repo)
          work_path = resolve_work_path(repo, build_path)

          show_repo_diff(repo, patch_repo_dir, work_path)
        end
      end

      # Fetch latest commit versions from GitHub and create environment definition
      # @rbs () -> void
      desc "latest", "Fetch latest commit versions and create environment definition"
      def latest
        puts "Fetching latest commits from GitHub..."
        repos_info = fetch_latest_repos

        # latest環境として保存
        env_name = "latest"
        puts "\nSaving as environment definition '#{env_name}' in .picoruby-env.yml..."

        Picotorokko::Env.set_environment(
          env_name,
          repos_info["R2P2-ESP32"],
          repos_info["picoruby-esp32"],
          repos_info["picoruby"],
          notes: "Auto-generated latest versions"
        )

        puts "✓ Environment definition '#{env_name}' created successfully in .picoruby-env.yml"
      end

      # Fetch latest commit versions from all default repositories
      #
      # This method fetches the current HEAD commit SHA and timestamp from all
      # repositories defined in `Picotorokko::Env::REPOS`. It performs temporary
      # shallow clones to extract commit metadata efficiently.
      #
      # **Process**:
      #   1. For each repository in REPOS hash:
      #      - Fetch remote HEAD commit SHA using `fetch_remote_commit`
      #      - Create temporary directory for shallow clone
      #      - Clone with `--depth 1` (single commit, no history)
      #      - Extract 7-character short commit hash via `git rev-parse`
      #      - Extract commit timestamp via `git show -s --format=%ci`
      #      - Clean up temporary directory
      #
      # **Why shallow clone?**
      #   Using `git clone --depth 1` significantly improves performance by:
      #   - Downloading only the latest commit (not entire history)
      #   - Reducing network transfer time and disk usage
      #   - Enabling timestamp extraction from commit metadata
      #   Note: `git ls-remote` provides commit SHA but not timestamp
      #
      # **Error handling**:
      #   - Raises error if `fetch_remote_commit` returns nil
      #   - Raises error if clone command fails (exit status non-zero)
      #   - Temporary directories cleaned up automatically by `Dir.mktmpdir`
      #
      # **Return value structure**:
      #   Hash with repository names as keys, each containing:
      #   - `"commit"`: 7-character short commit SHA (String)
      #   - `"timestamp"`: Formatted as "YYYYMMDD_HHMMSS" (String)
      #
      # **Performance notes**:
      #   - Network-bound operation (requires internet access)
      #   - Parallel execution not implemented (sequential by default)
      #   - Typical execution: 5-15 seconds for 3 repositories
      #
      # **Caching behavior**:
      #   This method does NOT cache results. Each call performs fresh network
      #   requests to ensure latest commit information.
      #
      # @return [Hash{String => Hash{String => String}}] Repository metadata
      #   Example: {
      #     "R2P2-ESP32" => {
      #       "commit" => "a1b2c3d",
      #       "timestamp" => "20250114_123045"
      #     },
      #     "picoruby-esp32" => { ... },
      #     "picoruby" => { ... }
      #   }
      #
      # @example Typical usage in 'latest' command
      #   repos_info = fetch_latest_repos
      #   Picotorokko::Env.set_environment("latest",
      #     repos_info["R2P2-ESP32"],
      #     repos_info["picoruby-esp32"],
      #     repos_info["picoruby"])
      #
      # @raise [RuntimeError] If fetch_remote_commit fails for any repository
      # @raise [RuntimeError] If git clone command fails (exit status non-zero)
      #
      # @rbs () -> Hash[String, Hash[String, String]]
      no_commands do
        def fetch_latest_repos
          require "tmpdir"

          repos_info = {}
          Picotorokko::Env::REPOS.each do |repo_name, repo_url|
            puts "  Checking #{repo_name}..."
            commit = Picotorokko::Env.fetch_remote_commit(repo_url, "HEAD")
            raise "Failed to fetch commit for #{repo_name}" if commit.nil?

            repos_info[repo_name] = fetch_repo_info(repo_name, repo_url)
          end

          repos_info
        end
      end

      private

      # @rbs (String, String) -> Hash[String, String]
      def fetch_repo_info(repo_name, repo_url)
        require "tmpdir"

        Dir.mktmpdir do |tmpdir|
          tmp_repo = File.join(tmpdir, repo_name)
          puts "    Cloning to get timestamp..."

          # Shallow clone（高速化のため）
          cmd = "git clone --depth 1 #{Shellwords.escape(repo_url)} #{Shellwords.escape(tmp_repo)} 2>/dev/null"
          unless system(cmd)
            raise "Command failed (exit status: #{$CHILD_STATUS.exitstatus}): #{cmd.sub(" 2>/dev/null", "")}"
          end

          # コミットハッシュとタイムスタンプ取得
          Dir.chdir(tmp_repo) do
            short_hash = `git rev-parse --short=7 HEAD`.strip
            raise "Failed to get commit hash from #{repo_name}" if short_hash.empty?

            timestamp_str = `git show -s --format=%ci HEAD`.strip
            raise "Failed to get timestamp from #{repo_name}" if timestamp_str.empty?

            timestamp = Time.parse(timestamp_str).strftime("%Y%m%d_%H%M%S")

            puts "    ✓ #{repo_name}: #{short_hash} (#{timestamp})"

            {
              "commit" => short_hash,
              "timestamp" => timestamp
            }
          end
        end
      end

      # @rbs (String, Hash[String, Hash[String, String]]) -> void
      def setup_build_environment(env_name, repos_info)
        build_path = Picotorokko::Env.get_build_path(env_name)

        # Create build directory if it doesn't exist
        FileUtils.mkdir_p(build_path)

        # Track cloned repos for rollback on failure
        cloned_repos = []

        begin
          # Clone R2P2-ESP32 WITH SUBMODULES to cache first
          r2p2_name = "R2P2-ESP32"
          r2p2_url = Picotorokko::Env::REPOS[r2p2_name]
          r2p2_info = repos_info[r2p2_name]
          r2p2_commit = r2p2_info["commit"]
          r2p2_timestamp = r2p2_info["timestamp"]

          puts "  Cloning #{r2p2_name} WITH SUBMODULES..."
          cache_path = Picotorokko::Env.cache_clone_with_submodules(r2p2_name, r2p2_url, r2p2_commit, r2p2_timestamp)
          target_path = File.join(build_path, r2p2_name)
          FileUtils.rm_rf(target_path)
          FileUtils.cp_r(cache_path, target_path)
          cloned_repos << target_path
          puts "    ✓ #{r2p2_name} with submodules: #{r2p2_commit}"

          # Clone other repositories normally
          ["picoruby-esp32", "picoruby"].each do |repo_name|
            repo_url = Picotorokko::Env::REPOS[repo_name]
            puts "  Cloning #{repo_name}..."
            clone_and_checkout_repo(repo_name, repo_url, build_path, repos_info)
            cloned_repos << File.join(build_path, repo_name)
          end

          # Copy storage/home/ to R2P2-ESP32 build directory
          storage_src = File.join(Picotorokko::Env.project_root, "storage", "home")
          if Dir.exist?(storage_src)
            r2p2_path = File.join(build_path, "R2P2-ESP32")
            storage_dst = File.join(r2p2_path, "storage", "home")
            FileUtils.mkdir_p(File.dirname(storage_dst))
            FileUtils.rm_rf(storage_dst)
            FileUtils.cp_r(storage_src, storage_dst)
            puts "  ✓ Copied storage/home/ to R2P2-ESP32"
          end
        rescue StandardError
          # Rollback: remove all cloned repos on failure
          cloned_repos.each { |path| FileUtils.rm_rf(path) }
          raise
        end
      end

      # @rbs (String, String, String, Hash[String, Hash[String, String]]) -> void
      def clone_and_checkout_repo(repo_name, repo_url, build_path, repos_info)
        target_path = File.join(build_path, repo_name)
        commit_info = repos_info[repo_name]
        commit_sha = commit_info["commit"]

        # Skip if already cloned AND valid (has .git directory)
        return if Dir.exist?(target_path) && File.directory?(File.join(target_path, ".git"))

        # Remove incomplete clone if exists
        FileUtils.rm_rf(target_path)

        # Clone repository - check return value
        clone_cmd = "git clone --filter=blob:none #{Shellwords.escape(repo_url)} #{Shellwords.escape(target_path)}"
        raise "Clone failed: #{repo_name} from #{repo_url}" unless system(clone_cmd)

        # Checkout specific commit - check return value
        checkout_cmd = "cd #{Shellwords.escape(target_path)} && git checkout #{Shellwords.escape(commit_sha)}"
        raise "Checkout failed: #{repo_name} to commit #{commit_sha}" unless system(checkout_cmd)

        puts "    ✓ #{repo_name}: #{commit_sha}"
      end

      # @rbs (String) -> void
      def show_env_not_found(env_name)
        puts "Error: Environment '#{env_name}' not found in .picoruby-env.yml"
      end

      # @rbs (String, Hash[String, untyped]) -> void
      def show_env_details(env_name, env_config)
        puts "Environment: #{env_name}"
        display_repo_versions(env_config)
        display_metadata(env_config)
      end

      # @rbs (Hash[String, untyped]) -> void
      def display_repo_versions(env_config)
        puts "\nRepo versions:"
        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          info = env_config[repo] || {}
          commit = info["commit"] || "N/A"
          timestamp = info["timestamp"] || "N/A"
          puts "  #{repo}: #{commit} (#{timestamp})"
        end
      end

      # @rbs (Hash[String, untyped]) -> void
      def display_metadata(env_config)
        puts "\nCreated: #{env_config["created_at"]}"
        puts "Notes: #{env_config["notes"]}" unless env_config["notes"].to_s.empty?
      end

      # @rbs (String, String) -> (String | nil)
      def resolve_work_path(repo, build_path)
        case repo
        when "R2P2-ESP32"
          File.join(build_path, "R2P2-ESP32")
        when "picoruby-esp32"
          File.join(build_path, "R2P2-ESP32", "components", "picoruby-esp32")
        when "picoruby"
          File.join(build_path, "R2P2-ESP32", "components", "picoruby-esp32", "picoruby")
        end
      end

      # @rbs (String, String) -> void
      def export_repo_changes(repo, work_path)
        Dir.chdir(work_path) do
          changed_files = `git diff --name-only 2>/dev/null`.split("\n")

          if changed_files.empty?
            puts "  #{repo}: (no changes)"
            return
          end

          puts "  #{repo}: #{changed_files.size} file(s)"

          changed_files.each do |file|
            patch_dir = File.join(Picotorokko::Env.patch_dir, repo)
            FileUtils.mkdir_p(patch_dir)

            file_dir = File.dirname(file)
            FileUtils.mkdir_p(File.join(patch_dir, file_dir)) unless file_dir == "."

            diff_output = `git diff #{Shellwords.escape(file)}`
            patch_file = File.join(patch_dir, file)

            if diff_output.strip.empty?
              FileUtils.cp(file, patch_file)
            else
              File.write(patch_file, diff_output)
            end

            puts "    Exported: #{repo}/#{file}"
          end
        end
      end

      # @rbs (String, String, (String | nil)) -> void
      def show_repo_diff(repo, patch_repo_dir, work_path)
        puts "#{repo}:"

        if Dir.exist?(work_path)
          Dir.chdir(work_path) do
            changed = `git diff --name-only 2>/dev/null`.split("\n")
            if changed.empty?
              puts "  (no working changes)"
            else
              puts "  Working changes: #{changed.join(", ")}"
            end
          end
        end

        if Dir.exist?(patch_repo_dir)
          patch_files = Dir.glob("#{patch_repo_dir}/**/*").reject do |p|
            File.directory?(p) || File.basename(p) == ".keep"
          end
          if patch_files.empty?
            puts "  (no stored patches)"
          else
            puts "  Stored patches: #{patch_files.map { |p| p.sub("#{patch_repo_dir}/", "") }.join(", ")}"
          end
        else
          puts "  (no patches directory)"
        end

        puts
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
