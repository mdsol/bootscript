require 'bootscript'
require 'logger'    # for testing logging functionality
require 'tmpdir'    # for unpacking Script archives
include Bootscript # for brevity

describe Script do

  #### TEST SETUP
  before :each do
    @script = Script.new()
  end

  #### TEST PUBLIC INSTANCE MEMBER VARIABLES

  it "has a public @data_map Hash, for mapping local data to the boot target" do
    expect(Script.new()).to respond_to(:data_map)
    expect(Script.new().data_map).to be_a Hash
  end

  it "exposes a Ruby Logger as its public @log member, to adjust log level" do
    expect(Script.new()).to respond_to(:log)
    expect(Script.new().log).to be_a Logger
  end

  #### TEST PUBLIC METHODS

  describe :initialize do
    context "when invoked with a logger" do
      it "sets the BootScript's @log to the passed Logger object" do
        my_logger = Logger.new(STDOUT)
        expect(Script.new(my_logger).log).to be my_logger
      end
    end
    context "when invoked with no logger" do
      it "assigns a default Logger the BootScript's @log" do
        expect(Script.new().log).to be_a Logger
      end
    end
  end

  describe :generate do
    # test arguments / arity
    it "accepts an (optional) Hash of template vars" do
      expect{@script.generate}.to_not raise_error
      expect{@script.generate({some_key: :some_value})}.to_not raise_error
    end
    it "accepts an (optional) destination for the generated text" do
      File.open('/dev/null', 'w') do |outfile|  # write to nowhere!
        expect{@script.generate({}, outfile)}.to_not raise_error
      end
    end
    # test output format
    it "produces a Bash script" do
      expect(@script.generate.lines.first.chomp).to eq '#!/usr/bin/env bash'
    end
    # test stripping of empty lines and comments
    context "when invoked with :strip_comments = true (the default)" do
      it "strips all empty lines and comments from the output" do
        lines = @script.generate.lines.to_a
        lines[1..lines.count].each do |line|
          expect(line).to_not match /^#/
          expect(line).to_not match /^\s+$/
        end
      end
    end
    context "when invoked with :strip_comments = false" do
      it "leaves empty lines and comments in the output" do
        lines = @script.generate(strip_comments: false).lines.to_a
        expect(lines.select{|l| l =~ /^\s+$/}).to_not be_empty  # check empty lines
        expect(lines.select{|l| l =~ /^#/}.size).to be > 1      # check comments
      end
    end

    # test rendering of built-in variables into built-in templates
    vars = {create_ramdisk: false, ramdisk_size: 5,
      ramdisk_mount: '/secrets', update_os: false}
    vars.keys.each do |var|
      it "renders template variable :#{var} as Bash variable #{var.upcase}" do
        rendered_config = Unpacker.new(Script.new.generate(vars)).config
        expect(vars[var].to_s).to eq rendered_config[var.upcase.to_s]
      end
    end
    # test rendering of custom templates
    it "renders custom templates into place with correct ERB values" do
      @script.data_map = {'/hello.sh' => 'echo Hello, <%= my_name %>.'}
      text = @script.generate(my_name: 'H. L. Mencken')
      Dir.mktmpdir do |tmp_dir| # do unarchiving in a temp dir
        Unpacker.new(text).unpack_to tmp_dir
        expect(File.exists?("#{tmp_dir}/hello.sh")).to eq(true)
        expect(File.read("#{tmp_dir}/hello.sh")).to eq 'echo Hello, H. L. Mencken.'
      end
    end
    # test raw file copying
    it "copies non-template files directly into the generated archive" do
      # insert this test file itself into the BootScript's archive!    :-/
      @script.data_map = {File.basename(__FILE__) => File.new(__FILE__)}
      Dir.mktmpdir do |tmp_dir| # do unarchiving in a temp dir
        target_file = "#{tmp_dir}/#{File.basename(__FILE__)}"
        Unpacker.new(@script.generate).unpack_to tmp_dir
        expect(File.exists?(target_file)).to eq(true)
        expect(File.read(target_file)).to eq File.read(__FILE__)
      end
    end
    # test return values
    context "when invoked without any output destination" do
      it "returns the rendered text of the BootScript" do
        rendered_text = @script.generate
        expect(rendered_text).to be_a String
        expect(rendered_text.lines.first.chomp).to eq '#!/usr/bin/env bash'
        expect(rendered_text.lines).to include("__ARCHIVE_FOLLOWS__\n")
      end
    end
    context "when invoked with a custom output destination" do
      it "returns the number of bytes written to the destination" do
        bytes_written, script_size = 0, @script.generate.bytes.count
        File.open('/dev/null', 'w') do |outfile|
          bytes_written = @script.generate({}, outfile)
        end
        expect(bytes_written).to be_a Fixnum
        expect(bytes_written).to eq(script_size)
      end
    end

  end

end
