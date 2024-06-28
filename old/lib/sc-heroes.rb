require "socket"

module SCHeroes
  class Chat
    OPCODE_JOIN      = 0x01
    OPCODE_SAY       = 0x03
    OPCODE_END       = 0x06
    OPCODE_CHANGE    = 0x07
    OPCODE_PING      = 0x0a
    OPCODE_CLAN_JOIN = 0x0b
    OPCODE_CLAN_SAY  = 0x0c
    
    def initialize(options)
      @client = TCPSocket.new(options[:address], options[:port])
    end

    def join(options)
      data =
        [
          OPCODE_JOIN,
          options[:version],
          options[:uid],
        ].pack("CL<2").force_encoding("utf-8") +
        varint_encode(options[:name].bytesize) +
        options[:name] +
        [options[:title].to_i].pack("L<").force_encoding("utf-8") +
        varint_encode(options[:info].bytesize) +
        options[:info] +
        varint_encode(options[:country].bytesize) +
        options[:country]
      @client.write(data)
    end

    def join_clan(options)
      data = [
        OPCODE_CLAN_JOIN,
        options[:clan]
      ].pack("CL<")
      @client.write(data)
    end
    
    def change(options)
      data =
        [
          OPCODE_CHANGE,
          options[:version],
          options[:uid],
        ].pack("CL<2").force_encoding("utf-8") +
        varint_encode(options[:name].bytesize) +
        options[:name] +
        [options[:title].to_i].pack("L<").force_encoding("utf-8") +
        varint_encode(options[:info].bytesize) +
        options[:info] +
        varint_encode(options[:country].bytesize) +
        options[:country] +
        # Unknown bytes
        "\x00\x00\x00\x00"
      @client.write(data)
    end
    
    def read
      messages = Array.new
      loop do
        opcode = @client.read(1).unpack("C").first
        case opcode
        when OPCODE_SAY, OPCODE_CLAN_SAY
          message = Hash.new
          message[:clan] = true if opcode == OPCODE_CLAN_SAY
          message[:uid] = @client.read(4).unpack("L<").first
          message[:name_size] = varint_decode()
          message[:name] = @client.read(message[:name_size])
          message[:title] = @client.read(4).unpack("L<").first
          message[:info_size] = varint_decode()
          message[:info] = @client.read(message[:info_size])
          message[:message_size] = varint_decode()
          message[:message] = @client.read(message[:message_size])
          message[:timestamp] = @client.read(4).unpack("L<").first
          yield(message) if block_given?
          messages.push(message)
        when OPCODE_END
          @client.read(9)
          return messages
        when OPCODE_PING
          return messages
        end
      end
    end
    
    def say(message)
      data = [OPCODE_SAY].pack("C")
      data += varint_encode(message.bytesize)
      data += message.force_encoding("utf-8")
      @client.write(data)
    end

    def varint_encode(value)
      data = String.new
      loop do
        byte = value & 0x7f
        value >>= 7
        if value == 0
          data += [byte].pack("C")
          break
        else
          data += [(byte | 0x80)].pack("C")
        end
      end
      return data
    end
    
    def varint_decode
      value = 0
      shift = 0
      loop do
        byte = @client.read(1).unpack("C").first
        value |= (byte & 0x7f) << shift
        shift += 7
        return value if (byte & 0x80) == 0
      end
    end
  end
end
