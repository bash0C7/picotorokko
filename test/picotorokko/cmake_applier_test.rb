require_relative "../test_helper"

class PicotororkoCMakeApplierTest < PraTestCase
  test "append cmake directives to empty CMakeLists.txt" do
    content = ""

    cmake_directives = [
      "target_sources(app PRIVATE src/sensor.c)",
      "target_include_directories(app PRIVATE include/)"
    ]

    result = Picotorokko::CMakeApplier.apply(content, cmake_directives)

    assert_includes result, "# === BEGIN Mrbgemfile generated ==="
    assert_includes result, "# === END Mrbgemfile generated ==="
    assert_includes result, "target_sources(app PRIVATE src/sensor.c)"
    assert_includes result, "target_include_directories(app PRIVATE include/)"
  end

  test "append cmake directives to existing CMakeLists.txt" do
    content = <<~CMAKE
      idf_component_register(
        SRCS "main.c"
        INCLUDE_DIRS "include"
      )
    CMAKE

    cmake_directives = [
      "target_sources(app PRIVATE src/sensor.c)"
    ]

    result = Picotorokko::CMakeApplier.apply(content, cmake_directives)

    # Original content should be preserved
    assert_includes result, 'SRCS "main.c"'
    assert_includes result, 'INCLUDE_DIRS "include"'
    # New directives should be added
    assert_includes result, "target_sources(app PRIVATE src/sensor.c)"
  end

  test "replace existing marker section in CMakeLists.txt" do
    content = <<~CMAKE
      idf_component_register(
        SRCS "main.c"
        INCLUDE_DIRS "include"
      )
      # === BEGIN Mrbgemfile generated ===
      target_sources(app PRIVATE old/sensor.c)
      # === END Mrbgemfile generated ===
    CMAKE

    cmake_directives = [
      "target_sources(app PRIVATE new/sensor.c)"
    ]

    result = Picotorokko::CMakeApplier.apply(content, cmake_directives)

    # Original content should be preserved
    assert_includes result, 'SRCS "main.c"'
    # Old directive should be removed
    assert_not_includes result, "old/sensor.c"
    # New directive should be present
    assert_includes result, "new/sensor.c"
  end

  test "handle multiple cmake directives" do
    content = ""

    cmake_directives = [
      "target_sources(picoruby_app PRIVATE src/sensor.c)",
      "target_sources(picoruby_app PRIVATE src/motor.c)",
      "target_link_libraries(picoruby_app PRIVATE m)"
    ]

    result = Picotorokko::CMakeApplier.apply(content, cmake_directives)

    assert_includes result, "target_sources(picoruby_app PRIVATE src/sensor.c)"
    assert_includes result, "target_sources(picoruby_app PRIVATE src/motor.c)"
    assert_includes result, "target_link_libraries(picoruby_app PRIVATE m)"
  end
end
