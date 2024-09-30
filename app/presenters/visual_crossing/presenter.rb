# Read the hash returned from VisualCrossing
# Retrieve forecast data for the given address.
#   This should include, at minimum, the current temperature
#   (Bonus points - Retrieve high/low and/or extended forecast)
module VisualCrossing
  class Presenter

    # for example of weather_data refer to:
    #   test/fixtures/visual_crossing/tampa-fl.json
    attr_reader :weather_data

    # callers:
    #   AddressesController#index
    #   app/views/addresses/index.html.erb
    def self.on_index(address)
      new(address.body_hash).ui_current_conditions_list
    end

    def initialize(visual_crossing_hash)
      @weather_data = visual_crossing_hash || {}
    end

    def valid?
      @weather_data["bad_request"].nil?
    end

    def address
      @weather_data['resolvedAddress'] || "None"
    end

    def days
      @weather_data['days'] || []
    end

    def valid(value)
      value.nil? ? "n/a" : value
    end

    def ui_hourly_info
      return [] if ui_days.blank?

      ui_days.first[:hour_data] || []
    end

    def ui_hour_data(day_info)
      data = day_info['hours'].map do |hour_info|
        { date: hour_info['datetime'],
          temp: hour_info['temp'],
          precipprob: hour_info['precipprob'],
          conditions: hour_info['conditions'] }
      end
      ap [:ui_hour_data, data]
      data
    end

    # weather.com
    #  time  temperature cloudy precipitation
    def ui_days
      days.map do |day_info|
        { 'Date' => valid(day_info['datetime']),
          'Temp' => { max: valid(day_info['tempmax']),
                      current: valid(day_info['temp']),
                      min: valid(day_info['tempmin']) },
          'Feels Like' => { max: valid(day_info['feelslikemax']),
                            current: valid(day_info['feelslike']),
                            min: valid(day_info['feelslikemin']) },
          hour_data: ui_hour_data(day_info)
        }
      end
    end

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
        'precipprob' => 'Precipitation Probability'
      }
    end

    def current_conditions
      @weather_data['currentConditions']
    end

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
      data = visible_current_conditions.map do  |key, title|
        "#{title}: #{valid? ? current_conditions[key] : "n/a"}"
      end
      ap [:ui_current_conditions, data]
      data
    end

    def ui_current_conditions_list
      @ui_current_conditions_list ||= ui_current_conditions[0..2].map{|info| info.split(":").last.strip}
    end
  end
end