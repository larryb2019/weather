# frozen_string_literal: true

FactoryBot.define do
  factory :address do
    transient do
      test_fixture { build(:visual_crossing_test_fixture, address_input: input) }
    end

    input { 'Plentywood, MT' }

    # Add Visual Crossing response to
    #   address similar to:
    #    VisualCrossing::Request#address_cache_update
    trait :with_visual_crossing do
      transient do
        http { build(:visual_crossing_http, location: input) }
      end
      after(:build) do |model, evaluator|
        if evaluator.test_fixture
          model.generated_at ||= Time.current
          model.body = evaluator.test_fixture.read
          model.resolved_as = begin
            model.body_hash['resolvedAddress']
          rescue StandardError
            'None'
          end
        end
        model.my_uri = evaluator.http.uri if evaluator.http
      end
    end
  end
end
