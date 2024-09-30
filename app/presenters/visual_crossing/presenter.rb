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
      @weather_data = visual_crossing_hash
    end

    def address
      @weather_data['resolvedAddress']
    end

    def days
      @weather_data['days']
    end

    def ui_weather_title(address)
      "<strong>#{address.resolved_as}</strong> As of #{ui_in_time_zone(address.generated_at)}"
    end

    def ui_hour_data(day_info)
      day_info['hours'].map do |hour_info|
        { date: hour_info['datetime'],
          temp: hour_info['temp'],
          precipprob: hour_info['precipprob'],
          conditions: hour_info['conditions'] }
      end
    end

    # weather.com
    #  time  temperature cloudy precipitation
    def ui_days
      days.map do |day_info|
        { 'Date' => day_info['datetime'],
          'Temp' => { max: day_info['tempmax'],
                      current: day_info['temp'],
                      min: day_info['tempmin'] },
          'Feels Like' => { max: day_info['feelslikemax'],
                            current: day_info['feelslike'],
                            min: day_info['feelslikemin'] },
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

    def ui_current_conditions
      visible_current_conditions.map { |key, title| "#{title}: #{current_conditions[key]}" }
    end

    def ui_current_conditions_list
      @ui_current_conditions_list ||= ui_current_conditions[0..2].map{|info| info.split(":").last.strip}
    end
  end
end