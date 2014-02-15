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

  # determines whether Windows is the boot target for a given set of ERB vars
  describe :windows? do
    [:windows, :WinDows, 'windows', 'WINDOWS'].each do |value|
      context "its Hash argument has :platform => #{value} (#{value.class})" do
        it "returns true" do
          Bootscript.windows?(platform: value).should be true
        end
      end
    end
    [:unix, :OS_X, 'other', 'randomstring0940358'].each do |value|
      context "its Hash argument has :platform => #{value} (#{value.class})" do
        it "returns false" do
          Bootscript.windows?(platform: value).should be false
        end
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
