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

end
