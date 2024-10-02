require 'net/http/persistent'

module VisualCrossing
  class Http
    delegate :payload_gsub, :rest_uri_base, :http_persist, to: :class

    def self.http_persist
      @http_persist ||= Net::HTTP::Persistent.new(name: 'VisualCrossingWeather')
    end

    def self.api_key
      @api_key ||= "5M3PTGAJSEJM247DA4NZ4QADX"
    end

    def self.payload_gsub
      @payload_sub ||= "PAYLOAD_GSUB"
    end

    def self.rest_uri_base
      @rest_uri_base ||= "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/#{payload_gsub}?key=#{api_key}"
    end

    def self.uri(payload)
      rest_uri_base.gsub(payload_gsub, payload)
    end

    attr_reader :date_begin_on, :date_end_on, :location

    # location => the Address Form input String used as location
    # note: location should be CGI.escaped
    def initialize(location:, begin_on: Date.current, end_on: nil)
      # Future may want to expand our date range from user
      #   Now just get one day's worth
      @location = location
      @date_begin_on = begin_on
      @date_end_on = end_on || begin_on
    end

    # memoize the actual uri we generate
    # example:
    # uri => https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline
    #   /Tamp%2C+FL/2024-09-29/2024-09-29?key=5M3PTGAJSEJM247DA4NZ4QADX
    def uri
      @uri ||= self.class.uri(payload)
    end

    def weather_body_json
      response = http_persist.request(uri)
      response.body
    end

    # TODO: sign up for access to get zip code
    def uri_zip_code
      l = CGI.unescape(location)
      city = l.split(",").first.strip
      state = l.split(",").last.strip
      "https://api.usps.com/addresses/v3/address/city/#{city}/state/#{state}"
    end

    def zip_code
      response = http_persist.request(uri_zip_code)
      response.body
    end

    private

    def payload
      @payload ||= "#{location}/#{date_begin_on}/#{date_end_on}"
    end
  end
end