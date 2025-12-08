# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"

# Test M5LibGen::RepositoryManager
class RepositoryManagerTest < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir("m5libgen_test")
    @repo_path = File.join(@tmpdir, "test_repo")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_initialize
    manager = M5LibGen::RepositoryManager.new(@repo_path)
    assert_equal @repo_path, manager.path
  end

  def test_clone_repository
    omit "Requires git and network access"
    manager = M5LibGen::RepositoryManager.new(@repo_path)
    # Using a small test repository
    manager.clone(url: "https://github.com/bash0C7/picotorokko.git", branch: "main")
    assert Dir.exist?(@repo_path)
    assert Dir.exist?(File.join(@repo_path, ".git"))
  end

  def test_clone_removes_existing_directory
    FileUtils.mkdir_p(@repo_path)
    File.write(File.join(@repo_path, "dummy.txt"), "test")

    omit "Requires git and network access"
    manager = M5LibGen::RepositoryManager.new(@repo_path)
    manager.clone(url: "https://github.com/bash0C7/picotorokko.git", branch: "main")

    assert Dir.exist?(@repo_path)
    refute File.exist?(File.join(@repo_path, "dummy.txt"))
  end

  def test_clone_with_invalid_url_raises_error
    manager = M5LibGen::RepositoryManager.new(@repo_path)
    assert_raise(M5LibGen::RepositoryManager::CloneError) do
      manager.clone(url: "https://invalid-url-that-does-not-exist.example.com/repo.git")
    end
  end

  def test_update_raises_error_if_repo_does_not_exist
    manager = M5LibGen::RepositoryManager.new(@repo_path)
    assert_raise(M5LibGen::RepositoryManager::UpdateError) do
      manager.update
    end
  end

  def test_info_returns_commit_and_branch
    omit "Requires git repository"
    # This test requires an actual git repository
    manager = M5LibGen::RepositoryManager.new(@repo_path)
    manager.clone(url: "https://github.com/bash0C7/picotorokko.git", branch: "main")

    info = manager.info
    assert_kind_of String, info[:commit]
    assert_kind_of String, info[:branch]
    assert_match(/\A[0-9a-f]{40}\z/, info[:commit])
    assert_equal "main", info[:branch]
  end

  def test_info_raises_error_if_repo_does_not_exist
    manager = M5LibGen::RepositoryManager.new(@repo_path)
    assert_raise(M5LibGen::RepositoryManager::InfoError) do
      manager.info
    end
  end
end
