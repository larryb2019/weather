module VisualCrossing
  class Request
    include SemanticLogger::Loggable

    attr_accessor :address
    attr_reader :body_hash, :body_json, :date_begin_on, :date_end_on, :params

    delegate :payload_gsub, :rest_uri_base, to: :class

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

    # Add to secret_config to allow changes when expired
    def self.api_key
      @api_key ||= "5M3PTGAJSEJM247DA4NZ4QADX"
    end

    def self.payload_gsub
      @payload_sub ||= "PAYLOAD_GSUB"
    end

    def self.rest_uri_base
      @rest_uri_base ||= "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/#{payload_gsub}?key=#{api_key}"
    end

    def initialize(address)
      @address = address
      @body_json = ""
      @body_hash = {}
    end

    def presenter
      @presenter ||= VisualCrossing::Presenter.new(address.body_hash)
    end

    # TestFixture helper to save responses in development
    #   to be used in tests.
    def on_create
      call_service
      address_save!
    end

    def on_show
      return unless expired?

      # get fresh data from service
      logger.measure_info("Reset Service data", metric: "VisualCrossing/Request/Reset") do
        on_create
      end
    end

    private

    def expired?
      Time.current > 1.hour.since(address.generated_at)
    end

    # save the VisualCrossing information
    #   into the database, since data is valid
    #   for at least one hour
    def address_save!
      address.body = body_json
      address.resolved_as = presenter.address
      address.generated_at = Time.current
      address.my_uri = uri
    end

    # the Form input String used as location
    #   in the api call
    def location
      CGI.escape(address.input)
    end

    # Future may want to expand our date range from user
    #   Now just get one day's worth
    def date_begin_on
      @date_begin_on ||= Date.current
    end

    def date_end_on
      @date_end_on ||= date_begin_on
    end

    def payload
      @payload ||= "#{location}/#{date_begin_on}/#{date_end_on}"
    end

    # example:
    # uri => https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline
    #   /Tamp%2C+FL/2024-09-29/2024-09-29?key=5M3PTGAJSEJM247DA4NZ4QADX
    def uri
      rest_uri_base.gsub(payload_gsub, payload)
    end

    # Replace this with our favorite HTTP Rails gem
    def send_service_request
      logger.measure_info("calling VisualCrossing",
                          metric: "VisualCrossing/Request",
                          criteria: { uri: uri }) do
        @body_json = `curl #{uri}`
      end
    end

    def call_service
      send_service_request
      VisualCrossing::TestFixture.write_or_not(address, body_json)
      @body_hash = JSON.parse(body_json)
    rescue JSON::ParserError => e
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
      @body_json = {bad_request: body_json}.to_json
    end
  end
end