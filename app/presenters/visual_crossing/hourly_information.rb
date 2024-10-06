# frozen_string_literal: true

module VisualCrossing
  # convert the VisualCrossing hourly information array
  #   into View's column information
  class HourlyInformation
    attr_reader :list

    delegate :view_map, to: :class

    # app/views/addresses/_hourly_information.html.erb
    def self.view_map
      @view_map ||= {
        hour: 'datetime',
        temp: 'temp',
        conditions: 'conditions',
        precip_probability: 'precipprob'
      }
    end

    def self.ui_translate(hour_information_list)
      new(hour_information_list).translate
    end

    def initialize(hour_information_list)
      @list = hour_information_list
    end

    # callers:
    #   AddressesController#show
    #   app/views/addresses/_hourly_information.html.erb
    #
    # Translate the VisualCrossing hour array
    #   into rows of column information
    def translate
      return [] if list.blank?

      list.map do |hour_info|
        columns(hour_info)
      end
    end

    private

    # column information for the hour_info data
    def columns(hour_info)
      columns = {}
      view_map.each do |view_key, field|
        columns[view_key] = hour_info[field]
      end
      columns
    end
  end
end