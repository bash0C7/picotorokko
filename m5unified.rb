#!/usr/bin/env ruby

require "fileutils"
require "open3"
require "pathname"

# M5Unified repository manager
class M5UnifiedRepositoryManager
  def initialize(path)
    @path = path
  end

  attr_reader :path

  # Clone M5Unified repository from remote URL
  def clone(url:, branch: "master")
    # Remove existing directory if present
    FileUtils.rm_rf(@path)

    # Create parent directory
    FileUtils.mkdir_p(File.dirname(@path))

    # Clone repository
    cmd = "git clone --branch #{branch} #{url} #{@path}"
    _, stderr, status = Open3.capture3(cmd)

    raise "Failed to clone repository: #{stderr}" unless status.success?
  end

  # Update existing repository with git pull
  def update
    raise "Repository does not exist at #{@path}" unless Dir.exist?(@path)

    cmd = "cd #{@path} && git pull"
    _, stderr, status = Open3.capture3(cmd)

    raise "Failed to update repository: #{stderr}" unless status.success?
  end

  # Get repository information
  def info
    raise "Repository does not exist at #{@path}" unless Dir.exist?(@path)

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

# C++ Header file reader
class HeaderFileReader
  def initialize(repo_path)
    @repo_path = repo_path
  end

  # List all .h files in src/ and include/ directories
  def list_headers
    headers = []
    search_dirs = ["src", "include"]

    search_dirs.each do |dir|
      dir_path = File.join(@repo_path, dir)
      next unless Dir.exist?(dir_path)

      Dir.glob(File.join(dir_path, "**", "*.h")).each do |file|
        headers << file
      end
    end

    headers.sort
  end

  # Read header file content
  def read_file(file_path)
    raise "File does not exist: #{file_path}" unless File.exist?(file_path)

    File.read(file_path)
  end
end
