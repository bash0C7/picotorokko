# frozen_string_literal: true

require 'test/unit'
require 'tmpdir'
require_relative '../lib/m5libgen/mrbgem_generator'
require_relative '../lib/m5libgen/cpp_wrapper_generator'

class ManualOverrideIntegrationTest < Test::Unit::TestCase
  def setup
    @test_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
  end

  def test_skipped_methods_are_not_generated
    cpp_data = [
      {
        name: 'M5Unified',
        methods: [
          {
            name: 'dsp',
            return_type: 'M5AtomDisplay',
            parameters: [{ name: 'cfg', type: 'cfg.atom_display' }]
          },
          {
            name: 'update',
            return_type: 'void',
            parameters: []
          }
        ]
      }
    ]

    generator = M5LibGen::MrbgemGenerator.new(@test_dir)
    generator.generate(cpp_data)

    c_file = File.join(@test_dir, 'src', 'm5unified.c')
    content = File.read(c_file)

    # 'dsp' should be skipped (has override with :skip action)
    assert_not_includes content, 'mrbc_m5_dsp'

    # 'update' should be generated (no override)
    assert_includes content, 'mrbc_m5_update'
  end

  def test_custom_methods_use_override_code
    cpp_data = [
      {
        name: 'M5Unified',
        methods: [
          {
            name: 'begin',
            return_type: 'void',
            parameters: []
          }
        ]
      }
    ]

    generator = M5LibGen::MrbgemGenerator.new(@test_dir)
    generator.generate(cpp_data)

    c_file = File.join(@test_dir, 'src', 'm5unified.c')
    content = File.read(c_file)

    # Custom begin() wrapper should be used
    assert_includes content, 'mrbc_m5_begin_0'
    assert_includes content, 'm5unified_m5unified_begin_void'

    cpp_file = File.join(@test_dir, 'ports', 'esp32', 'm5unified_wrapper.cpp')
    cpp_content = File.read(cpp_file)

    # Custom C++ wrapper should be used
    assert_includes cpp_content, 'extern "C" void m5unified_m5unified_begin_void'
    assert_includes cpp_content, 'M5.begin()'
  end

  def test_led_setallcolor_uses_rgb888_override
    cpp_data = [
      {
        name: 'Led_Class',
        methods: [
          {
            name: 'setAllColor',
            return_type: 'void',
            parameters: [{ name: 'color', type: 'RGBColor&' }]
          }
        ]
      }
    ]

    generator = M5LibGen::MrbgemGenerator.new(@test_dir)
    generator.generate(cpp_data)

    c_file = File.join(@test_dir, 'src', 'm5unified.c')
    content = File.read(c_file)

    # Custom wrapper that accepts uint32_t RGB888
    assert_includes content, 'uint32_t rgb888'
    assert_includes content, 'GET_INT_ARG'
    assert_includes content, 'm5unified_led_class_setallcolor_uint32'

    cpp_file = File.join(@test_dir, 'ports', 'esp32', 'm5unified_wrapper.cpp')
    cpp_content = File.read(cpp_file)

    # Custom C++ wrapper
    assert_includes cpp_content, 'm5unified_led_class_setallcolor_uint32'
    assert_includes cpp_content, 'uint32_t rgb888'
    assert_includes cpp_content, 'M5.Led.setAllColor(rgb888)'
  end

  def test_rtc_methods_are_skipped_with_struct_references
    cpp_data = [
      {
        name: 'RTC_Base',
        methods: [
          {
            name: 'getTime',
            return_type: 'rtc_time_t&',
            parameters: []
          },
          {
            name: 'setDate',
            return_type: 'void',
            parameters: [{ name: 'date', type: 'rtc_date_t&' }]
          }
        ]
      }
    ]

    generator = M5LibGen::MrbgemGenerator.new(@test_dir)
    stats = generator.generate(cpp_data)

    # Both methods should be skipped
    assert_equal 2, stats[:skipped_by_override]
    assert_equal 0, stats[:generated_count]

    c_file = File.join(@test_dir, 'src', 'm5unified.c')
    content = File.read(c_file)

    # RTC methods should not be generated
    assert_not_includes content, 'gettime'
    assert_not_includes content, 'setdate'
  end

  def test_statistics_track_overrides
    cpp_data = [
      {
        name: 'M5Unified',
        methods: [
          { name: 'dsp', return_type: 'void', parameters: [] },        # Skipped
          { name: 'begin', return_type: 'void', parameters: [] },      # Custom
          { name: 'update', return_type: 'void', parameters: [] }      # Normal
        ]
      },
      {
        name: 'Led_Class',
        methods: [
          { name: 'setAllColor', return_type: 'void', parameters: [] } # Custom
        ]
      }
    ]

    generator = M5LibGen::MrbgemGenerator.new(@test_dir)
    stats = generator.generate(cpp_data)

    assert_equal 1, stats[:skipped_by_override]
    assert_equal 2, stats[:custom_override_count]
    assert_equal 3, stats[:generated_count] # 2 custom + 1 normal
  end
end
