require "fileutils"

module Picotorokko
  # パッチ適用ロジック（複数のコマンドで再利用）
  module PatchApplier
    # パッチディレクトリ内のファイルをワーキングディレクトリに適用
    # patch_repo_dir: パッチを含むディレクトリ（patch/repo 配下など）
    # work_path: ワーキングディレクトリのパス（build/ 配下など）
    # @rbs (String, String) -> void
    def self.apply_patches_to_directory(patch_repo_dir, work_path)
      Dir.glob("#{patch_repo_dir}/**/*").each do |patch_file|
        next if File.directory?(patch_file)
        next if File.basename(patch_file) == ".keep"

        rel_path = patch_file.sub("#{patch_repo_dir}/", "")
        dest_file = File.join(work_path, rel_path)

        FileUtils.mkdir_p(File.dirname(dest_file))
        FileUtils.cp(patch_file, dest_file)
      end
    end
  end
end
