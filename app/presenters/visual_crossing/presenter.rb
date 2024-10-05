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

    delegate :scope_view, :translate_current_conditions,
             :translate_high_low_conditions, :translate_index, to: :class

    def self.scope_view(view = :index)
      [:views, :addresses, view]
    end

    def self.translate_index
      @translate_index ||= {
        time_epoch: 'datetimeEpoch',
        temp: 'temp',
        feels_like: 'feelslike',
        precip_probability: 'precipprob'
      }
    end

    # feelslike – what the temperature feels like accounting for heat index or wind chill.
    #             Daily values are average values (mean) for the day.
    # humidity – relative humidity in %
    # precip – the amount of liquid precipitation in (inches or mm) that fell or is predicted to fall in the period.
    #          This includes the liquid-equivalent amount of any frozen precipitation such as snow or ice.
    # precipprob (forecast only) – the likelihood of measurable precipitation ranging from 0% to 100%
    def self.translate_current_conditions
      @translate_current_conditions ||= {
        time_epoch: 'datetimeEpoch',
        temp: 'temp',
        feels_like: 'feelslike',
        humidity: 'humidity',
        precip_amount: 'precip',
        precip_probability: 'precipprob'
      }
    end

    # translate VisualCrossing fields into
    #   high_low_conditions.html standard format data
    # mean, high, and low for the day
    def self.translate_high_low_conditions
      @translate_high_low_conditions ||= {
        temp: {
          # temp – temperature at the location. Daily values are average values (mean) for the day.
          # tempmax (day only) – maximum temperature at the location.
          # tempmin (day only) – minimum temperature at the location.
          mean: 'temp', high: 'tempmax', low: 'tempmin'
        },
        feels_like: {
          # feelslike – what the temperature feels like accounting for heat index or wind chill.
          #   Daily values are average values (mean) for the day.
          # feelslikemax (day only) – maximum feels like temperature at the location.
          # feelslikemin (day only) – minimum feels like temperature at the location.
          mean: 'feelslike', high: 'feelslikemax', low: 'feelslikemin'
        }
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

    # callers:
    #   app/views/addresses/_hourly_information.html.erb
    #   app/views/addresses/show.html.erb
    def ui_hourly_info
      return [] if invalid_days?

      ui_days.first[:hour_data] || []
    end

    def time_zone
      @weather_data['timezone'] || 'Eastern Time (US & Canada)'
    end

    def current_conditions
      @current_conditions ||= @weather_data['currentConditions']
    end

    # callers:
    #  app/views/addresses/_current_conditions.html.erb
    #  app/views/addresses/show.html.erb
    # ex:
    # [
    #   :ui_data,
    #   {
    #     :time_epoch => 1728129600,
    #     :temp => 60.0,
    #     :feels_like => 60.0,
    #     :humidity => 75.07,
    #     :precip_amount => 0.0,
    #     :precip_probability => 0.0
    # }
    # ]
    def ui_current_conditions
      ui_data = {}
      translate_current_conditions.each do |key, field|
        ui_data[key] = current_conditions[field]
      end
      ui_data
    end

    # convert VisualCrossing's first day_info data into
    #   today's high_low_conditions.html rows data
    # NOTE: just the data values, no formatting
    #
    # callers:
    #   AddressesController#show
    #   app/views/addresses/_high_low_conditions.html.erb
    def ui_high_low_conditions
      day_info = days&.first || {}

      ui_data = {}
      translate_high_low_conditions.each do |row_key, column_data|
        columns = {}
        column_data.each do |col, field|
          # view => mean, high, and low
          columns[col] = day_info[field]
        end
        ui_data[row_key] = columns
      end
      ui_data
    end

    # callers:
    #   AddressesController#index
    #   app/views/addresses/index.html.erb
    def ui_index
      ui_data = {}
      translate_index.each do |key, field|
        ui_data[key] = current_conditions[field]
      end
      ui_data
    end

    private

    def in_degrees(element)
      "#{element}&deg;".html_safe
    end

    def with_degree(element, attr)
      if %w[temp feelslike].include?(attr)
        in_degrees(element)
      else
        element
      end
    end

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

    def days
      @weather_data['days'] || []
    end

    # VisualCrossing daily information array
    # datetime – ISO 8601 formatted date, time or datetime value indicating
    #   the date and time of the weather data in the local time zone of the
    #   requested location.
    def ui_days
      days.map do |day_info|
        {
          date: valid(day_info['datetime']),
          hour_data: ui_hour_data(day_info)
        }
      end
    end

    def invalid_days?
      ui_days.blank?
    end

    def ui_hour_data(day_info)
      day_info['hours'].map do |hour_info|
        { date: hour_info['datetime'],
          temp: in_degrees(hour_info['temp']),
          precipprob: hour_info['precipprob'],
          conditions: hour_info['conditions'] }
      end
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
