# frozen_string_literal: true

require_relative "m5libgen/version"
require_relative "m5libgen/repository_manager"
require_relative "m5libgen/header_reader"
require_relative "m5libgen/libclang_parser"
require_relative "m5libgen/type_mapper"

module M5LibGen
  class Error < StandardError; end
end
