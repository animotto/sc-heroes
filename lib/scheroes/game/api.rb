# frozen_string_literal: true

require 'net/http'
require 'stringio'

module SCHeroes
  module Game
    ##
    # API
    class API
      attr_reader :uid, :http_client
      attr_reader :info_service, :auth_service

      VERSION = '1.7.82.30601'

      def initialize(uid)
        @uid = uid
        @http_client = HTTPClient.new
        @info_service = InfoService.new(self)
        @auth_service = AuthService.new(self)
      end

      def version
        VERSION
      end
    end

    ##
    # Hack for the case sensitive HTTP headers
    class StringNoDownCase < String
      def downcase
        self
      end
    end

    ##
    # HTTP client
    class HTTPClient
      HOST = 'game.star-thunder.com'
      PORT = 1337

      HEADERS = {
        'User-Agent' => 'BestHTTP/2 v2.5.2',
        StringNoDownCase.new('x-OS') => '2'
      }

      attr_reader :host, :port

      def initialize(host = HOST, port = PORT)
        @host = host
        @port = port
        @client = Net::HTTP.new(@host, @port)
      end

      def post(path, data = '', headers: {}, dl: nil)
        headers.merge!(HEADERS)
        headers[StringNoDownCase.new('x-DL')] = dl.to_s unless dl.nil?
        response = @client.post(path, data, initheader = headers)
        raise HTTPClientError.new(path) if response.body.empty?

        response.body
      end
    end

    ##
    # Base service
    class BaseService
      def initialize(api)
        @api = api
        @http_client = @api.http_client
      end
    end

    ##
    # Info service
    class InfoService < BaseService
      PATH = '/InfoService'

      def get_server_time
        request = ServerTimeRequest.new
        request.version = @api.version
        request.uid = 0xffffffff
        response = @http_client.post(PATH + '/GetServerTime', request.pack)
        response = ServerTimeResponse.new(response)
        response.unpack
      end
    end

    ##
    # Auth service
    class AuthService < BaseService
      PATH = '/AuthService'

      def auth_request
        request = AuthRequest.new
        request.version = @api.version
        request.uid = @api.uid
        request_data = request.pack
        response = @http_client.post(PATH + '/AuthRequest', request_data, dl: request.dl)
        response = AuthResponse.new(response)
        response.unpack
      end

      def auth_challenge_response
        request = AuthChallengeRequest.new
        request.version = @api.version
        request.uid = @api.uid
        request_data = request.pack
        response = @http_client.post(PATH + '/AuthChallangeResponse', request_data, dl: request.dl)
        response = AuthChallengeResponse.new(response)
        response.unpack
      end
    end

    ##
    # HTTP client error
    class HTTPClientError < StandardError
      def initialize(path)
        super

        @path = path
      end

      def to_s
        "#{self.class}: #{@path}"
      end
    end
  end
end

##
# Hack for the case sensitive HTTP headers
module Net::HTTPHeader
  def capitalize(name)
    name
  end

  private :capitalize
end
