# frozen_string_literal: true

module Picotorokko
  # Applies Mrbgemfile definitions to build_config files
  # Parses Mrbgemfile and updates all build_config/*.rb files with gem definitions
  # @rbs < Object
  class MrbgemfileApplier
    # Apply Mrbgemfile to build configuration
    # @rbs (String, String) -> void
    def self.apply(mrbgemfile_content, r2p2_path)
      new(mrbgemfile_content, r2p2_path).apply
    end

    # @rbs (String, String) -> void
    def initialize(mrbgemfile_content, r2p2_path)
      @mrbgemfile_content = mrbgemfile_content
      @r2p2_path = r2p2_path
    end

    # @rbs () -> void
    def apply
      build_config_dir = File.join(@r2p2_path, "build_config")
      return unless Dir.exist?(build_config_dir)

      Dir.glob(File.join(build_config_dir, "*.rb")).each do |config_file|
        apply_to_config(config_file)
      end

      puts "  ✓ Applied Mrbgemfile to R2P2-ESP32/build_config/"
    end

    private

    # @rbs (String) -> void
    def apply_to_config(config_file)
      config_name = File.basename(config_file, ".rb")
      dsl = MrbgemsDSL.new(@mrbgemfile_content, config_name)
      gems = dsl.gems

      return if gems.empty?

      content = File.read(config_file)
      modified = BuildConfigApplier.apply(content, gems)
      File.write(config_file, modified)
    end
  end
end
