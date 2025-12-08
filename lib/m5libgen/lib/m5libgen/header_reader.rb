# frozen_string_literal: true

module M5LibGen
  # Reads and lists C++ header files from a repository
  class HeaderReader
    class FileNotFoundError < StandardError; end

    attr_reader :repo_path

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
      raise FileNotFoundError, "File does not exist: #{file_path}" unless File.exist?(file_path)

      File.read(file_path)
    end
  end
end
