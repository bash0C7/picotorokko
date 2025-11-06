
require 'thor'
require 'fileutils'

module Pra
  module Commands
    # CI/CD設定管理コマンド群
    class Ci < Thor
      def self.exit_on_failure?
        true
      end

      desc 'setup', 'Setup GitHub Actions workflow for ESP32 firmware builds'
      def setup
        puts "Setting up GitHub Actions workflow for CI/CD..."

        # .github/workflows/ ディレクトリを作成
        workflows_dir = File.join(Dir.pwd, '.github', 'workflows')
        FileUtils.mkdir_p(workflows_dir)
        puts "✓ Created directory: .github/workflows/"

        # テンプレートファイルのパス
        gem_root = File.expand_path('../../../', __dir__)
        template_file = File.join(gem_root, 'docs', 'github-actions', 'esp32-build.yml')

        unless File.exist?(template_file)
          raise "Error: Template file not found at #{template_file}"
        end

        # コピー先のパス
        target_file = File.join(workflows_dir, 'esp32-build.yml')

        # 既存ファイルがある場合の確認
        if File.exist?(target_file)
          print "⚠ File already exists: .github/workflows/esp32-build.yml\n"
          print "  Overwrite? (y/N): "
          response = $stdin.gets.chomp.downcase

          unless response == 'y' || response == 'yes'
            puts "✗ Cancelled. No changes made."
            return
          end
        end

        # ファイルをコピー
        FileUtils.cp(template_file, target_file)
        puts "✓ Copied workflow file: .github/workflows/esp32-build.yml"

        puts "\n=== Setup Complete ==="
        puts "Next steps:"
        puts "  1. Edit .picoruby-env.yml to define your environment"
        puts "  2. Commit the workflow file:"
        puts "     git add .github/workflows/esp32-build.yml"
        puts "     git commit -m \"Add CI/CD workflow for ESP32 builds\""
        puts "  3. Push to GitHub and check the Actions tab"
        puts "\nFor more information, see: docs/CI_CD_GUIDE.md"
      end
    end
  end
end
