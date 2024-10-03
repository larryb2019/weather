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

    delegate :scope_view, :visible_current_conditions, :visible_current_conditions_list, to: :class

    def self.scope_view(view = :index)
      [:views, :addresses, view]
    end

    # Show page current conditions
    # feelslike – what the temperature feels like accounting for heat index or wind chill.
    #             Daily values are average values (mean) for the day.
    # feelslikemax (day only) – maximum feels like temperature at the location.
    # feelslikemin (day only) – minimum feels like temperature at the location.
    # humidity – relative humidity in %
    # precip – the amount of liquid precipitation that fell or is predicted to fall in the period.
    #          This includes the liquid-equivalent amount of any frozen precipitation such as snow or ice.
    # precipprob (forecast only) – the likelihood of measurable precipitation ranging from 0% to 100%
    def self.visible_current_conditions
      @visible_current_conditions ||= %w[temp feelslike humidity precip precipprob]
    end

    # Index page current conditions
    def self.visible_current_conditions_list
      @visible_current_conditions_list ||= %w[temp feelslike precipprob]
    end

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
      @ui_current_conditions ||= format_view_attrs(visible_current_conditions)
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
      @ui_current_conditions_list ||= format_view_attrs(visible_current_conditions_list,
                                                        scope: scope_view(:index))
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

    def format_view_attrs(list, scope: nil)
      list.map do |attr|
        if valid?
          translate = scope ? I18n.t(attr, scope: scope) : Address.human_attribute_name(attr)
          value = current_conditions[attr] || 0.0
          element = translate.gsub('{%}', '%%') % value
          with_degree(element, attr)
        else
          'n/a'
        end
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
        max: valid(in_degrees(day_info['tempmax'])),
        current: valid(in_degrees(day_info['temp'])),
        min: valid(in_degrees(day_info['tempmin']))
      }
    end

    def ui_high_low_feels_like(day_info)
      {
        max: valid(in_degrees(day_info['feelslikemax'])),
        current: valid(in_degrees(day_info['feelslike'])),
        min: valid(in_degrees(day_info['feelslikemin']))
      }
    end

    def ui_hour_data(day_info)
      day_info['hours'].map do |hour_info|
        { date: hour_info['datetime'],
          temp: in_degrees(hour_info['temp']),
          precipprob: hour_info['precipprob'],
          conditions: hour_info['conditions'] }
      end
    end

    def current_conditions
      @current_conditions ||= @weather_data['currentConditions']
    end
  end
end
