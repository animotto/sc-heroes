# frozen_string_literal: true

require 'json'
require 'base64'

module RETools
  ##
  # File dump
  class FileDump
    attr_reader :path

    def initialize(path)
      @path = path
      @data = {}
    end

    def read
      @data = JSON.parse(File.read(@path))
    end

    def write
      File.write(@path, JSON.generate(@data))
    end

    def datetime
      Time.at(@data['datetime'])
    end

    def datetime(datetime)
      @data['datetime'] = Time.at(datetime).to_i
    end

    def datetime_now
      @data['datetime'] = Time.now.to_i
    end

    def name
      @data['name']
    end

    def name=(name)
      @data['name'] = name
    end

    def description
      @data['description']
    end

    def description=(description)
      @data['description'] = description
    end

    def data
      Base64.decode64(@data['data'])
    end

    def data=(data)
      @data['data'] = Base64.encode64(data)
    end
  end
end
