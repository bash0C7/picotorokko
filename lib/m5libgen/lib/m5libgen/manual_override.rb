# frozen_string_literal: true

module M5LibGen
  # Manual override system for methods that cannot be handled by generic rules
  #
  # 90% of M5Unified methods work with generic type mapping rules.
  # The remaining 10% require M5Unified-specific knowledge and custom wrappers.
  #
  # This class provides:
  # - Custom C++ wrapper code for problematic method signatures
  # - Custom C binding code for unsupported parameter types
  # - Skip directives for methods that cannot be wrapped
  #
  class ManualOverride
    def initialize
      @overrides = load_overrides
    end

    # Check if a method has a manual override
    #
    # @param class_name [String] C++ class name
    # @param method_name [String] Method name
    # @return [Boolean] true if override exists
    def has_override?(class_name, method_name)
      key = normalize_key(class_name, method_name)
      @overrides.key?(key)
    end

    # Get override action for a method
    #
    # @param class_name [String] C++ class name
    # @param method_name [String] Method name
    # @return [Symbol] :skip, :custom, or nil
    def get_action(class_name, method_name)
      override = get_override(class_name, method_name)
      override ? override[:action] : nil
    end

    # Get custom C++ wrapper code
    #
    # @param class_name [String] C++ class name
    # @param method_name [String] Method name
    # @param method [Hash] Method metadata from parser
    # @return [String, nil] Custom C++ code or nil
    def get_cpp_wrapper(class_name, method_name, method)
      override = get_override(class_name, method_name)
      return nil unless override && override[:action] == :custom

      # Execute custom generator if proc
      if override[:cpp_wrapper].is_a?(Proc)
        override[:cpp_wrapper].call(method)
      else
        override[:cpp_wrapper]
      end
    end

    # Get custom C binding code
    #
    # @param class_name [String] C++ class name
    # @param method_name [String] Method name
    # @param method [Hash] Method metadata from parser
    # @return [String, nil] Custom C code or nil
    def get_c_binding(class_name, method_name, method)
      override = get_override(class_name, method_name)
      return nil unless override && override[:action] == :custom

      # Execute custom generator if proc
      if override[:c_binding].is_a?(Proc)
        override[:c_binding].call(method)
      else
        override[:c_binding]
      end
    end

    # Get skip reason
    #
    # @param class_name [String] C++ class name
    # @param method_name [String] Method name
    # @return [String, nil] Reason for skipping or nil
    def get_skip_reason(class_name, method_name)
      override = get_override(class_name, method_name)
      override && override[:action] == :skip ? override[:reason] : nil
    end

    private

    def get_override(class_name, method_name)
      key = normalize_key(class_name, method_name)
      @overrides[key]
    end

    def normalize_key(class_name, method_name)
      "#{class_name}::#{method_name}".downcase
    end

    def load_overrides
      {
        # ========================================================================
        # P0: Invalid type names (9 methods)
        # Problem: Parser extracts "cfg.atom_display" as type name
        # Solution: Skip these overloads, keep only config_t version
        # ========================================================================
        "m5unified::dsp" => {
          action: :skip,
          reason: "Multiple overloads with problematic types. Use M5.begin(config) instead."
        },

        # ========================================================================
        # P1: Object references - Display objects
        # Problem: M5GFX& cannot be passed from PicoRuby
        # Solution: Provide index-based access only
        # ========================================================================
        "m5unified::adddisplay" => {
          action: :skip,
          reason: "Takes M5GFX& parameter (object reference not supported in mrubyc)"
        },

        "log_class::setdisplay" => {
          action: :skip,
          reason: "Takes M5GFX& parameter (object reference not supported)"
        },

        # ========================================================================
        # P1: Object references - Struct references
        # Problem: config_t&, rtc_time_t&, etc. are struct references
        # Solution: Custom wrapper that accepts individual fields
        # ========================================================================
        "m5unified::begin" => {
          action: :custom,
          cpp_wrapper: lambda { |method|
            # Check parameter count to identify which overload
            if method[:parameters].empty?
              # begin() - no parameters, use default config
              <<~CPP
                extern "C" void m5unified_m5unified_begin_void(void) {
                  M5.begin();
                }
              CPP
            else
              # begin(config_t cfg) - skip, too complex for now
              nil
            end
          },
          c_binding: lambda { |method|
            if method[:parameters].empty?
              <<~C
                static void mrbc_m5_begin_0(mrbc_vm *vm, mrbc_value *v, int argc) {
                  m5unified_m5unified_begin_void();
                  SET_NIL_RETURN();
                }
              C
            end
          }
        },

        # ========================================================================
        # P1: RGBColor struct
        # Problem: RGBColor& is struct reference
        # Solution: Accept uint32_t RGB888 value instead
        # ========================================================================
        "led_class::setallcolor" => {
          action: :custom,
          cpp_wrapper: lambda { |_method|
            <<~CPP
              extern "C" void m5unified_led_class_setallcolor_uint32(uint32_t rgb888) {
                // Convert RGB888 to RGBColor struct
                M5.Led.setAllColor(rgb888);
              }
            CPP
          },
          c_binding: lambda { |_method|
            <<~C
              static void mrbc_m5_setallcolor_1(mrbc_vm *vm, mrbc_value *v, int argc) {
                uint32_t rgb888 = GET_INT_ARG(1);
                m5unified_led_class_setallcolor_uint32(rgb888);
                SET_NIL_RETURN();
              }
            C
          }
        },

        "led_class::setcolor" => {
          action: :custom,
          cpp_wrapper: lambda { |_method|
            <<~CPP
              extern "C" void m5unified_led_class_setcolor_size_t_uint32(size_t index, uint32_t rgb888) {
                M5.Led.setColor(index, rgb888);
              }
            CPP
          },
          c_binding: lambda { |_method|
            <<~C
              static void mrbc_m5_setcolor_2(mrbc_vm *vm, mrbc_value *v, int argc) {
                size_t index = GET_INT_ARG(1);
                uint32_t rgb888 = GET_INT_ARG(2);
                m5unified_led_class_setcolor_size_t_uint32(index, rgb888);
                SET_NIL_RETURN();
              }
            C
          }
        },

        # ========================================================================
        # P1: RTC time/date structs
        # Problem: rtc_time_t&, rtc_date_t&, rtc_datetime_t& are struct references
        # Solution: Skip for now (complex structs)
        # ========================================================================
        "rtc_base::gettime" => {
          action: :skip,
          reason: "Returns rtc_time_t& (struct reference not supported)"
        },

        "rtc_base::getdate" => {
          action: :skip,
          reason: "Returns rtc_date_t& (struct reference not supported)"
        },

        "rtc_base::getdatetime" => {
          action: :skip,
          reason: "Returns rtc_datetime_t& (struct reference not supported)"
        },

        "rtc_base::settime" => {
          action: :skip,
          reason: "Takes rtc_time_t& parameter (struct reference not supported)"
        },

        "rtc_base::setdate" => {
          action: :skip,
          reason: "Takes rtc_date_t& parameter (struct reference not supported)"
        },

        "rtc_base::setdatetime" => {
          action: :skip,
          reason: "Takes rtc_datetime_t& parameter (struct reference not supported)"
        },

        # ========================================================================
        # P2: Default parameters
        # Problem: Default values incorrectly parsed into variable declarations
        # Solution: Generate multiple arity versions in Ruby
        # Note: This is handled by a generic rule in MrbgemGenerator, not per-method overrides
        # ========================================================================

        # ========================================================================
        # Phase 1: IMU Methods (CRITICAL - Output Pointers)
        # Problem: getAccel(float*, float*, float*) has output pointer parameters
        # Solution: Return array of [ax, ay, az] values
        # ========================================================================
        "imu_class::getaccel" => {
          action: :custom,
          cpp_wrapper: lambda { |_method|
            <<~CPP
              extern "C" int m5unified_imu_class_getaccel_array(float* result) {
                float ax, ay, az;
                bool success = M5.Imu.getAccel(&ax, &ay, &az);
                if (success) {
                  result[0] = ax;
                  result[1] = ay;
                  result[2] = az;
                  return 1;
                }
                return 0;
              }
            CPP
          },
          c_binding: lambda { |_method|
            <<~C
              static void mrbc_m5_getaccel_0(mrbc_vm *vm, mrbc_value *v, int argc) {
                float result[3];
                if (m5unified_imu_class_getaccel_array(result)) {
                  // Create array and set values
                  mrbc_value array = mrbc_array_new(vm, 3);
                  mrbc_value ax = mrbc_float_value(vm, result[0]);
                  mrbc_value ay = mrbc_float_value(vm, result[1]);
                  mrbc_value az = mrbc_float_value(vm, result[2]);
                  mrbc_array_set(&array, 0, &ax);
                  mrbc_array_set(&array, 1, &ay);
                  mrbc_array_set(&array, 2, &az);
                  SET_RETURN(array);
                } else {
                  SET_NIL_RETURN();
                }
              }
            C
          }
        },

        "imu_class::getgyro" => {
          action: :custom,
          cpp_wrapper: lambda { |_method|
            <<~CPP
              extern "C" int m5unified_imu_class_getgyro_array(float* result) {
                float gx, gy, gz;
                bool success = M5.Imu.getGyro(&gx, &gy, &gz);
                if (success) {
                  result[0] = gx;
                  result[1] = gy;
                  result[2] = gz;
                  return 1;
                }
                return 0;
              }
            CPP
          },
          c_binding: lambda { |_method|
            <<~C
              static void mrbc_m5_getgyro_0(mrbc_vm *vm, mrbc_value *v, int argc) {
                float result[3];
                if (m5unified_imu_class_getgyro_array(result)) {
                  mrbc_value array = mrbc_array_new(vm, 3);
                  mrbc_value gx = mrbc_float_value(vm, result[0]);
                  mrbc_value gy = mrbc_float_value(vm, result[1]);
                  mrbc_value gz = mrbc_float_value(vm, result[2]);
                  mrbc_array_set(&array, 0, &gx);
                  mrbc_array_set(&array, 1, &gy);
                  mrbc_array_set(&array, 2, &gz);
                  SET_RETURN(array);
                } else {
                  SET_NIL_RETURN();
                }
              }
            C
          }
        },

        "imu_class::getmag" => {
          action: :custom,
          cpp_wrapper: lambda { |_method|
            <<~CPP
              extern "C" int m5unified_imu_class_getmag_array(float* result) {
                float mx, my, mz;
                bool success = M5.Imu.getMag(&mx, &my, &mz);
                if (success) {
                  result[0] = mx;
                  result[1] = my;
                  result[2] = mz;
                  return 1;
                }
                return 0;
              }
            CPP
          },
          c_binding: lambda { |_method|
            <<~C
              static void mrbc_m5_getmag_0(mrbc_vm *vm, mrbc_value *v, int argc) {
                float result[3];
                if (m5unified_imu_class_getmag_array(result)) {
                  mrbc_value array = mrbc_array_new(vm, 3);
                  mrbc_value mx = mrbc_float_value(vm, result[0]);
                  mrbc_value my = mrbc_float_value(vm, result[1]);
                  mrbc_value mz = mrbc_float_value(vm, result[2]);
                  mrbc_array_set(&array, 0, &mx);
                  mrbc_array_set(&array, 1, &my);
                  mrbc_array_set(&array, 2, &mz);
                  SET_RETURN(array);
                } else {
                  SET_NIL_RETURN();
                }
              }
            C
          }
        },

        # ========================================================================
        # Phase 2: RTC Methods (3 methods - struct return values)
        # Problem: getTime(), getDate(), getDateTime() return structs by value
        # Solution: Array return pattern (same as IMU)
        # ========================================================================

        "rtc_class::gettime" => {
          action: :custom,
          cpp_wrapper: lambda { |_method|
            <<~CPP
              extern "C" int m5unified_rtc_class_gettime_array(int8_t* result) {
                rtc_time_t time = M5.Rtc.getTime();
                result[0] = time.hours;
                result[1] = time.minutes;
                result[2] = time.seconds;
                return 3;
              }
            CPP
          },
          c_binding: lambda { |_method|
            <<~C
              static void mrbc_m5_gettime_0(mrbc_vm *vm, mrbc_value *v, int argc) {
                int8_t result[3];
                if (m5unified_rtc_class_gettime_array(result)) {
                  mrbc_value array = mrbc_array_new(vm, 3);
                  mrbc_value hours = mrbc_integer_value(result[0]);
                  mrbc_value minutes = mrbc_integer_value(result[1]);
                  mrbc_value seconds = mrbc_integer_value(result[2]);
                  mrbc_array_set(&array, 0, &hours);
                  mrbc_array_set(&array, 1, &minutes);
                  mrbc_array_set(&array, 2, &seconds);
                  SET_RETURN(array);
                } else {
                  SET_NIL_RETURN();
                }
              }
            C
          }
        },

        "rtc_class::getdate" => {
          action: :custom,
          cpp_wrapper: lambda { |_method|
            <<~CPP
              extern "C" int m5unified_rtc_class_getdate_array(int16_t* result) {
                rtc_date_t date = M5.Rtc.getDate();
                result[0] = date.year;
                result[1] = date.month;
                result[2] = date.date;
                result[3] = date.weekDay;
                return 4;
              }
            CPP
          },
          c_binding: lambda { |_method|
            <<~C
              static void mrbc_m5_getdate_0(mrbc_vm *vm, mrbc_value *v, int argc) {
                int16_t result[4];
                if (m5unified_rtc_class_getdate_array(result)) {
                  mrbc_value array = mrbc_array_new(vm, 4);
                  mrbc_value year = mrbc_integer_value(result[0]);
                  mrbc_value month = mrbc_integer_value(result[1]);
                  mrbc_value date = mrbc_integer_value(result[2]);
                  mrbc_value weekday = mrbc_integer_value(result[3]);
                  mrbc_array_set(&array, 0, &year);
                  mrbc_array_set(&array, 1, &month);
                  mrbc_array_set(&array, 2, &date);
                  mrbc_array_set(&array, 3, &weekday);
                  SET_RETURN(array);
                } else {
                  SET_NIL_RETURN();
                }
              }
            C
          }
        },

        "rtc_class::getdatetime" => {
          action: :custom,
          cpp_wrapper: lambda { |_method|
            <<~CPP
              extern "C" int m5unified_rtc_class_getdatetime_array(int16_t* result) {
                rtc_datetime_t dt = M5.Rtc.getDateTime();
                result[0] = dt.date.year;
                result[1] = dt.date.month;
                result[2] = dt.date.date;
                result[3] = dt.date.weekDay;
                result[4] = dt.time.hours;
                result[5] = dt.time.minutes;
                result[6] = dt.time.seconds;
                return 7;
              }
            CPP
          },
          c_binding: lambda { |_method|
            <<~C
              static void mrbc_m5_getdatetime_0(mrbc_vm *vm, mrbc_value *v, int argc) {
                int16_t result[7];
                if (m5unified_rtc_class_getdatetime_array(result)) {
                  mrbc_value array = mrbc_array_new(vm, 7);
                  mrbc_value year = mrbc_integer_value(result[0]);
                  mrbc_value month = mrbc_integer_value(result[1]);
                  mrbc_value date = mrbc_integer_value(result[2]);
                  mrbc_value weekday = mrbc_integer_value(result[3]);
                  mrbc_value hours = mrbc_integer_value(result[4]);
                  mrbc_value minutes = mrbc_integer_value(result[5]);
                  mrbc_value seconds = mrbc_integer_value(result[6]);
                  mrbc_array_set(&array, 0, &year);
                  mrbc_array_set(&array, 1, &month);
                  mrbc_array_set(&array, 2, &date);
                  mrbc_array_set(&array, 3, &weekday);
                  mrbc_array_set(&array, 4, &hours);
                  mrbc_array_set(&array, 5, &minutes);
                  mrbc_array_set(&array, 6, &seconds);
                  SET_RETURN(array);
                } else {
                  SET_NIL_RETURN();
                }
              }
            C
          }
        },

        # Add more overrides as needed...
        # See PATH_TO_100_PERCENT.md for complete roadmap
      }
    end
  end
end
