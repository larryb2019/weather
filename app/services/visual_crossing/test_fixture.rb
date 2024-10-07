# frozen_string_literal: true

module VisualCrossing
  # Ability to store the development responses
  #   into test fixtures for our tests.
  # NOTE: Only writes in Rails.env.development?
  class TestFixture
    include SemanticLogger::Loggable

    attr_reader :my_location, :json_data

    delegate :path_base, to: :class

    def self.path_base
      'test/fixtures/visual_crossing'
    end

    def self.write_or_not(address, json_data)
      service = new(address.input, json_data)
      service.write_or_not
      service
    end

    def initialize(address_input, json_data)
      @my_location = address_input
      @json_data = json_data
    end

    def read
      @json_data = path_location.read
    end

    # Only write the test/fixtures file
    #   if in development and file does not currently exist
    def write_or_not
      return unless Rails.env.development?
      return if path_location.exist?

      logger.measure_info('writing test fixture',
                          metric: 'TestFixture/Write',
                          criteria: { path_location: path_location.to_s }) do
        path_location.writer { |io| io << json_data }
      end
    end

    private

    def path_location
      if @path_location.nil?
        parts = my_location.split(',')
        city = parts.first.downcase.gsub(' ', '_').strip
        state = parts.last.downcase.strip
        @path_location = IOStreams.path(path_base, "#{city}-#{state}.json")
      end
      @path_location
    end
  end
end
