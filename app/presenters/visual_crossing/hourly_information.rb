# frozen_string_literal: true

module VisualCrossing
  # convert the VisualCrossing hourly information array
  #   into View's column information
  class HourlyInformation
    attr_reader :list

    delegate :view_translate, to: :class

    # app/views/addresses/_hourly_information.html.erb
    def self.view_translate
      @view_translate ||= {
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
    # ex:
    #   [
    #     {
    #                      :hour => "00:00:00",
    #                     :temp => 67.1,
    #               :conditions => "Clear",
    #       :precip_probability => 0.0
    #     },
    #     {
    #                      :hour => "01:00:00",
    #                     :temp => 64.3,
    #               :conditions => "Clear",
    #       :precip_probability => 0.0
    #     }
    #   ]
    def translate
      return [] if list.blank?

      list.map do |hour_info|
        columns(hour_info)
      end
    end

    private

    # column information for the hour_info data
    # ex:
    #   :columns,
    #   {
    #                   :hour => "00:00:00",
    #                   :temp => 67.1,
    #             :conditions => "Clear",
    #     :precip_probability => 0.0
    #   }
    def columns(hour_info)
      columns = {}
      view_translate.each do |view_key, field|
        columns[view_key] = hour_info[field]
      end
      columns
    end
  end
end