require_relative "test_helper"

class GemspecTest < PraTestCase
  def test_executable_name_is_ptrk
    # 2.1: Rename gemspec and bin/ptrk
    # Red: Verify executable is named 'ptrk', not 'pra'
    assert File.exist?(File.join(__dir__, "..", "exe", "ptrk")),
           "exe/ptrk executable should exist"
  end

  def test_gem_name_includes_picotorokko
    # 2.1: Rename gemspec
    # Red: Verify gem name includes 'picotorokko'
    gemspec_path = File.join(__dir__, "..", "picoruby-application-on-r2p2-esp32-development-kit.gemspec")
    gemspec_content = File.read(gemspec_path)

    assert gemspec_content.include?('spec.name = "picotorokko"'),
           "gemspec should set spec.name to 'picotorokko'"
  end
end
