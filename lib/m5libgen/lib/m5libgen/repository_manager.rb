# frozen_string_literal: true

require "fileutils"
require "open3"

module M5LibGen
  # Manages M5Unified repository operations (clone, update, info)
  class RepositoryManager
    class CloneError < StandardError; end
    class UpdateError < StandardError; end
    class InfoError < StandardError; end

    attr_reader :path

    def initialize(path)
      @path = path
    end

    # Clone repository from remote URL
    def clone(url:, branch: "master")
      # Remove existing directory if present
      FileUtils.rm_rf(@path)

      # Create parent directory
      FileUtils.mkdir_p(File.dirname(@path))

      # Clone repository
      cmd = "git clone --branch #{branch} #{url} #{@path}"
      _, stderr, status = Open3.capture3(cmd)

      raise CloneError, "Failed to clone repository: #{stderr}" unless status.success?
    end

    # Update existing repository with git pull
    def update
      raise UpdateError, "Repository does not exist at #{@path}" unless Dir.exist?(@path)

      cmd = "cd #{@path} && git pull"
      _, stderr, status = Open3.capture3(cmd)

      raise UpdateError, "Failed to update repository: #{stderr}" unless status.success?
    end

    # Get repository information (commit hash and branch)
    def info
      raise InfoError, "Repository does not exist at #{@path}" unless Dir.exist?(@path)

      # Get current commit hash
      cmd_commit = "cd #{@path} && git rev-parse HEAD"
      commit, = Open3.capture3(cmd_commit)

      # Get current branch
      cmd_branch = "cd #{@path} && git rev-parse --abbrev-ref HEAD"
      branch, = Open3.capture3(cmd_branch)

      {
        commit: commit.strip,
        branch: branch.strip
      }
    end
  end
end
