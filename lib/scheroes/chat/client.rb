# frozen_string_literal: true

require 'socket'
require 'stringio'

module SCHeroes
  module Chat
    ##
    # Chat client
    class Client
      HOST = 'game.star-thunder.com'
      PORT = 2001

      LANGUAGE_RU = 'ru'
      LANGUAGE_EN = 'en'
      LANGUAGE_DE = 'de'
      LANGUAGE_FR = 'fr'
      LANGUAGE_PL = 'pl'
      LANGUAGE_UA = 'ua'

      VERSION = 1

      UPDATE_STATUS_INTERVAL = 60

      attr_reader :host, :port

      def initialize(host = HOST, port = PORT)
        @host = host
        @port = port
        @online_users = 0
      end

      ##
      # Opens a connection to the chat server
      def open
        @socket = TCPSocket.new(@host, @port)
      end

      ##
      # Closes connection to chat server
      def close
        @socket.close
      end

      ##
      # Returns true if the connection is closed
      def closed?
        @socket&.closed?
      end

      ##
      # Joins a chat by specified language
      def join(uid, language)
        packet = JoinPacket.new(@socket)
        packet.version = VERSION
        packet.uid = uid
        packet.language = language
        packet.write
      end

      ##
      # Joins the clan chat
      def join_clan(cid)
        packet = JoinClanPacket.new(@socket)
        packet.cid = cid
        packet.write
      end

      ##
      # Changes language
      def change_language(uid, language)
        packet = ChangeLanguagePacket.new(@socket)
        packet.version = VERSION
        packet.uid = uid
        packet.language = language
        packet.write
      end

      ##
      # Sends a message to the chat server
      def say(text)
        packet = MessagePacket.new(@socket)
        packet.text = text
        packet.write
      end

      ##
      # Sends a clan message to the chat server
      def clan_say(text)
        packet = ClanMessagePacket.new(@socket)
        packet.text = text
        packet.write
      end

      ##
      # Updates server status
      def update_status
        packet = StatusRequestPacket.new(@socket)
        packet.write
      end

      ##
      # Reads data and processes packets from the chat server
      # Returns an array of messages
      def read
        update_status_time = Time.now
        loop do
          socket_ready = @socket.wait_readable(1)
          unless socket_ready
            if Time.now - update_status_time >= UPDATE_STATUS_INTERVAL 
              update_status
              update_status_time = Time.now
            end
            next
          end

          packet = DataPacket.packet_id(@socket).new(@socket)
          packet.read

          case packet
            when MessagePacket, ClanMessagePacket
              return packet.message unless block_given?

              yield(packet.message)

            when AuthRequestPacket
              # TODO: we need to send a response for authentication
              @auth_request_key = packet.key

            when StatusResponsePacket
              @online_users = packet.online_users
          end
        end
      end
    end
  end
end
