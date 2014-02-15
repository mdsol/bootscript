require 'bootscript'

describe Bootscript do
  describe :DEFAULT_VARS do
    it "provides some sane default template variables" do
      [ :platform, :startup_command,
        :create_ramdisk, :ramdisk_size, :ramdisk_mount,
        :add_script_tags
      ].each do |required_var|
        Bootscript::DEFAULT_VARS.should include(required_var)
        Bootscript::DEFAULT_VARS[required_var].should_not be nil
      end
    end
  end

  describe :default_logger do
    context "with no arguments" do
      it "returns a Ruby Logger with LOG_LEVEL set to FATAL" do
        logger = Bootscript.default_logger
        logger.level.should be Logger::FATAL
      end
    end
    context "with a specific log level" do
      [Logger::DEBUG, Logger::INFO, Logger::WARN].each do |log_level|
        it "returns a standard Ruby Logger with level #{log_level}" do
          logger = Bootscript.default_logger(STDOUT, log_level)
          logger.level.should be log_level
        end
      end
    end
  end
end
