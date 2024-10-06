# frozen_string_literal: true

module VisualCrossing
  # translate VisualCrossing fields into
  #   high_low_conditions.html standard format data
  # mean, high, and low for the day
  class HighLowConditions
    attr_reader :hash

    delegate :view_map, to: :class

    # translate VisualCrossing fields into
    #   high_low_conditions.html standard format data
    # mean, high, and low for the day
    def self.view_map
      @view_map ||= {
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

    # translate the Visual Crossing day_information_hash
    #  into the View's Hash for display
    def self.ui_translate(day_information_hash)
      new(day_information_hash).translate
    end

    def initialize(day_information_hash)
      @hash = day_information_hash
    end

    def translate
      return {} if hash.blank?

      ui_data = {}
      view_map.each do |row_key, column_data|
        columns = {}
        column_data.each do |col, field|
          # view => mean, high, and low
          columns[col] = hash[field]
        end
        ui_data[row_key] = columns
      end
      ui_data
    end
  end
end
