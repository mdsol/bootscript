require 'bootscript'

describe Bootscript do
  describe :DEFAULT_VARS do
    it "provides some sane default template variables" do
      [ :platform, :startup_command,
        :create_ramdisk, :ramdisk_size, :ramdisk_mount,
        :add_script_tags, :inst_pkgs
      ].each do |required_var|
        expect(Bootscript::DEFAULT_VARS).to include(required_var)
        expect(Bootscript::DEFAULT_VARS[required_var]).to_not eq nil
      end
    end
  end

  describe :generate do
    before :each do
      @template_vars = {key1: :value1, key2: :value2}
      @data_map = {'/use/local/bin/hello.sh' => "echo Hello!\n"}
      @script = Bootscript::Script.new
    end
    it "accepts a Hash of template vars and a data map" do
      Bootscript.generate(@template_vars, @data_map)
    end
    it "creates a Script with the same data map" do
      allow(Bootscript::Script).to receive(:new).and_return @script
      expect(@script).to receive(:data_map=).with @data_map
      Bootscript.generate(@template_vars, @data_map)
    end
    it "calls generate() on the script, passing the same template vars" do
      allow(Bootscript::Script).to receive(:new).and_return @script
      expect(@script).to receive(:generate).with(@template_vars, nil)
      Bootscript.generate(@template_vars, @data_map)
    end
  end

  # determines whether Windows is the boot target for a given set of ERB vars
  describe :windows? do
    [:windows, :WinDoWs, 'windows', 'WINDOWS'].each do |value|
      context "its Hash argument has :platform => #{value} (#{value.class})" do
        it "returns true" do
          expect(Bootscript.windows?(platform: value)).to eq(true)
        end
      end
    end
    [:unix, :OS_X, 'other', 'randomstring0940358'].each do |value|
      context "its Hash argument has :platform => #{value} (#{value.class})" do
        it "returns false" do
          expect(Bootscript.windows?(platform: value)).to eq(false)
        end
      end
    end
  end

  describe :default_logger do
    context "with no arguments" do
      it "returns a Ruby Logger with LOG_LEVEL set to FATAL" do
        logger = Bootscript.default_logger
        expect(logger.level).to be Logger::FATAL
      end
    end
    context "with a specific log level" do
      [Logger::DEBUG, Logger::INFO, Logger::WARN].each do |log_level|
        it "returns a standard Ruby Logger with level #{log_level}" do
          logger = Bootscript.default_logger(STDOUT, log_level)
          expect(logger.level).to be log_level
        end
      end
    end
  end
end
