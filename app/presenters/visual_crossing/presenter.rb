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

    # callers:
    #   AddressesController#index
    #   app/views/addresses/index.html.erb
    # NOTE: Using body_hash so the cache does not
    #   refresh when showing all Addresses
    def self.on_index(address)
      new(address.body_hash).ui_current_conditions_list
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

    # callers:
    #   app/views/addresses/_high_low_conditions.html.erb
    #   app/views/addresses/show.html.erb
    def ui_high_low_info
      return {} if invalid_days?

      ui_days.first || {}
    end

    # callers:
    #  app/views/addresses/_current_conditions.html.erb
    #  app/views/addresses/show.html.erb
    # ex:
    # [
    #     [0] :ui_current_conditions,
    #     [1] [
    #         [0] "Temperature: 60.8",
    #         [1] "Feels Like: 60.8",
    #         [2] "Humidity: 77.4",
    #         [3] "Precipitation: 0.0",
    #         [4] "Precipitation Probability: 0.0"
    #     ]
    # ]
    def ui_current_conditions
      @ui_current_conditions ||= visible_current_conditions.map do |key, title|
        "#{title}: #{valid? ? current_conditions[key] : 'n/a'}"
      end
    end

    # callers:
    #   app/views/addresses/index.html.erb
    # example:
    #   :ui_current_conditions_list
    #     [
    #         [0] "44.5",
    #         [1] "37.6",
    #         [2] "52.7"
    #     ]
    def ui_current_conditions_list
      @ui_current_conditions_list ||= ui_current_conditions[0..2].map { |info| info.split(':').last.strip }
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

    def days
      @weather_data['days'] || []
    end

    # VisualCrossing daily information array
    def ui_days
      days.map do |day_info|
        {
          date: valid(day_info['datetime']),
          temp: ui_high_low_temp(day_info),
          feels_like: ui_high_low_feels_like(day_info),
          hour_data: ui_hour_data(day_info)
        }
      end
    end

    def invalid_days?
      ui_days.blank?
    end

    def ui_high_low_temp(day_info)
      {
        max: valid(day_info['tempmax']),
        current: valid(day_info['temp']),
        min: valid(day_info['tempmin'])
      }
    end

    def ui_high_low_feels_like(day_info)
      {
        max: valid(day_info['feelslikemax']),
        current: valid(day_info['feelslike']),
        min: valid(day_info['feelslikemin'])
      }
    end

    def ui_hour_data(day_info)
      day_info['hours'].map do |hour_info|
        { date: hour_info['datetime'],
          temp: hour_info['temp'],
          precipprob: hour_info['precipprob'],
          conditions: hour_info['conditions'] }
      end
    end

    # Possible attribute data supplied
    #     "currentConditions": {
    #       "datetime": "09:45:00",
    #       "datetimeEpoch": 1727531100,
    #       "temp": 82.4,
    #       "feelslike": 92.9,
    #       "humidity": 90.1,
    #       "dew": 79.2,
    #       "precip": 0.0,
    #       "precipprob": 0.0,
    #       "snow": 0.0,
    #       "snowdepth": 0.0,
    #       "preciptype": null,
    #       "windgust": 4.8,
    #       "windspeed": 0.9,
    #       "winddir": 68.0,
    #       "pressure": 1013.0,
    #       "visibility": 9.9,
    #       "cloudcover": 88.0,
    #       "solarradiation": 249.0,
    #       "solarenergy": 0.9,
    #       "uvindex": 2.0,
    #       "conditions": "Partially cloudy",
    #       "icon": "partly-cloudy-day",
    #       "stations": [
    #         "KBKV",
    #         "E8085",
    #         "F8529"
    #       ],
    #       "source": "obs",
    #       "sunrise": "07:22:13",
    #       "sunriseEpoch": 1727522533,
    #       "sunset": "19:19:20",
    #       "sunsetEpoch": 1727565560,
    #       "moonphase": 0.86
    # #   (Bonus points - Retrieve high/low and/or extended forecast)
    def visible_current_conditions
      { 'temp' => 'Temperature',
        'feelslike' => 'Feels Like',
        'humidity' => 'Humidity',
        'precip' => 'Precipitation',
        'precipprob' => 'Precipitation Probability' }
    end

    def current_conditions
      @current_conditions ||= @weather_data['currentConditions']
    end
  end
end
