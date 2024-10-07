# frozen_string_literal: true

FactoryBot.define do
  factory :visual_crossing_test_fixture, class: 'VisualCrossing::TestFixture' do
    transient do
      address_input { 'Plentywood, MT' }
      json_data { nil }
    end
    initialize_with { new(address_input, json_data) }
  end
end
