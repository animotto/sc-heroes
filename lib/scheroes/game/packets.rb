# frozen_string_literal: true

require 'json'

module SCHeroes
  module Game
    ##
    # Data packet
    class DataPacket
      def initialize(data = nil)
        @buffer = data.nil? ? StringIO.new : StringIO.new(data)
      end

      def read_byte
        @buffer.read(1).unpack1('C')
      end

      def read_bytes(n)
        @buffer.read(n).unpack('C*')
      end

      def read_short
        @buffer.read(2).unpack1('S<')
      end

      def read_long
        @buffer.read(4).unpack1('L<')
      end

      def read_string
        type = read_byte
        size = (type >> 7) == 1 || (type >> 1) & 0x01 == 1 ? read_short : read_byte
        size -= 3
        raise DataPacketSerializationError.new(@buffer.string) if size.negative?

        string = @buffer.read(size).unpack1('a*')
        read_bytes(3)
        string.force_encoding('UTF-16LE')
      end

      def read_string2
        type = read_byte
        size = (type >> 7) == 1 || (type >> 1) & 0x01 == 1 ? read_short : read_byte
        size -= 3
        raise DataPacketSerializationError.new(@buffer.string) if size.negative?

        string = @buffer.read(size).unpack1('a*')
        read_bytes(2)
        string.force_encoding('UTF-16LE')
      end

      def read_string3
        type = read_byte
        size = (type >> 7) == 1 || (type >> 1) & 0x01 == 1 ? read_short : read_byte
        size -= 3
        raise DataPacketSerializationError.new(@buffer.string) if size.negative?

        string = @buffer.read(size).unpack1('a*')
        read_bytes(1)
        string.force_encoding('UTF-16LE')
      end

      def read_string4
        type = read_byte
        size = (type >> 7) == 1 || (type >> 1) & 0x01 == 1 ? read_short : read_byte
        size -= 4
        raise DataPacketSerializationError.new(@buffer.string) if size.negative?

        string = @buffer.read(size).unpack1('a*')
        read_bytes(3)
        string.force_encoding('UTF-16LE')
      end

      def write_byte(byte)
        @buffer.write([byte].pack('C'))
      end

      def write_bytes(bytes)
        @buffer.write(bytes.pack('C*'))
      end

      def write_long(value)
        @buffer.write([value].pack('L<'))
      end

      def write_string(string)
        write_byte(string.bytesize)
        @buffer.write([string].pack('a*'))
      end

      def flush
        @buffer.truncate(0)
        @buffer.rewind
      end

      def buffer
        @buffer.string
      end

      def to_s
        buffer
      end

      def size
        @buffer.size
      end
    end

    ##
    # Request packet
    class RequestPacket < DataPacket
      attr_accessor :version, :uid

      def serialize; end

      def pack
        serialize
        @tail = DataPacket.new
        @tail.write_long(@uid)
        @tail.write_string(@version)
        @buffer.write(@tail.to_s)
        @buffer.string
      end

      def dl
        @buffer.size - @tail.size - 1
      end
    end

    ##
    # Response packet
    class ResponsePacket < DataPacket
      def deserialize; end

      def unpack
        deserialize
        self
      end
    end

    ##
    # Server time request
    class ServerTimeRequest < RequestPacket
      def serialize
        write_byte(0x00)
      end
    end

    ##
    # Server time response
    class ServerTimeResponse < ResponsePacket
      attr_reader :unknown, :time

      def deserialize
        @unknown = read_bytes(3) # Unknown
        @time = Time.at(read_long)
      end
    end

    ##
    # Auth request
    class AuthRequest < RequestPacket
      def serialize
        write_bytes([0x06, 0x00, 0x00, 0x00, 0x01, 0x01, 0x03])
        write_long(@uid)
      end
    end

    ##
    # Auth response
    class AuthResponse < ResponsePacket
      attr_reader :header, :game_server, :chat_server,
      :privacy_policy_url, :support_request_en_url, :support_request_ru_url,
      :fourth_code_piece, :support_request_en_dup_url, :support_request_ru_dup_url,
      :code1, :code2, :code3, :teletype_ru_url, :teletype_en_url, :special_offer,
      :claim_en, :claim_de, :claim_pl, :offer_tiers, :offer_tiers_numbers,
      :shopping_google_play, :official_shop, :teletype_en_dup1_url, :teletype_en_dup2_url,
      :json,
      :unknown_block1, :unknown_block2, :unknown_block3, :unknown_block4,
      :unknown_block5, :unknown_block6, :unknown_block7, :unknown_block8,
      :unknown_block9, :unknown_block10, :unknown_block11, :unknown_block12,
      :unknown_block13, :unknown_block14, :unknown_block15

      def deserialize
        @header = read_bytes(6)
        size = read_byte
        @unknown_block1 = read_bytes(size) # Unknown

        @game_server = read_string
        @chat_server = read_string

        @unknown_block2 = read_bytes(42) # Unknown
        @privacy_policy_url = read_string

        @unknown_block3 = read_bytes(35) # Unknown
        @support_request_en_url = read_string2
        @support_request_ru_url = read_string2

        @unknown_block4 = read_bytes(53) # Unknown
        @fourth_code_piece = read_string

        @unknown_block5 = read_bytes(28) # Unknown
        @support_request_en_dup_url = read_string3
        @support_request_ru_dup_url = read_string2

        @code1 = read_string

        @unknown_block6 = read_bytes(9) # Unknown
        @teletype_ru_url = read_string
        @teletype_en_url = read_string

        @unknown_block7 = read_bytes(62) # Unknown
        @special_offer = read_string

        @unknown_block8 = read_bytes(30) # Unknown
        @claim_en = read_string

        @unknown_block9 = read_bytes(22) # Unknown
        @claim_de = read_string2

        @claim_pl = read_string

        @unknown_block10 = read_bytes(3) # Unknown
        @offer_tiers = read_string

        @offer_tiers_numbers = read_string2

        @code2 = read_string

        @unknown_block11 = read_bytes(123) # Unknown
        @shopping_google_play = read_string2

        @unknown_block12 = read_bytes(30) # Unknown
        @official_shop = read_string

        @unknown_block13 = read_bytes(10) # Unknown
        @teletype_en_dup1_url = read_string2
        @teletype_en_dup2_url = read_string2

        @unknown_block14 = read_bytes(4) # Unknown
        @code3 = read_string

        @unknown_block15 = read_bytes(8) # Unknown
        @json = read_string4
        @json = JSON.parse(@json)
      end
    end

    ##
    # Auth challenge request
    class AuthChallengeRequest < RequestPacket
      def serialize
        write_bytes([0x06, 0x00, 0x00, 0x00, 0x01, 0x01, 0x03])
      end
    end

    ##
    # Auth challenge response
    class AuthChallengeResponse < ResponsePacket
      def deserialize
      end
    end

    ##
    # Data packet serialization error
    class DataPacketSerializationError < StandardError
      attr_reader :data

      def initialize(data)
        super

        @data = data
      end

      def to_s
        "Size #{@data.bytesize} bytes"
      end
    end
  end
end
