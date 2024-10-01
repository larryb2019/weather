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
    def self.on_create(address)
      service = new(address)
      service.on_create
      service
    end

    # Going to show the address information
    #   if more than an hour ago
    #     refresh the data
    #   else
    #     display our stored information
    def self.on_show(address)
      service = new(address)
      service.on_show
      service
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

    # TestFixture helper to save responses in development
    #   to be used in tests.
    def on_create
      call_service
      address_save
    end

    def on_show
      return unless expired?

      # get fresh data from service
      logger.measure_info("Reset Service data", metric: "VisualCrossing/Request/Reset") do
        on_create
        address.save
      end
    end

    private

    def expired?
      Time.current > 1.hour.since(address.generated_at)
    end

    # save the VisualCrossing information
    #   into the database, since data is valid
    #   for at least one hour
    def address_save
      address.body = body_json
      address.resolved_as = presenter.address
      address.generated_at = Time.current
      address.my_uri = http.uri
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

    def send_service_request
      logger.measure_info("calling VisualCrossing",
                          metric: "VisualCrossing/Request",
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

    def call_service_rescue(exception)
      logger.error("Could not parse response ask Product Owner how to handle this",
                   metric: "Request/Rescue",
                   rescued: {
                     message: exception.message,
                     backtrace: exception.backtrace
                   })
      address.errors.add(:base, exception.message)
      @body_json = { bad_request: body_json }.to_json
    end
  end
end