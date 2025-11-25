require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/picotorokko/commands/new"
require_relative "../../lib/picotorokko/commands/env"

class ScenarioPhase5E2ETest < PicotorokkoTestCase
  # Phase 5 end-to-end verification シナリオテスト
  # Codify the manual e2e verification performed in Phase 5

  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  # 標準出力をキャプチャするヘルパー
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  sub_test_case "Scenario: Phase 5 e2e verification" do
    test "Step 2: ptrk new creates project structure" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # ptrk new myapp
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project

          # Verify project structure
          assert Dir.exist?("myapp")
          assert File.exist?("myapp/README.md")
          assert File.exist?("myapp/.picoruby-env.yml")
          assert Dir.exist?("myapp/storage/home")
          assert Dir.exist?("myapp/mrbgems/app")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Step 6-7: environment can be set and selected" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project
          Dir.chdir("myapp")
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Simulate env set (actual network operations skipped)
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env_name = "20251123_150000"
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # Set current environment
          capture_stdout do
            Picotorokko::Commands::Env.start(["current", env_name])
          end

          # Verify
          assert_equal env_name, Picotorokko::Env.get_current_env
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Verification: build directory structure" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project
          Dir.chdir("myapp")
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env_name = "20251123_160000"
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # Create simulated build structure
          build_path = Picotorokko::Env.get_build_path(env_name)
          FileUtils.mkdir_p(File.join(build_path, "R2P2-ESP32", "storage", "home"))
          FileUtils.mkdir_p(File.join(build_path, "R2P2-ESP32", "mrbgems"))

          # Verify build directory structure
          assert Dir.exist?(build_path)
          assert Dir.exist?(File.join(build_path, "R2P2-ESP32"))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Verification: mrbgems structure" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project

          # Verify mrbgems structure
          assert Dir.exist?("myapp/mrbgems/app")
          assert File.exist?("myapp/mrbgems/app/mrbgem.rake")
          assert File.exist?("myapp/mrbgems/app/mrblib/app.rb")
          assert File.exist?("myapp/mrbgems/app/src/app.c")
          assert File.exist?("myapp/mrbgems/app/README.md")

          # Verify mrbgem.rake content
          rake_content = File.read("myapp/mrbgems/app/mrbgem.rake")
          assert_match(/MRuby::Gem::Specification/, rake_content)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Verification: storage/home exists and is writable" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project

          # Verify storage/home
          assert Dir.exist?("myapp/storage/home")

          # Verify writable
          File.write("myapp/storage/home/test.rb", "# Test file")
          assert File.exist?("myapp/storage/home/test.rb")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end
end
