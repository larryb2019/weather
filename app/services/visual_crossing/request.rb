require 'net/http/persistent'

module VisualCrossing
  class Request
    include SemanticLogger::Loggable

    attr_accessor :address
    attr_reader :body_hash, :body_json

    # callers:
    #   addresses_controller#create
    # Calls the VisualCrossing endpoint using
    #   address.input as the location and
    #   using a date range of Date.current
    def self.xon_create(address)
      service = new(address)
      service.on_create
      service
    end

    # Going to show the address information
    #   if more than an hour ago
    #     refresh the data
    #   else
    #     display our stored information
    def self.xon_show(address)
      service = new(address)
      service.on_show
      service
    end

    # callers:
    #   Address#current_weather_data
    # the current_weather_data cache has expired
    #   Call the Service for fresh data
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

    # Presenter to standardize the VisualCrossing
    #   json data into the Weather Apps views expected information.
    def presenter
      @presenter ||= VisualCrossing::Presenter.new(address.body_hash)
    end

    # Splunk metric: "VisualCrossing/Request/Refresh"
    def refresh_weather_data
      logger.measure_info("calling VisualCrossing for address#{address&.id}",
                          metric: to_metric("Refresh"),
                          criteria: { location: location }) do
        call_service
        address_cache_update
      end
    end

    # TestFixture helper to save responses in development
    #   to be used in tests.
    def xon_create
      call_service
      address_save
    end

    # NOTE: if decision is to not use Rails cache
    #   the following code will also cache the data
    #   into the actual address.model
    #
    #   return unless expired?
    #   # get fresh data from service
    #   logger.measure_info("Reset Service data", metric: "VisualCrossing/Request/Reset") do
    #     on_create
    #     address.save
    #    end
    def xon_show
      # refresh the current_weather_data cache if needed
      address.current_weather_data
    end

    private

    def to_metric(metric)
      "VisualCrossing/Request/#{metric}"
    end

    def expired?
      Time.current > 1.hour.since(address.generated_at)
    end

    # save the VisualCrossing information
    #   into the database, since data is valid
    #   for at least one hour
    def address_save
      address.body = body_json
      address.generated_at = Time.current
      address.my_uri = http.uri
      address.resolved_as = presenter.address
    end

    # use update_column so the cache key using
    #   updated_at is still valid
    def address_cache_update
      if address.new_record?
        address.body = body_json
        address.generated_at = Time.current
        address.my_uri = http.uri
        address.resolved_as = body_hash['resolvedAddress'] || "None"
      else
        address.update_column(:body, body_json)
        address.update_column(:generated_at, Time.current)
      end
      if body_hash.key?("bad_request")
        # Save the record so the updated_at will
        #   expire the cache.
        address.save
      end
    end

    # # the Form input String used as location
    # #   in the api call
    def location
      CGI.escape(address.input)
    end

    # Create a persistent http request
    #   for the address.input or location
    # Using PersistentHttp, replace with our
    #   currently favorite http Gem if needed
    def http
      @http ||= VisualCrossing::Http.new(location: location)
    end

    # Splunk metric: "VisualCrossing/Request/Api"
    def send_service_request
      logger.measure_info("calling VisualCrossing for address#{address&.id}",
                          metric: to_metric("Api"),
                          criteria: { location: location }) do
        @body_json = http.weather_body_json
      end
    end

    def call_service
      send_service_request
      VisualCrossing::TestFixture.write_or_not(address, body_json)
      @body_hash = JSON.parse(body_json)
    rescue JSON::ParserError => e
      call_service_rescue(e)
    rescue StandardError => e
      call_service_rescue(e)
    end

    # Splunk metric: "VisualCrossing/Request/Rescue"
    def call_service_rescue(exception)
      logger.error("Could not parse response ask Product Owner how to handle this",
                   metric: to_metric("Rescue"),
                   rescued: {
                     message: exception.message,
                     backtrace: exception.backtrace
                   })
      address.errors.add(:base, exception.message)
      @body_hash = {"bad_request" => body_json}
      @body_json = body_hash.to_json
    end
  end
end