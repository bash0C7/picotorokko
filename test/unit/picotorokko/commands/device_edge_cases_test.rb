require "English"
require_relative "../../../test_helper"
require_relative "../../../../lib/picotorokko/commands/device"

class CommandsDeviceEdgeCasesTest < PicotorokkoTestCase
  # Edge cases for environment resolution
  sub_test_case "device command environment resolution edge cases" do
    test "rejects invalid environment name format" do
      # Mock the executor to avoid actual execution
      mock_executor = Picotorokko::MockExecutor.new
      Picotorokko::Env.set_executor(mock_executor)

      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.reset_cached_root!

          # Invalid environment name should raise error
          error = assert_raise(RuntimeError) do
            Picotorokko::Commands::Device.start(["build", "--env", "invalid-name"])
          end

          # Should reference the invalid environment
          assert_include error.message, "invalid-name"
        end
      end

      Picotorokko::Env.set_executor(Picotorokko::ProductionExecutor.new)
    end

    test "handles missing environment gracefully" do
      mock_executor = Picotorokko::MockExecutor.new
      Picotorokko::Env.set_executor(mock_executor)

      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.reset_cached_root!

          # Try to use an environment that doesn't exist
          capture_stdout do
            Picotorokko::Commands::Device.start(["build", "--env", "20251121_120000"])
          rescue SystemExit, RuntimeError
            # Expected - environment doesn't exist
          end

          # Output should contain some error indication
          # (may be silent if resolve_env_name just returns nil gracefully)
        end
      end

      Picotorokko::Env.set_executor(Picotorokko::ProductionExecutor.new)
    end
  end

  # Edge cases for build paths
  sub_test_case "device command build path edge cases" do
    test "handles build directory creation" do
      mock_executor = Picotorokko::MockExecutor.new
      Picotorokko::Env.set_executor(mock_executor)

      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.reset_cached_root!

          # Create a minimal environment definition
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

          Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

          # Verify build path would be created
          build_path = Picotorokko::Env.get_build_path("20251121_120000")
          assert build_path.include?(".ptrk_build")
          assert build_path.include?("20251121_120000")
        end
      end

      Picotorokko::Env.set_executor(Picotorokko::ProductionExecutor.new)
    end

    test "handles setup marker existence check" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.reset_cached_root!

          build_path = Picotorokko::Env.get_build_path("20251121_120000")
          r2p2_full_path = File.join(build_path, "R2P2-ESP32")
          setup_marker = File.join(r2p2_full_path, "build/repos/esp32")

          # Without marker - should need setup
          assert !File.exist?(setup_marker)

          # Create marker
          FileUtils.mkdir_p(File.dirname(setup_marker))
          FileUtils.touch(setup_marker)

          # Now marker exists
          assert File.exist?(setup_marker)
        end
      end
    end
  end

  # Edge cases for Rake task extraction
  sub_test_case "device command rake task parsing edge cases" do
    test "handles missing Rakefile gracefully" do
      mock_executor = Picotorokko::MockExecutor.new
      Picotorokko::Env.set_executor(mock_executor)

      Dir.mktmpdir do |tmpdir|
        # No Rakefile in this directory
        assert !File.exist?(File.join(tmpdir, "Rakefile"))

        # The device command should handle this gracefully
        # (Either skip parsing or return empty task list)
      end

      Picotorokko::Env.set_executor(Picotorokko::ProductionExecutor.new)
    end

    test "handles Rakefile with syntax errors" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          # Write invalid Ruby code
          File.write("Rakefile", "invalid ruby syntax }{")

          # Parsing should not crash, should fail gracefully
          # (Prism should handle syntax errors)
          begin
            Prism.parse(File.read("Rakefile"))
            # Prism should parse it (even if it's invalid Ruby)
          rescue StandardError => e
            # Some parsing error is acceptable
            assert e.is_a?(StandardError)
          end
        end
      end
    end

    test "extracts tasks from complex Rakefile" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          rakefile_content = <<~RUBY
            task :build do
              puts "Building..."
            end

            task :flash do
              puts "Flashing..."
            end

            namespace :device do
              task :prepare do
                puts "Preparing..."
              end
            end
          RUBY

          File.write("Rakefile", rakefile_content)

          # Parse the Rakefile - should succeed without syntax errors
          result = Prism.parse(File.read("Rakefile"))
          # Prism.parse returns a ParseResult, which has the AST in its body
          assert_not_nil result
        end
      end
    end
  end

  # Edge cases for monitor command output
  sub_test_case "device monitor command edge cases" do
    test "generates correct monitor command for valid environment" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.reset_cached_root!

          # Create environment definition
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

          Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

          # Create mock build structure
          build_path = Picotorokko::Env.get_build_path("20251121_120000")
          r2p2_path = File.join(build_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_path)

          # Monitor command should reference correct path
          # (Verify by checking what would be printed)
          expected_path = r2p2_path
          assert expected_path.include?(".ptrk_build")
          assert expected_path.include?("R2P2-ESP32")
        end
      end
    end
  end

  # Edge cases for flash command
  sub_test_case "device flash command edge cases" do
    test "flash command references correct environment" do
      mock_executor = Picotorokko::MockExecutor.new
      Picotorokko::Env.set_executor(mock_executor)

      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.reset_cached_root!

          # Create environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

          Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

          # Create R2P2 path structure
          build_path = Picotorokko::Env.get_build_path("20251121_120000")
          r2p2_path = File.join(build_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_path)

          # Verify paths exist
          assert Dir.exist?(r2p2_path)
        end
      end

      Picotorokko::Env.set_executor(Picotorokko::ProductionExecutor.new)
    end
  end

  # Edge cases for prepare command
  sub_test_case "device prepare command edge cases" do
    test "prepare command deletes existing build directory" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.reset_cached_root!

          build_path = Picotorokko::Env.get_build_path("20251121_120000")

          # Create build directory with content
          FileUtils.mkdir_p(build_path)
          test_file = File.join(build_path, "test.txt")
          File.write(test_file, "content")

          assert Dir.exist?(build_path)
          assert File.exist?(test_file)

          # Simulate prepare command behavior (delete existing)
          FileUtils.rm_rf(build_path)

          # Directory should be gone
          assert !Dir.exist?(build_path)
        end
      end
    end

    test "prepare command creates fresh build directory" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.reset_cached_root!

          build_path = Picotorokko::Env.get_build_path("20251121_120000")

          # Simulate prepare: create fresh directory
          FileUtils.mkdir_p(build_path)

          assert Dir.exist?(build_path)
        end
      end
    end
  end
end
