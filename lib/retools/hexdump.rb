# frozen_string_literal: true

require 'stringio'

module RETools
  ##
  # HexDump
  class HexDump
    LINE_SIZE = 16
    CHAR_DEFAULT = '.'

    def initialize
      @data = StringIO.new
    end

    def <<(data)
      @data.write(data)
    end

    def clear
      @data.truncate(0)
      @data.rewind
    end

    def size
      @data.size
    end

    def dump(offset = 0, n = nil)
      lines = []
      bytes = Array.new(LINE_SIZE)
      chars = []
      @data.seek(offset)
      i = 0
      loop do
        bytes[i] = @data.read(1).unpack1('C')
        unless bytes[i].nil?
          chars << (bytes[i].between?(0x21, 0x7e) ? bytes[i].chr : CHAR_DEFAULT)
        end

        i += 1
        stream_end = @data.eof? || (!n.nil? && @data.pos - offset >= n)
        if i == LINE_SIZE || stream_end
          line = String.new
          line << ::Kernel.format("%04x  ", @data.pos - i)
          line << bytes.map { |b| b.nil? ? '  ' : ::Kernel.format('%02x', b) }.join(' ')
          line << '  '
          line << chars.join('')
          lines << line
          bytes = Array.new(LINE_SIZE)
          chars.clear
          i = 0

          break if stream_end
        end
      end

      lines.join("\n")
    end
  end
end
