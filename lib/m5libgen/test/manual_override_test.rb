# frozen_string_literal: true

require "test/unit"
require_relative "../lib/m5libgen/manual_override"

class ManualOverrideTest < Test::Unit::TestCase
  def setup
    @override = M5LibGen::ManualOverride.new
  end

  def test_has_override_returns_true_for_registered_methods
    assert_true @override.has_override?("M5Unified", "dsp")
    assert_true @override.has_override?("M5Unified", "addDisplay")
    assert_true @override.has_override?("M5Unified", "begin")
  end

  def test_has_override_returns_false_for_normal_methods
    assert_false @override.has_override?("M5Unified", "update")
    assert_false @override.has_override?("Button_Class", "wasPressed")
  end

  def test_has_override_is_case_insensitive
    assert_true @override.has_override?("m5unified", "DSP")
    assert_true @override.has_override?("M5UNIFIED", "dsp")
  end

  def test_get_action_returns_skip_for_problematic_methods
    assert_equal :skip, @override.get_action("M5Unified", "dsp")
    assert_equal :skip, @override.get_action("M5Unified", "addDisplay")
  end

  def test_get_action_returns_custom_for_custom_methods
    assert_equal :custom, @override.get_action("M5Unified", "begin")
    assert_equal :custom, @override.get_action("Led_Class", "setAllColor")
  end

  def test_get_action_returns_nil_for_normal_methods
    assert_nil @override.get_action("M5Unified", "update")
    assert_nil @override.get_action("Button_Class", "wasPressed")
  end

  def test_get_skip_reason_returns_reason_for_skipped_methods
    reason = @override.get_skip_reason("M5Unified", "dsp")
    assert_not_nil reason
    assert_includes reason.downcase, "overload"
  end

  def test_get_skip_reason_returns_nil_for_non_skipped_methods
    assert_nil @override.get_skip_reason("M5Unified", "begin")
    assert_nil @override.get_skip_reason("M5Unified", "update")
  end

  def test_get_cpp_wrapper_returns_custom_code_for_begin
    method = { name: "begin", parameters: [] }
    code = @override.get_cpp_wrapper("M5Unified", "begin", method)

    assert_not_nil code
    assert_includes code, 'extern "C"'
    assert_includes code, "M5.begin()"
    assert_includes code, "m5unified_m5unified_begin_void"
  end

  def test_get_cpp_wrapper_returns_nil_for_skipped_methods
    method = { name: "dsp", parameters: [] }
    code = @override.get_cpp_wrapper("M5Unified", "dsp", method)

    assert_nil code
  end

  def test_get_cpp_wrapper_returns_nil_for_normal_methods
    method = { name: "update", parameters: [] }
    code = @override.get_cpp_wrapper("M5Unified", "update", method)

    assert_nil code
  end

  def test_get_c_binding_returns_custom_code_for_begin
    method = { name: "begin", parameters: [] }
    code = @override.get_c_binding("M5Unified", "begin", method)

    assert_not_nil code
    assert_includes code, "mrbc_m5_begin_0"
    assert_includes code, "m5unified_m5unified_begin_void"
    assert_includes code, "SET_NIL_RETURN"
  end

  def test_get_c_binding_handles_proc_generators
    method = {
      name: "setAllColor",
      parameters: [{ name: "color", type: "RGBColor&" }]
    }
    code = @override.get_c_binding("Led_Class", "setAllColor", method)

    assert_not_nil code
    assert_includes code, "GET_INT_ARG"
    assert_includes code, "rgb888"
  end

  def test_rtc_methods_are_skipped_with_reason
    # getTime and getDateTime are still skipped (return struct references)
    assert_equal :skip, @override.get_action("RTC_Base", "getTime")
    assert_equal :skip, @override.get_action("RTC_Base", "getDateTime")

    reason = @override.get_skip_reason("RTC_Base", "getTime")
    assert_includes reason.downcase, "struct"
  end

  def test_led_setcolor_with_index_parameter
    method = {
      name: "setColor",
      parameters: [
        { name: "index", type: "size_t" },
        { name: "color", type: "RGBColor&" }
      ]
    }
    code = @override.get_cpp_wrapper("Led_Class", "setColor", method)

    assert_not_nil code
    assert_includes code, "size_t index"
    assert_includes code, "uint32_t rgb888"
    assert_includes code, "M5.Led.setColor(index, rgb888)"
  end

  def test_imu_getaccel_returns_array
    method = { name: "getAccel", parameters: [] }

    cpp_code = @override.get_cpp_wrapper("IMU_Class", "getAccel", method)
    assert_not_nil cpp_code
    assert_includes cpp_code, "m5unified_imu_class_getaccel_array"
    assert_includes cpp_code, "M5.Imu.getAccel"
    assert_includes cpp_code, "result[0]"
    assert_includes cpp_code, "result[1]"
    assert_includes cpp_code, "result[2]"

    c_code = @override.get_c_binding("IMU_Class", "getAccel", method)
    assert_not_nil c_code
    assert_includes c_code, "mrbc_array_new"
    assert_includes c_code, "mrbc_float_value"
    assert_includes c_code, "mrbc_array_set"
  end

  def test_imu_has_three_custom_overrides
    assert_equal :custom, @override.get_action("IMU_Class", "getAccel")
    assert_equal :custom, @override.get_action("IMU_Class", "getGyro")
    assert_equal :custom, @override.get_action("IMU_Class", "getMag")
  end

  def test_rtc_has_three_custom_overrides
    # Struct return values using Array pattern (like IMU)
    assert_equal :custom, @override.get_action("RTC_Class", "getTime")
    assert_equal :custom, @override.get_action("RTC_Class", "getDate")
    assert_equal :custom, @override.get_action("RTC_Class", "getDateTime")
  end

  def test_rtc_gettime_returns_array
    method = { name: "getTime", parameters: [] }
    cpp_code = @override.get_cpp_wrapper("RTC_Class", "getTime", method)

    assert_not_nil cpp_code
    assert_includes cpp_code, "m5unified_rtc_class_gettime_array"
    assert_includes cpp_code, "rtc_time_t time = M5.Rtc.getTime()"
    assert_includes cpp_code, "result[0] = time.hours"
    assert_includes cpp_code, "result[1] = time.minutes"
    assert_includes cpp_code, "result[2] = time.seconds"

    c_code = @override.get_c_binding("RTC_Class", "getTime", method)
    assert_not_nil c_code
    assert_includes c_code, "mrbc_array_new"
    assert_includes c_code, "mrbc_integer_value"
    assert_includes c_code, "mrbc_array_set"
  end

  def test_rtc_getdate_returns_array
    method = { name: "getDate", parameters: [] }
    cpp_code = @override.get_cpp_wrapper("RTC_Class", "getDate", method)

    assert_not_nil cpp_code
    assert_includes cpp_code, "rtc_date_t date = M5.Rtc.getDate()"
    assert_includes cpp_code, "result[0] = date.year"
    assert_includes cpp_code, "result[3] = date.weekDay"
  end

  def test_rtc_getdatetime_returns_array
    method = { name: "getDateTime", parameters: [] }
    cpp_code = @override.get_cpp_wrapper("RTC_Class", "getDateTime", method)

    assert_not_nil cpp_code
    assert_includes cpp_code, "rtc_datetime_t dt = M5.Rtc.getDateTime()"
    assert_includes cpp_code, "result[0] = dt.date.year"
    assert_includes cpp_code, "result[4] = dt.time.hours"
  end
end
