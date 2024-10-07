# frozen_string_literal: true

FactoryBot.define do
  factory :visual_crossing_http, class: 'VisualCrossing::Http' do
    transient do
      location { 'Plentywood, MT' }
    end
    initialize_with { new(location: location) }
  end
end
