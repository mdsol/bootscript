module Bootscript

  require 'fileutils'
  require 'erubis'
  require 'json'
  require 'tmpdir'
  require 'zlib'
  require 'archive/tar/minitar'
  require 'zip'

  # Main functional class. Models and builds a self-extracting Bash/TAR file.
  class Script

    # A Hash of data sources to be written onto the boot target's filesystem.
    # Each (String) key is a path to the desired file on the boot target.
    # Each value can be a String (treated as ERB), or Object with a read method.
    # Any Ruby File objects with extension ".ERB" are also processed as ERB.
    attr_accessor :data_map

    # Standard Ruby Logger, overridden by passing :logger to {#initialize}
    attr_reader   :log

    # constructor - configures the AWS S3 connection and logging
    # @param logger [::Logger] - a standard Ruby logger
    def initialize(logger = nil)
      @log      ||= logger || Bootscript.default_logger
      @data_map = Hash.new
      @vars     = Hash.new
    end

    # Generates the BootScript contents by interpreting the @data_map
    # based on erb_vars. If destination has a write() method,
    # the data is streamed there line-by-line, and the number of bytes written
    # is returned. Otherwise, the BootScript contents are returned as a String.
    # In the case of streaming output, the destination must be already opened.
    # @param erb_vars [Hash] Ruby variables to interpolate into all templates
    # @param destination [IO] a Ruby object that responds to write(String)
    # @return [Fixnum] the number of bytes written to the destination, or
    # @return [String] the text of the rendered script, if destination is nil
    def generate(erb_vars = {}, destination = nil)
      # Set state / instance variables, used by publish() and helper methods
      @vars          = Bootscript.merge_platform_defaults(erb_vars)
      output         = destination || StringIO.open(@script_data = "")
      @bytes_written = 0
      if Bootscript.windows?(@vars)
        @bytes_written += output.write(render_erb_text(File.read(
          "#{File.dirname(__FILE__)}/../templates/windows_header.ps1.erb"
        )))
      end
      write_bootscript(output)          # streams the script part line-by-line
      write_uuencoded_archive(output)   # streams the archive line-by-line
      if Bootscript.windows?(@vars)
        @bytes_written += output.write(render_erb_text(File.read(
          "#{File.dirname(__FILE__)}/../templates/windows_footer.ps1.erb"
        )))
      end
      output.close unless destination   # (close StringIO if it was opened)
      return (destination ? @bytes_written : @script_data)
    end

    private

    # Streams the bootscript to destination and updates @bytes_written
    def write_bootscript(destination)
      # If streaming, send the top-level script line-by-line from memory
      if Bootscript.windows?(@vars)
        template_path = Bootscript::WINDOWS_TEMPLATE
      else
        template_path = Bootscript::UNIX_TEMPLATE
      end
      template = File.read(template_path)
      template = strip_shell_comments(template) if @vars[:strip_comments]
      @log.debug "Rendering boot script to #{destination}..."
      render_erb_text(template).each_line do |ln|
        destination.write ln
        @bytes_written += ln.bytes.count
      end
    end

    # Streams the uuencoded archive to destination, updating @bytes_written
    def write_uuencoded_archive(destination)
      @log.debug "Writing #{@vars[:platform]} archive to #{destination}..."
      if Bootscript.windows?(@vars)
        @bytes_written += destination.write("$archive = @'\n")
        write_windows_archive(destination)
        @bytes_written += destination.write("'@\n")
      else  # :platform = 'unix'
        @bytes_written += destination.write("begin-base64 0600 bootstrap.tbz\n")
        write_unix_archive(destination)
        @bytes_written += destination.write("====\n") # (base64 footer)
      end
    end

    # Streams a uuencoded TGZ archive to destination, updating @bytes_written
    def write_unix_archive(destination)
      begin
        uuencode  = UUWriter.new(destination)
        gz        = Zlib::GzipWriter.new(uuencode)
        tar       = Archive::Tar::Minitar::Writer.open(gz)
        render_data_map_into(tar)
      ensure
        tar.close
        gz.close
        @bytes_written += uuencode.bytes_written
      end
    end

    # Streams a uuencoded ZIP archive to destination, updating @bytes_written
    def write_windows_archive(destination)
      Dir.mktmpdir do |dir|
        zip_path = "#{dir}/archive.zip"
        zipfile = File.open(zip_path, 'wb')
        Zip::OutputStream.open(zipfile) {|zip| render_data_map_into(zip)}
        zipfile.close
        @log.debug "zipfile = #{zip_path}, length = #{File.size zip_path}"
        File.open(zip_path, 'rb') do |zipfile|
          @bytes_written += destination.write([zipfile.read].pack 'm')
        end
      end
    end

    # renders each data map item into an 'archive', which must be either an
    # Archive::Tar::Minitar::Writer (if unix), or a Zip::OutputStream (windows)
    def render_data_map_into(archive)
      full_data_map.each do |remote_path, item|
        if item.is_a?(String)           # case 1: data item is a String
          @log.debug "Rendering ERB data (#{item[0..16]}...) into archive"
          data  = render_erb_text(item)
          input = StringIO.open(data, 'r')
          size  = data.bytes.count
        elsif item.is_a?(File)          # case 2: data item is an ERB file
          if item.path.upcase.end_with?('.ERB')
            @log.debug "Rendering ERB file #{item.path} into archive"
            data  = render_erb_text(item.read)
            input = StringIO.open(data, 'r')
            size  = data.bytes.count
          else                          # case 3: data item is a regular File
            @log.debug "Copying data from #{item.inspect} into archive"
            input = item
            size  = File.stat(item).size
          end
        else                            # case 4: Error
          raise ArgumentError.new("cannot process item: #{item}")
        end
        if Bootscript.windows?(@vars)
          archive.put_next_entry remote_path
          archive.write input.read
        else
          opts = {mode: 0600, size: size, mtime: Time.now}
          archive.add_file_simple(remote_path, opts) do |output|
            while data = input.read(512) ; output.write data end
          end
        end
      end
    end

    # merges the @data_map with the Chef and/or Ansible built-ins, as-needed
    def full_data_map
      ansible_vars = Ansible.included?(@vars) ? Ansible.files(@vars) : {}
      chef_vars = Chef.included?(@vars) ? Chef.files(@vars) : {}
      @data_map.merge(ansible_vars).merge(chef_vars) # Chef wins collisions.
    end

    # renders erb_text, using @vars
    def render_erb_text(erb_text)
      Erubis::Eruby.new(erb_text).result(@vars)
    end

    # strips all empty lines and lines beginning with # from text
    # does NOT touch the first line of text
    def strip_shell_comments(text)
      lines = text.lines.to_a
      return text if lines.count < 2
      lines.first + lines.drop(1).
        reject { |l| (l =~ /^\s*#/) || (l =~ /^\s+$/) }.join('')
    end
  end

end
