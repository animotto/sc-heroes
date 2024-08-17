# frozen_string_literal: true

module SCHeroes
  module Chat
    MESSAGE_STRUCT = Struct.new(
      :time, :uid, :info, :title,
      :name, :text, :clan
    )

    ##
    # Data packet
    class DataPacket
      def self.packet_id(socket)
        id = socket.read(1).unpack1('C')
        packet = subclasses.detect { |s| s::ID == id }
        raise UnknownPacketError.new(id) unless packet

        packet
      end

      def initialize(socket)
        @socket = socket
        @buffer = StringIO.new
      end

      def read; end

      def write; end

      private

      ##
      # Reads one byte from the socket
      def read_byte
        @socket.read(1).unpack1('C')
      end

      ##
      # Reads n bytes from the socket
      def read_bytes(n)
        @socket.read(n).bytes
      end

      ##
      # Reads four bytes from the socket
      def read_long
        @socket.read(4).unpack1('L<')
      end

      ##
      # Reads string from the socket
      def read_string
        size = read_varint
        @socket.read(size)
      end

      ##
      # Reads variable integer from the socket
      def read_varint
        varint = 0
        shift = 0
        loop do
          byte = read_byte
          varint |= (byte & 0x7f) << shift
          shift += 7
          break if byte & 0x80 == 0
        end

        varint
      end

      ##
      # Writes one byte to the socket
      def write_byte(data)
        @buffer.write([data].pack('C'))
      end

      ##
      # Write bytes to the socket
      def write_bytes(bytes)
        @buffer.write(bytes.pack('C*'))
      end

      ##
      # Writes four bytes to the socket
      def write_long(data)
        @buffer.write([data].pack('L<'))
      end

      ##
      # Writes a string to the socket
      def write_string(data)
        write_varint(data.bytesize)
        @buffer.write(data)
      end

      ##
      # Writes an integer as variable integer to the socket
      def write_varint(int)
        loop do
          byte = int & 0x7f
          int >>= 7
          if int == 0
            write_byte(byte)
            break
          end

          write_byte(byte | 0x80)
        end
      end

      ##
      # Writes and flushes the buffer to the socket
      def flush
        @socket.write(@buffer.string)
        @buffer.truncate(0)
        @buffer.rewind
      end
    end

    ##
    # Join packet
    class JoinPacket < DataPacket
      ID = 0x01

      attr_accessor :version, :uid, :language

      def write
        write_byte(ID)
        write_long(@version)
        write_long(@uid)
        write_string(@language)
        flush
      end
    end

    ##
    # Join clan packet
    class JoinClanPacket < DataPacket
      ID = 0x0b

      attr_accessor :cid

      def write
        write_byte(ID)
        write_long(cid)
        flush
      end
    end

    ##
    # Message packet
    class MessagePacket < DataPacket
      ID = 0x03

      attr_reader :message
      attr_accessor :text

      def read
        @message = MESSAGE_STRUCT.new

        @message.uid = read_long
        @message.name = read_string
        @message.title = read_long
        @message.info = read_string
        @message.text = read_string
        @message.time = Time.at(read_long)

        @message
      end

      def write
        write_byte(ID)
        write_string(text)
        flush
      end
    end

    ##
    # Clan message packet
    class ClanMessagePacket < DataPacket
      ID = 0x0c

      attr_reader :message
      attr_accessor :text

      def read
        @message = MESSAGE_STRUCT.new

        @message.uid = read_long
        @message.name = read_string
        @message.title = read_long
        @message.info = read_string
        @message.text = read_string
        @message.time = Time.at(read_long)
        @message.clan = true

        @message
      end

      def write
        write_byte(ID)
        write_string(text)
        flush
      end
    end

    ##
    # Status response packet
    class StatusResponsePacket < DataPacket
      ID = 0x06

      attr_reader :online_users

      def read
        read_long # Unknown
        read_byte # Unknown (usually 0x09?)
        @online_users = read_long
      end
    end

    ##
    # Status request packet
    class StatusRequestPacket < DataPacket
      ID = 0x08

      def write
        write_byte(ID)
        flush
      end
    end

    ##
    # Change language packet
    class ChangeLanguagePacket < DataPacket
      ID = 0x07

      attr_accessor :version, :uid, :language

      def write
        write_byte(ID)
        write_long(@version)
        write_long(@uid)
        write_string(@language)
        write_long(0) # Unknown
        flush
      end
    end
    
    ##
    # Auth request packet
    class AuthRequestPacket < DataPacket
      ID = 0x0e

      attr_reader :key

      def read
        size = read_long
        @key = read_bytes(size)
      end
    end

    ##
    # Auth response packet
    class AuthResponsePacket < DataPacket
      ID = 0x0f

      attr_accessor :key

      def write
        write_byte(ID)
        write_long(@key.size)
        write_bytes(@key)
        flush
      end
    end

    ##
    # Unknown packet error
    class UnknownPacketError < StandardError
      attr_reader :id

      def initialize(id)
        super

        @id = id
      end

      def to_s
        "Unknown packet: 0x#{@id.to_s(16)}"
      end
    end
  end
end
