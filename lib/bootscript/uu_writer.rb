module Bootscript

  class UUWriter

    attr_reader :bytes_written

    def initialize(output)
      @output         = output
      @bytes_written  = 0
    end

    def write(data)
      @bytes_written += @output.write [data].pack('m')
    end
  end

end
