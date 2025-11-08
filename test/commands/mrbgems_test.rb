# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsMrbgemsTest < Test::Unit::TestCase
  # テスト用の一時ディレクトリ
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
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

  # mrbgems generate コマンドのテスト

  test "generates App mrbgem template with default name" do
    output = capture_stdout do
      Pra::Commands::Mrbgems.start(["generate"])
    end

    # 出力を確認
    assert_match(/Generating mrbgem template: App/, output)
    assert_match(/Created directories/, output)
    assert_match(/Created: mrbgem.rake/, output)
    assert_match(/Created: app.rb/, output)
    assert_match(/Created: app.c/, output)
    assert_match(/Created: README.md/, output)

    # ディレクトリが作成されたことを確認
    assert_true(Dir.exist?("mrbgems/App"))
    assert_true(Dir.exist?("mrbgems/App/mrblib"))
    assert_true(Dir.exist?("mrbgems/App/src"))

    # ファイルが作成されたことを確認
    assert_true(File.exist?("mrbgems/App/mrbgem.rake"))
    assert_true(File.exist?("mrbgems/App/mrblib/app.rb"))
    assert_true(File.exist?("mrbgems/App/src/app.c"))
    assert_true(File.exist?("mrbgems/App/README.md"))
  end

  test "generates custom named mrbgem" do
    output = capture_stdout do
      Pra::Commands::Mrbgems.start(["generate", "CustomLib"])
    end

    # 出力を確認
    assert_match(/Generating mrbgem template: CustomLib/, output)

    # ディレクトリが作成されたことを確認
    assert_true(Dir.exist?("mrbgems/CustomLib"))
    assert_true(File.exist?("mrbgems/CustomLib/mrblib/customlib.rb"))
    assert_true(File.exist?("mrbgems/CustomLib/src/customlib.c"))
  end

  test "generates mrbgem.rake with correct content" do
    capture_stdout do
      Pra::Commands::Mrbgems.start(["generate", "App"])
    end

    content = File.read("mrbgems/App/mrbgem.rake")

    # 内容を確認
    assert_match(/MRuby::Gem::Specification\.new\('App'\)/, content)
    assert_match(/spec\.license = 'MIT'/, content)
    assert_match(/spec\.summary = 'Application-specific mrbgem'/, content)
  end

  test "generates app.rb with App class" do
    capture_stdout do
      Pra::Commands::Mrbgems.start(["generate", "App"])
    end

    content = File.read("mrbgems/App/mrblib/app.rb")

    # クラス定義を確認
    assert_match(/class App/, content)
    assert_match(/Class methods are defined in C extension/, content)
  end

  test "generates app.c with mrbgem initialization" do
    capture_stdout do
      Pra::Commands::Mrbgems.start(["generate", "App"])
    end

    content = File.read("mrbgems/App/src/app.c")

    # マクロと関数を確認
    assert_include(content, "#elif defined(PICORB_VM_MRUBYC)")
    assert_include(content, "#include <mrubyc.h>")
    assert_match(/void\s+mrbc_app_init/, content)
    assert_include(content, "mrbc_define_class")
    assert_include(content, '"App"')
    assert_include(content, "mrbc_define_method")
    assert_include(content, '"version"')
    assert_include(content, "App.version")
  end

  test "raises error when directory already exists" do
    # ディレクトリを事前に作成
    FileUtils.mkdir_p("mrbgems/App")

    assert_raises(RuntimeError) do
      capture_stdout do
        Pra::Commands::Mrbgems.start(["generate", "App"])
      end
    end
  end

  test "includes author name in generated mrbgem.rake" do
    capture_stdout do
      Pra::Commands::Mrbgems.start(["generate", "App"])
    end

    content = File.read("mrbgems/App/mrbgem.rake")

    # author_nameが含まれていることを確認
    assert_match(/spec\.author/, content)
  end

  test "accepts --author option" do
    capture_stdout do
      Pra::Commands::Mrbgems.start(["generate", "App", "--author", "Test Author"])
    end

    content = File.read("mrbgems/App/mrbgem.rake")

    # author_nameが正しく設定されたことを確認
    assert_match(/spec\.author\s*=\s*'Test Author'/, content)
  end

  test "generated C code uses correct variable names" do
    capture_stdout do
      Pra::Commands::Mrbgems.start(["generate", "CustomLib"])
    end

    content = File.read("mrbgems/CustomLib/src/customlib.c")

    # 変数名とクラス名が正しく置換されたことを確認
    assert_match(/void\s+mrbc_customlib_init/, content)
    assert_match(/mrbc_define_class\(vm, "CustomLib"/, content)
    assert_match(/c_customlib_version/, content)
    assert_match(/CustomLib\.version/, content)
  end

  test "displays next steps message" do
    output = capture_stdout do
      Pra::Commands::Mrbgems.start(["generate", "App"])
    end

    # ナビゲーションメッセージを確認
    assert_match(/Next steps/, output)
    assert_match(/Edit the C extension/, output)
    assert_match(/pra build setup/, output)
  end
end
