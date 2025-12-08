# frozen_string_literal: true

require_relative "m5libgen/version"
require_relative "m5libgen/repository_manager"
require_relative "m5libgen/header_reader"
require_relative "m5libgen/libclang_parser"
require_relative "m5libgen/type_mapper"
require_relative "m5libgen/api_pattern_detector"
require_relative "m5libgen/mrbgem_generator"
require_relative "m5libgen/cpp_wrapper_generator"
require_relative "m5libgen/cmake_generator"

module M5LibGen
  class Error < StandardError; end
end
