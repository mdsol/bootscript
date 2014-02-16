module Bootscript
  require 'open3'

  # a utility class for testing BootScripts
  # only suitable for BootScripts that fit in memory!
  class Unpacker

    attr_reader :config, :text, :command

    @text # the actual text of the rendered BootScript

    def initialize(script_text)
      @text = script_text
      @config = Hash.new
      parse
    end

    def parse
      # try to grab Bash config statements from the text of the script
      @text.each_line do |line|
        break if line =~ /\A__ARCHIVE_FOLLOWS__/
        if matches = line.match(%r{(\w+)=(.*)})
          key, value = matches[1],  matches[2]
          value.gsub!(/\A['"]+|['"]+\Z/, "")  # strip quotes
          @config[key] = value
        end
      end
    end

    # extracts the contents of the BootScript's archive into dir
    def unpack_to(dir)
      Open3.popen3('uudecode -o /dev/stdout | tar xz', chdir: dir) do
        |stdin, stdout, stderr, thread|
          stdin.write @text
          stderr.read   # (why is this is needed for successfull unpacking?)
      end
    end
  end

end
