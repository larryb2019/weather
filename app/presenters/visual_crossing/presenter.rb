# frozen_string_literal: true

module VisualCrossing
  # Read the hash returned from VisualCrossing
  # Retrieve forecast data for the given address.
  #   This should include, at minimum, the current temperature
  #   (Bonus points - Retrieve high/low and/or extended forecast)
  #
  # for example of weather_data json document refer to:
  #   test/fixtures/visual_crossing/tampa-fl.json
  class Presenter
    attr_reader :weather_data

    delegate :view_map_index, to: :class

    def self.view_map_index
      @view_map_index ||= {
        time_epoch: 'datetimeEpoch',
        temp: 'temp',
        feels_like: 'feelslike',
        precip_probability: 'precipprob'
      }
    end

    # callers:
    #   AddressesController#index
    #   app/views/addresses/index.html.erb
    # NOTE: Using body_hash so the cache does not
    #   refresh when showing all Addresses
    def self.on_index(address)
      new(address.body_hash).ui_index
    end

    # callers:
    #   AddressesController#create
    #   app/views/addresses/show.html.erb
    def self.on_create(address)
      body_hash = address.current_weather_data
      presenter = new(body_hash)
      address.save
      presenter
    end

    def initialize(visual_crossing_hash)
      @weather_data = visual_crossing_hash || {}
    end

    def time_zone
      @weather_data['timezone'] || 'Eastern Time (US & Canada)'
    end

    # callers:
    #  app/views/addresses/_current_conditions.html.erb
    #  app/views/addresses/show.html.erb
    def ui_current_conditions
      CurrentConditions.ui_translate(current_conditions)
    end

    # callers:
    #   AddressesController#show
    #   app/views/addresses/_high_low_conditions.html.erb
    #
    # convert VisualCrossing's first day_info data into
    #   today's high_low_conditions.html rows data
    # NOTE: just the data values, no formatting
    def ui_high_low_conditions
      HighLowConditions.ui_translate(day_information)
    end

    # callers:
    #   AddressesController#show
    #   app/views/addresses/_hourly_information.html.erb
    #
    # Translate the VisualCrossing hour array
    #   into rows of column information
    def ui_hourly_information
      HourlyInformation.ui_translate(hourly_information)
    end

    # callers:
    #   AddressesController#index
    #   app/views/addresses/index.html.erb
    def ui_index
      ui_data = {}
      view_map_index.each do |key, field|
        ui_data[key] = current_conditions[field]
      end
      ui_data
    end

    private

    # VisualCrossing::Request sets "bad_request"
    #   when http or json.parse is not successful
    def valid?
      @weather_data['bad_request'].nil?
    end

    # TODO: Program Manager what to display
    #   when we have a bad_request returned from the Service?
    def valid(value)
      value.nil? ? 'n/a' : value
    end

    def current_conditions
      @current_conditions ||= @weather_data['currentConditions']
    end

    def days
      @weather_data['days'] || []
    end

    def day_information
      @day_information ||= days.first
    end

    def hourly_information
      @hourly_information ||= day_information['hours'] || []
    end

    # Moonphase
    # A decimal value representing the current moon phase
    #   between 0 and 1 where 0 represents the new moon,
    #   0.5 represents the full moon.
    #   The full cycle can be represented as:
    #
    # 0 – new moon
    # 0-0.25 – waxing crescent
    # 0.25 – first quarter
    # 0.25-0.5 – waxing gibbous
    # 0.5 – full moon
    # 0.5-0.75 – waning gibbous
    # 0.75 – last quarter
    # 0.75 -1 – waning crescent
    def moonphase
      'implmement'
    end
  end
end
