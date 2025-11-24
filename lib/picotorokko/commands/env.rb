require "English"
require "fileutils"
require "json"
require "shellwords"
require "thor"
require "picotorokko/patch_applier"
require "rbs"

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

      # Get or set current environment
      # @rbs (String?) -> void
      desc "current [ENV_NAME]", "Get or set current environment"
      def current(env_name = nil)
        if env_name
          # Set current environment
          env_config = Picotorokko::Env.get_environment(env_name)
          raise "Environment '#{env_name}' not found" if env_config.nil?

          Picotorokko::Env.set_current_env(env_name)
          sync_project_rubocop_yml(env_name)
          puts "✓ Current environment set to: #{env_name}"
        else
          # Show current environment
          current_env = Picotorokko::Env.get_current_env
          if current_env
            puts "Current environment: #{current_env}"
          else
            puts "No current environment set."
            puts "Use 'ptrk env current ENV_NAME' to set one."
          end
        end
      end

      # Display environment definition from .picoruby-env.yml
      # @rbs (String?) -> void
      desc "show [ENV_NAME]", "Display environment definition from .picoruby-env.yml"
      def show(env_name = nil)
        env_name ||= Picotorokko::Env.get_current_env
        raise "No environment specified and no current environment set" if env_name.nil?

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
      # @rbs (String?) -> void
      desc "set [ENV_NAME]", "Create new environment with repository sources"
      option :"R2P2-ESP32", type: :string, desc: "org/repo or path:// for R2P2-ESP32"
      option :"picoruby-esp32", type: :string, desc: "org/repo or path:// for picoruby-esp32"
      option :picoruby, type: :string, desc: "org/repo or path:// for picoruby"
      option :latest, type: :boolean, desc: "Use timestamp for env name and fetch latest"
      def set(env_name = nil)
        # Handle --latest option: generate timestamp-based env_name
        if options[:latest]
          set_latest
          return
        end

        raise "Error: ENV_NAME is required" if env_name.nil?

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
        # Create environment with timestamp-based name and fetch latest repos
        # @rbs () -> void
        def set_latest
          puts "Fetching latest commits from GitHub..."
          repos_info = fetch_latest_repos

          # Generate env_name from current timestamp
          env_name = Time.now.strftime("%Y%m%d_%H%M%S")
          puts "\nSaving as environment definition '#{env_name}' in .picoruby-env.yml..."

          Picotorokko::Env.set_environment(
            env_name,
            repos_info["R2P2-ESP32"],
            repos_info["picoruby-esp32"],
            repos_info["picoruby"],
            notes: "Auto-generated latest versions"
          )

          puts "✓ Environment definition '#{env_name}' created successfully in .picoruby-env.yml"

          # Clone R2P2-ESP32 to .ptrk_env/{env_name}/
          clone_env_repository(env_name, repos_info)

          # Auto-set current if not already set
          return unless Picotorokko::Env.get_current_env.nil?

          Picotorokko::Env.set_current_env(env_name)
          sync_project_rubocop_yml(env_name)
          puts "✓ Current environment set to: #{env_name}"
        end

        # Clone R2P2-ESP32 repository to .ptrk_env/{env_name}/
        # @rbs (String, Hash[String, Hash[String, String]]) -> void
        def clone_env_repository(env_name, repos_info)
          env_path = File.join(Picotorokko::Env::ENV_DIR, env_name)
          r2p2_url = Picotorokko::Env::REPOS["R2P2-ESP32"]
          r2p2_commit = repos_info["R2P2-ESP32"]["commit"]

          puts "\nCloning R2P2-ESP32 to #{env_path}..."

          # Clone with --filter=blob:none for partial clone (faster)
          clone_cmd = "git clone --filter=blob:none #{Shellwords.escape(r2p2_url)} " \
                      "#{Shellwords.escape(env_path)} 2>/dev/null"
          raise "Clone failed: R2P2-ESP32 from #{r2p2_url}" unless system(clone_cmd)

          # Checkout to specified commit
          checkout_cmd = "cd #{Shellwords.escape(env_path)} && git checkout #{Shellwords.escape(r2p2_commit)}"
          raise "Checkout failed: R2P2-ESP32 to commit #{r2p2_commit}" unless system(checkout_cmd)

          # Initialize and fetch all nested submodules recursively
          submodule_cmd = "cd #{Shellwords.escape(env_path)} && git submodule update --init --recursive --jobs 4"
          raise "Submodule update failed for R2P2-ESP32" unless system(submodule_cmd)

          # Checkout picoruby-esp32 to specified commit
          esp32_commit = repos_info["picoruby-esp32"]["commit"]
          esp32_path = File.join(env_path, "components", "picoruby-esp32")
          esp32_checkout = "cd #{Shellwords.escape(esp32_path)} && git checkout #{Shellwords.escape(esp32_commit)}"
          raise "Checkout failed: picoruby-esp32 to commit #{esp32_commit}" unless system(esp32_checkout)

          # Checkout picoruby (nested submodule) to specified commit
          picoruby_commit = repos_info["picoruby"]["commit"]
          picoruby_path = File.join(esp32_path, "picoruby")
          picoruby_checkout = "cd #{Shellwords.escape(picoruby_path)} && git checkout #{Shellwords.escape(picoruby_commit)}"
          raise "Checkout failed: picoruby to commit #{picoruby_commit}" unless system(picoruby_checkout)

          # Stage submodule changes
          git_add = "cd #{Shellwords.escape(env_path)} && git add components/picoruby-esp32"
          raise "Failed to stage submodule changes" unless system(git_add)

          # Amend commit with env-name (skip gpg signing to avoid signing server issues)
          git_amend = "cd #{Shellwords.escape(env_path)} && " \
                      "git commit --amend --no-gpg-sign -m #{Shellwords.escape("ptrk env: #{env_name}")}"
          raise "Failed to amend commit" unless system(git_amend)

          # Disable push on all repos
          disable_push = "git remote set-url --push origin no_push"
          system("cd #{Shellwords.escape(env_path)} && #{disable_push}")
          system("cd #{Shellwords.escape(esp32_path)} && #{disable_push}")
          system("cd #{Shellwords.escape(picoruby_path)} && #{disable_push}")

          puts "  ✓ R2P2-ESP32 cloned and checked out to #{r2p2_commit}"
          puts "  ✓ picoruby-esp32 checked out to #{esp32_commit}"
          puts "  ✓ picoruby checked out to #{picoruby_commit}"
          puts "  ✓ Push disabled on all repositories"

          # Generate RuboCop configuration
          generate_rubocop_config(env_name, env_path)
        end

        # Generate RuboCop configuration with PicoRuby method database
        # @rbs (String, String) -> void
        def generate_rubocop_config(_env_name, env_path)
          rubocop_data_path = File.join(env_path, "rubocop", "data")
          FileUtils.mkdir_p(rubocop_data_path)

          # Find RBS files in picoruby mrbgems
          picoruby_path = File.join(env_path, "components", "picoruby-esp32", "picoruby")
          rbs_pattern = File.join(picoruby_path, "mrbgems", "picoruby-*", "sig", "*.rbs")

          supported_methods = {}
          rbs_files = Dir.glob(rbs_pattern)

          rbs_files.each do |rbs_file|
            parse_rbs_file(rbs_file, supported_methods)
          end

          # Generate supported methods JSON
          supported_json = File.join(rubocop_data_path, "picoruby_supported_methods.json")
          File.write(supported_json, JSON.pretty_generate(supported_methods))

          # Generate unsupported methods JSON (CRuby methods not in PicoRuby)
          unsupported_methods = calculate_unsupported_methods(supported_methods)
          unsupported_json = File.join(rubocop_data_path, "picoruby_unsupported_methods.json")
          File.write(unsupported_json, JSON.pretty_generate(unsupported_methods))

          # Generate .rubocop-picoruby.yml
          rubocop_yml_path = File.join(env_path, "rubocop", ".rubocop-picoruby.yml")
          generate_rubocop_yml(rubocop_yml_path, rubocop_data_path)

          puts "  ✓ RuboCop configuration generated in #{rubocop_data_path}"
        end

        # Generate .rubocop-picoruby.yml configuration file
        # @rbs (String, String) -> void
        def generate_rubocop_yml(yml_path, data_path)
          content = <<~YAML
            # PicoRuby-specific RuboCop configuration
            # Auto-generated by ptrk env set --latest

            require:
              - rubocop-performance

            AllCops:
              TargetRubyVersion: 3.2
              NewCops: enable

            # Custom cop configuration for PicoRuby method detection
            # Data files location: #{data_path}
          YAML
          File.write(yml_path, content)
        end

        # Sync project .rubocop.yml with current environment
        # @rbs (String) -> void
        def sync_project_rubocop_yml(env_name)
          env_rubocop_path = File.join(Picotorokko::Env::ENV_DIR, env_name, "rubocop", ".rubocop-picoruby.yml")
          return unless File.exist?(env_rubocop_path)

          project_rubocop = ".rubocop.yml"
          content = <<~YAML
            # Project RuboCop configuration
            # Linked to current PicoRuby environment: #{env_name}

            inherit_from:
              - #{env_rubocop_path}
          YAML
          File.write(project_rubocop, content)
        end

        # Parse RBS file and extract method definitions
        # @rbs (String, Hash[String, Hash[String, Array[String]]]) -> void
        def parse_rbs_file(rbs_file, methods_hash)
          content = File.read(rbs_file, encoding: "UTF-8")
          sig = RBS::Parser.parse_signature(content)

          sig[2].each do |dec|
            case dec
            when RBS::AST::Declarations::Class, RBS::AST::Declarations::Module
              class_name = dec.name.name.to_s
              methods_hash[class_name] ||= { "instance" => [], "singleton" => [] }

              dec.members.each do |member|
                case member
                when RBS::AST::Members::MethodDefinition
                  # Skip methods with @ignore annotation
                  next if member.comment&.string&.include?("@ignore")

                  method_name = member.name.to_s
                  kind = member.kind == :singleton ? "singleton" : "instance"
                  unless methods_hash[class_name][kind].include?(method_name)
                    methods_hash[class_name][kind] << method_name
                  end
                end
              end

              # Sort methods alphabetically
              methods_hash[class_name]["instance"].sort!
              methods_hash[class_name]["singleton"].sort!
            end
          end
        rescue RBS::ParsingError => e
          warn "Warning: Failed to parse #{rbs_file}: #{e.message}"
        end

        # Calculate unsupported methods (CRuby methods not in PicoRuby)
        # @rbs (Hash[String, Hash[String, Array[String]]]) -> Hash[String, Hash[String, Array[String]]]
        def calculate_unsupported_methods(supported_methods)
          core_classes = [Array, String, Hash, Integer, Float, Symbol, Regexp, Range, Numeric]
          unsupported = {}

          core_classes.each do |klass|
            class_name = klass.name
            next unless supported_methods.key?(class_name)

            cruby_instance = klass.instance_methods(false).map(&:to_s)
            cruby_singleton = klass.methods(false).map(&:to_s)

            picoruby_instance = supported_methods[class_name]["instance"] || []
            picoruby_singleton = supported_methods[class_name]["singleton"] || []

            unsupported_instance = (cruby_instance - picoruby_instance).sort
            unsupported_singleton = (cruby_singleton - picoruby_singleton).sort

            next if unsupported_instance.empty? && unsupported_singleton.empty?

            unsupported[class_name] = {
              "instance" => unsupported_instance,
              "singleton" => unsupported_singleton
            }
          end

          unsupported
        end

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
      desc "reset [ENV_NAME]", "Remove and recreate environment definition"
      def reset(env_name = nil)
        env_name ||= Picotorokko::Env.get_current_env
        raise "No environment specified and no current environment set" if env_name.nil?

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
      desc "patch_export [ENV_NAME]", "Export changes from build environment to patch directory"
      def patch_export(env_name = nil)
        env_name ||= Picotorokko::Env.get_current_env
        raise "No environment specified and no current environment set" if env_name.nil?

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

      # Display differences between working changes and stored patches
      # @rbs (String) -> void
      desc "patch_diff [ENV_NAME]", "Display differences between working changes and stored patches"
      def patch_diff(env_name = nil)
        env_name ||= Picotorokko::Env.get_current_env
        raise "No environment specified and no current environment set" if env_name.nil?

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
      def setup_build_environment(env_name, _repos_info)
        env_path = File.join(Picotorokko::Env::ENV_DIR, env_name)
        build_path = Picotorokko::Env.get_build_path(env_name)

        # Verify .ptrk_env/{env_name}/ exists
        raise "Error: Environment directory not found: #{env_path}" unless Dir.exist?(env_path)

        # Copy entire .ptrk_env/{env_name}/ to .ptrk_build/{env_name}/
        puts "  Copying environment to build directory..."
        FileUtils.mkdir_p(File.dirname(build_path))
        FileUtils.rm_rf(build_path)
        FileUtils.cp_r(env_path, build_path)
        puts "  ✓ Environment copied to #{build_path}"

        # Copy storage/home/ to R2P2-ESP32 for build
        storage_src = File.join(Picotorokko::Env.project_root, "storage", "home")
        if Dir.exist?(storage_src)
          r2p2_path = File.join(build_path, "R2P2-ESP32")
          storage_dst = File.join(r2p2_path, "storage", "home")
          FileUtils.mkdir_p(File.dirname(storage_dst))
          FileUtils.rm_rf(storage_dst)
          FileUtils.cp_r(storage_src, storage_dst)
          puts "  ✓ Copied storage/home/ to R2P2-ESP32"
        end

        # Copy mrbgems/ to nested picoruby path for build
        mrbgems_src = File.join(Picotorokko::Env.project_root, "mrbgems")
        if Dir.exist?(mrbgems_src)
          r2p2_path = File.join(build_path, "R2P2-ESP32")
          mrbgems_dst = File.join(r2p2_path, "components", "picoruby-esp32", "picoruby", "mrbgems")
          FileUtils.mkdir_p(File.dirname(mrbgems_dst))
          FileUtils.rm_rf(mrbgems_dst)
          FileUtils.cp_r(mrbgems_src, mrbgems_dst)
          puts "  ✓ Copied mrbgems/ to nested picoruby path"
        end

        # Apply patches
        apply_patches_to_build(build_path)
      end

      # Apply stored patches to build environment
      # @rbs (String) -> void
      def apply_patches_to_build(build_path)
        puts "  Applying patches..."

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          case repo
          when "R2P2-ESP32"
            work_path = File.join(build_path, "R2P2-ESP32")
          when "picoruby-esp32"
            work_path = File.join(build_path, "R2P2-ESP32", "components", "picoruby-esp32")
          when "picoruby"
            work_path = File.join(build_path, "R2P2-ESP32", "components", "picoruby-esp32", "picoruby")
          end

          next unless Dir.exist?(work_path)

          # Apply patches from .ptrk_env/patch/{repo}/
          patch_repo_dir = File.join(Picotorokko::Env.patch_dir, repo)
          if Dir.exist?(patch_repo_dir)
            Picotorokko::PatchApplier.apply_patches_to_directory(patch_repo_dir, work_path)
            puts "    Applied #{repo} (from .ptrk_env/patch)"
          end

          # Apply patches from project root patch/{repo}/
          project_patch_dir = File.join(Picotorokko::Env.project_root, "patch", repo)
          if Dir.exist?(project_patch_dir)
            Picotorokko::PatchApplier.apply_patches_to_directory(project_patch_dir, work_path)
            puts "    Applied #{repo} (from project patch)"
          end
        end

        puts "  ✓ Patches applied"
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
          # Skip if not a git repository
          unless Dir.exist?(".git")
            puts "  #{repo}: (not a git repository)"
            return
          end

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

            diff_output = `git diff -- #{Shellwords.escape(file)}`
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
