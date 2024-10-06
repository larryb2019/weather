# frozen_string_literal: true

module VisualCrossing
  # convert the VisualCrossing hourly information array
  #   into View's column information
  class CurrentConditions
    attr_reader :hash

    delegate :view_map, to: :class

    # feelslike – what the temperature feels like accounting for heat index or wind chill.
    #             Daily values are average values (mean) for the day.
    # humidity – relative humidity in %
    # precip – the amount of liquid precipitation in (inches or mm) that fell or is predicted to fall in the period.
    #          This includes the liquid-equivalent amount of any frozen precipitation such as snow or ice.
    # precipprob (forecast only) – the likelihood of measurable precipitation ranging from 0% to 100%
    def self.view_map
      @view_map ||= {
        time_epoch: 'datetimeEpoch',
        temp: 'temp',
        feels_like: 'feelslike',
        humidity: 'humidity',
        precip_amount: 'precip',
        precip_probability: 'precipprob'
      }
    end

    def self.ui_translate(current_conditions_hash)
      new(current_conditions_hash).translate
    end

    def initialize(current_conditions_hash)
      @hash = current_conditions_hash
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
    def translate
      return {} if hash.blank?

      ui_data = {}
      view_map.each do |key, field|
        ui_data[key] = hash[field]
      end
      ui_data
    end
  end
end