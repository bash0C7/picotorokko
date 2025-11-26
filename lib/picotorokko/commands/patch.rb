# rbs_inline: enabled

require "shellwords"
require "thor"

module Picotorokko
  module Commands
    # Patch management commands
    # Provides export, diff, and list operations for patches
    # @rbs < Thor
    class Patch < Thor
      # @rbs () -> bool
      def self.exit_on_failure?
        true
      end

      # List all patch files
      # @rbs () -> void
      desc "list", "List all patch files"
      def list
        patch_dir = Picotorokko::Env.patch_dir

        unless Dir.exist?(patch_dir)
          puts "No patches found"
          return
        end

        patch_files = Dir.glob("#{patch_dir}/**/*").reject do |p|
          File.directory?(p) || File.basename(p) == ".keep"
        end

        if patch_files.empty?
          puts "No patches found"
          return
        end

        puts "Patches:"
        patch_files.sort.each do |file|
          relative_path = file.sub("#{patch_dir}/", "")
          puts "  #{relative_path}"
        end
      end

      # Display differences between working changes and stored patches
      # @rbs (String?) -> void
      desc "diff [ENV_NAME]", "Display differences between working changes and stored patches"
      def diff(env_name = nil)
        env_name ||= Picotorokko::Env.get_current_env
        raise "No environment specified and no current environment set" if env_name.nil?

        env_config = Picotorokko::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        build_path = Picotorokko::Env.get_build_path(env_name)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        puts "=== Patch Differences ==="
        puts "Environment: #{env_name}\n"

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          patch_repo_dir = File.join(Picotorokko::Env.patch_dir, repo)
          work_path = resolve_work_path(repo, build_path)

          show_repo_diff(repo, patch_repo_dir, work_path)
        end
      end

      # Export changes from build environment to patch directory
      # @rbs (String?) -> void
      desc "export [ENV_NAME]", "Export changes from build environment to patch directory"
      def export(env_name = nil)
        env_name ||= Picotorokko::Env.get_current_env
        raise "No environment specified and no current environment set" if env_name.nil?

        env_config = Picotorokko::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

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

      private

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
          # Skip if not a git repository (check both file and directory for submodules)
          unless File.exist?(".git")
            puts "  #{repo}: (not a git repository)"
            return
          end

          changed_files = `git diff --name-only 2>/dev/null`.split("\n")

          # Remove and recreate patch directory for this repo
          patch_dir = File.join(Picotorokko::Env.patch_dir, repo)
          FileUtils.rm_rf(patch_dir) if Dir.exist?(patch_dir)

          if changed_files.empty?
            puts "  #{repo}: (no changes)"
            return
          end

          puts "  #{repo}: #{changed_files.size} file(s)"
          FileUtils.mkdir_p(patch_dir)

          changed_files.each do |file|
            source_file = File.join(work_path, file)

            # Skip directories (git reports them for submodule changes)
            next if File.directory?(source_file)

            file_dir = File.dirname(file)
            FileUtils.mkdir_p(File.join(patch_dir, file_dir)) unless file_dir == "."

            dest_file = File.join(patch_dir, file)
            FileUtils.cp(source_file, dest_file)

            puts "    Exported: #{repo}/#{file}"
          end
        end
      end

      # @rbs (String, String, (String | nil)) -> void
      def show_repo_diff(repo, patch_repo_dir, work_path)
        puts "#{repo}:"

        if work_path && Dir.exist?(work_path)
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

        puts ""
      end
    end
  end
end
