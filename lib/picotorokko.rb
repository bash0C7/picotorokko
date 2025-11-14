require_relative "picotorokko/version"
require_relative "picotorokko/cli"
require_relative "picotorokko/template/engine"
require_relative "picotorokko/mrbgems_dsl"
require_relative "picotorokko/build_config_applier"

module Picotorokko
  class Error < StandardError; end
end
