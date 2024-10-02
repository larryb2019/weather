# frozen_string_literal: true

module VisualCrossing
  # Wrapper for making an http request to the
  #   VisualCrossing API to get our current weather data
  class Request
    include SemanticLogger::Loggable

    attr_accessor :address
    attr_reader :body_hash, :body_json

    # callers:
    #   Address#current_weather_data
    # the current_weather_data cache has expired
    #   Call the Service for fresh weather data
    def self.on_current_weather_data(address)
      service = new(address)
      service.refresh_weather_data
      service.body_hash
    end

    def initialize(address)
      @address = address
      @body_json = ''
      @body_hash = {}
    end

    # Splunk metric: "VisualCrossing/Request/Refresh"
    def refresh_weather_data
      logger.measure_info("calling VisualCrossing for address#{address&.id}",
                          metric: to_metric('Refresh'),
                          criteria: { location: location }) do
        call_service
        address_cache_update
      end
    end

    private

    def to_metric(metric)
      "VisualCrossing/Request/#{metric}"
    end

    def address_on_new
      address.body = body_json
      address.generated_at = Time.current
      address.my_uri = http.uri
      address.resolved_as = @resolved_as
    end

    # using update_column so the addresses update_at key
    #   used in caching doesn't get reset
    # rubocop:disable Rails/SkipsModelValidations
    def address_on_update
      address.update_column(:body, body_json)
      address.update_column(:generated_at, Time.current)
      address.update_column(:resolved_as, @resolved_as)
    end
    # rubocop:enable Rails/SkipsModelValidations

    # use update_column so the cache key using
    #   updated_at is still valid
    def address_cache_update
      @resolved_as = body_hash['resolvedAddress'] || 'None'
      if address.new_record?
        address_on_new
      else
        address_on_update
      end
      return unless body_hash.key?('bad_request')

      # Save the record so the updated_at will
      #   expire the cache.
      address.save
    end

    # VisualCrossing docs
    # location (required) – is the address, partial address or latitude,longitude location
    #   for which to retrieve weather data. You can also use US ZIP Codes.
    #
    # the Address Form input String used as location
    def location
      CGI.escape(address.input)
    end

    # Create a persistent http request
    #   for the address.input or location
    # Using PersistentHttp, or replace with any other
    #   currently favorite http Gem if needed
    def http
      @http ||= VisualCrossing::Http.new(location: location)
    end

    # Splunk metric: "VisualCrossing/Request/Api"
    def send_service_request
      logger.measure_info("calling VisualCrossing for address#{address&.id}",
                          metric: to_metric('Api'),
                          criteria: { location: location }) do
        @body_json = http.weather_body_json
      end
    end

    # Splunk metric: "VisualCrossing/Request/Rescue"
    def call_service_rescue(exception)
      logger.error('Could not parse response ask Product Owner how to handle this',
                   metric: to_metric('Rescue'),
                   rescued: {
                     message: exception.message,
                     backtrace: exception.backtrace
                   })
      address.errors.add(:base, exception.message)
      @body_hash = { 'bad_request' => body_json }
      @body_json = body_hash.to_json
    end

    # Weather Service workflow
    #   - call the Weather Service and get json response
    #   - Store the actual json response, that can be used in Testing
    #   - Parse the json into a Ruby Hash for Views
    def call_service
      send_service_request
      VisualCrossing::TestFixture.write_or_not(address, body_json)
      @body_hash = JSON.parse(body_json)
    rescue JSON::ParserError => e
      call_service_rescue(e)
    rescue StandardError => e
      call_service_rescue(e)
    end
  end
end
