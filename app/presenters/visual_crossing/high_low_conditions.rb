# frozen_string_literal: true

module VisualCrossing
  # translate VisualCrossing fields into
  #   high_low_conditions.html standard format data
  # mean, high, and low for the day
  class HighLowConditions
    attr_reader :hash

    delegate :view_translate, to: :class

    # translate VisualCrossing fields into
    #   high_low_conditions.html standard format data
    # mean, high, and low for the day
    def self.view_translate
      @view_translate ||= {
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

    # ex:
    #   :view_hash,
    #   {
    #           :temp => { :mean => 67.3, :high => 81.9, :low => 54.0 },
    #     :feels_like => { :mean => 67.1, :high => 80.2, :low => 54.0 }
    #   }
    def translate
      return {} if hash.blank?

      view_hash = {}
      view_translate.each do |row_key, column_data|
        columns = {}
        column_data.each do |col, field|
          # view => mean, high, and low
          columns[col] = hash[field]
        end
        view_hash[row_key] = columns
      end
      view_hash
    end
  end
end
