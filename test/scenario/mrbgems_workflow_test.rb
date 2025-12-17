require "test_helper"
require "tmpdir"
require "fileutils"

class ScenarioMrbgemsWorkflowTest < PicotorokkoTestCase
  # mrbgems workflow scenario tests
  # Verify mrbgems are correctly generated using ptrk commands

  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  sub_test_case "Scenario: mrbgems workflow from project creation" do
    test "ptrk new creates project with default applib mrbgem" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        applib_dir = File.join(project_dir, "mrbgems", "picoruby-applib")

        # Verify mrbgems/picoruby-applib/ is generated
        assert Dir.exist?(applib_dir), "Should create mrbgems/picoruby-applib/ directory"
        assert Dir.exist?(File.join(applib_dir, "mrblib")), "Should create mrblib directory"
        assert Dir.exist?(File.join(applib_dir, "src")), "Should create src directory"
        assert File.exist?(File.join(applib_dir, "mrbgem.rake")), "Should create mrbgem.rake"
        assert File.exist?(File.join(applib_dir, "mrblib", "applib.rb")), "Should create applib.rb"
        assert File.exist?(File.join(applib_dir, "src", "applib.c")), "Should create applib.c"
      end
    end

    test "user can generate custom mrbgem using ptrk mrbgems generate" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Generate custom mrbgem
        output, status = run_ptrk_command("mrbgems generate mylib", cwd: project_dir)
        assert status.success?, "ptrk mrbgems generate should succeed. Output: #{output}"

        mylib_dir = File.join(project_dir, "mrbgems", "picoruby-mylib")

        # Verify mrbgems/picoruby-mylib/ is generated
        assert Dir.exist?(mylib_dir), "Should create mrbgems/picoruby-mylib/ directory"
        assert Dir.exist?(File.join(mylib_dir, "mrblib")), "Should create mylib mrblib directory"
        assert Dir.exist?(File.join(mylib_dir, "src")), "Should create mylib src directory"
        assert File.exist?(File.join(mylib_dir, "mrbgem.rake")), "Should create mylib mrbgem.rake"
        assert File.exist?(File.join(mylib_dir, "mrblib", "mylib.rb")), "Should create mylib.rb"
        assert File.exist?(File.join(mylib_dir, "src", "mylib.c")), "Should create mylib.c"

        # Verify content uses correct names
        rake_content = File.read(File.join(mylib_dir, "mrbgem.rake"))
        assert_match(/MRuby::Gem::Specification\.new\('picoruby-mylib'\)/, rake_content)

        c_content = File.read(File.join(mylib_dir, "src", "mylib.c"))
        assert_match(/mrbc_mylib_init/, c_content)
      end
    end

    test "multiple mrbgems can be created in project" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Generate second mrbgem
        output, status = run_ptrk_command("mrbgems generate mylib", cwd: project_dir)
        assert status.success?, "ptrk mrbgems generate mylib should succeed. Output: #{output}"

        # Generate third mrbgem
        output, status = run_ptrk_command("mrbgems generate utils", cwd: project_dir)
        assert status.success?, "ptrk mrbgems generate utils should succeed. Output: #{output}"

        # Verify all mrbgems exist
        assert Dir.exist?(File.join(project_dir, "mrbgems", "picoruby-applib")), "Should have picoruby-applib mrbgem"
        assert Dir.exist?(File.join(project_dir, "mrbgems", "picoruby-mylib")), "Should have picoruby-mylib mrbgem"
        assert Dir.exist?(File.join(project_dir, "mrbgems", "picoruby-utils")), "Should have picoruby-utils mrbgem"

        # Verify each has complete structure
        [["applib", "applib"], ["mylib", "mylib"], ["utils", "utils"]].each do |gem_name, prefix|
          assert File.exist?(File.join(project_dir, "mrbgems", "picoruby-#{gem_name}", "mrbgem.rake")),
                 "Should have mrbgem.rake for #{gem_name}"
          assert File.exist?(File.join(project_dir, "mrbgems", "picoruby-#{gem_name}", "mrblib", "#{prefix}.rb")),
                 "Should have #{prefix}.rb for #{gem_name}"
          assert File.exist?(File.join(project_dir, "mrbgems", "picoruby-#{gem_name}", "src", "#{prefix}.c")),
                 "Should have #{prefix}.c for #{gem_name}"
        end

        # Verify mrbgems are distinct
        applib_rake = File.read(File.join(project_dir, "mrbgems", "picoruby-applib", "mrbgem.rake"))
        mylib_rake = File.read(File.join(project_dir, "mrbgems", "picoruby-mylib", "mrbgem.rake"))
        assert_match(/Specification\.new\('picoruby-applib'\)/, applib_rake)
        assert_match(/Specification\.new\('picoruby-mylib'\)/, mylib_rake)
      end
    end

    test "generated mrbgems have correct class names in Ruby code" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Generate with different naming patterns
        run_ptrk_command("mrbgems generate my_lib", cwd: project_dir)
        run_ptrk_command("mrbgems generate MyAwesomeLib", cwd: project_dir)

        # Verify my_lib uses correct class name
        my_lib_rb = File.read(File.join(project_dir, "mrbgems", "picoruby-my_lib", "mrblib", "my_lib.rb"))
        assert_match(/class MyLib/, my_lib_rb)

        # Verify MyAwesomeLib preserves capitalization
        awesome_rb = File.read(File.join(project_dir, "mrbgems", "picoruby-MyAwesomeLib", "mrblib", "myawesomelib.rb"))
        assert_match(/class MyAwesomeLib/, awesome_rb)

        # Verify C code uses lowercase for function names
        my_lib_c = File.read(File.join(project_dir, "mrbgems", "picoruby-my_lib", "src", "my_lib.c"))
        assert_match(/mrbc_my_lib_init/, my_lib_c)

        awesome_c = File.read(File.join(project_dir, "mrbgems", "picoruby-MyAwesomeLib", "src", "myawesomelib.c"))
        assert_match(/mrbc_myawesomelib_init/, awesome_c)
      end
    end

    test "mrbgems directory structure can be copied to build path" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Generate custom mrbgem
        run_ptrk_command("mrbgems generate custom", cwd: project_dir)

        # Verify mrbgems directory exists in project
        assert Dir.exist?(File.join(project_dir, "mrbgems")), "mrbgems directory should exist"
        assert Dir.exist?(File.join(project_dir, "mrbgems", "picoruby-applib")), "default picoruby-applib mrbgem should exist"
        assert Dir.exist?(File.join(project_dir, "mrbgems", "picoruby-custom")), "picoruby-custom mrbgem should exist"

        # Simulate copying to build directory
        mrbgems_src = File.join(project_dir, "mrbgems")
        build_mrbgems_dst = File.join(tmpdir, "build", "R2P2-ESP32", "components",
                                      "picoruby-esp32", "picoruby", "mrbgems")

        FileUtils.mkdir_p(File.dirname(build_mrbgems_dst))
        FileUtils.cp_r(mrbgems_src, build_mrbgems_dst)

        # Verify copy worked
        assert Dir.exist?(build_mrbgems_dst), "mrbgems should be copied to nested picoruby path"
        assert Dir.exist?(File.join(build_mrbgems_dst, "picoruby-applib")), "picoruby-applib should exist in copied path"
        assert Dir.exist?(File.join(build_mrbgems_dst, "picoruby-custom")), "picoruby-custom should exist in copied path"
        assert Dir.exist?(File.join(build_mrbgems_dst, "picoruby-applib", "mrblib")), "applib mrblib should exist"
      end
    end

    test "mrbgems structure includes all required files for building" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Generate multiple mrbgems with different styles
        run_ptrk_command("mrbgems generate utils", cwd: project_dir)
        run_ptrk_command("mrbgems generate device_helpers", cwd: project_dir)

        # Verify all mrbgems have README
        %w[applib utils device_helpers].each do |gem_name|
          readme = File.join(project_dir, "mrbgems", "picoruby-#{gem_name}", "README.md")
          assert File.exist?(readme), "Should have README.md for #{gem_name}"

          # Verify all mrbgems have proper mrblib structure
          mrblib = File.join(project_dir, "mrbgems", "picoruby-#{gem_name}", "mrblib")
          assert Dir.exist?(mrblib), "Should have mrblib directory for #{gem_name}"

          # Each mrblib should have at least one .rb file
          rb_files = Dir.glob(File.join(mrblib, "*.rb"))
          assert rb_files.any?, "#{gem_name} should have Ruby files in mrblib"
        end
      end
    end

    test "mrbgems have proper source files with C support" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Generate mrbgem with C code
        run_ptrk_command("mrbgems generate native_lib", cwd: project_dir)

        native_lib = File.join(project_dir, "mrbgems", "picoruby-native_lib")

        # Verify src directory has C file
        src_dir = File.join(native_lib, "src")
        assert Dir.exist?(src_dir), "Should have src directory"

        c_files = Dir.glob(File.join(src_dir, "*.c"))
        assert c_files.any?, "Should have C source files"

        c_content = File.read(File.join(src_dir, "native_lib.c"))
        assert_match(/mrbc_native_lib_init/, c_content)
        assert_match(/"NativeLib"/, c_content)
      end
    end

    test "Mrbgemfile exists in project after creation" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        mrbgemfile = File.join(project_dir, "Mrbgemfile")

        # Verify Mrbgemfile exists
        assert File.exist?(mrbgemfile), "Mrbgemfile should exist"

        # Verify it contains references to mrbgems
        content = File.read(mrbgemfile)
        assert_match(/mrbgems do/, content)
        assert_match(/conf\.gem.*mrbgems/, content)
      end
    end

    test "mrbgem names support underscores and lowercase" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Generate mrbgems with various naming patterns
        run_ptrk_command("mrbgems generate string_utils", cwd: project_dir)
        run_ptrk_command("mrbgems generate device_io", cwd: project_dir)

        # Verify all were created successfully
        assert Dir.exist?(File.join(project_dir, "mrbgems", "picoruby-string_utils"))
        assert Dir.exist?(File.join(project_dir, "mrbgems", "picoruby-device_io"))

        # Verify mrbgem.rake files have correct names
        su_rake = File.read(File.join(project_dir, "mrbgems", "picoruby-string_utils", "mrbgem.rake"))
        di_rake = File.read(File.join(project_dir, "mrbgems", "picoruby-device_io", "mrbgem.rake"))

        assert_match(/Specification\.new\('picoruby-string_utils'\)/, su_rake)
        assert_match(/Specification\.new\('picoruby-device_io'\)/, di_rake)
      end
    end
  end
end
