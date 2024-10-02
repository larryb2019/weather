class Address < ApplicationRecord
  validates :input, presence: true
  validates_with JsonBodyValidator, on: :create

  def body_hash
    @body_hash ||= JSON.parse(body || "")
  rescue JSON::ParserError
    @body_hash = {}
  end

  def is_refresh?
    @is_refresh
  end

  # callers:
  #   Request#on_show
  # if current_weather_data cache expired then
  #   get new weather data and store the
  #   body_json response into body and update
  #   the generated_at, without setting the updated_at
  #   used in the cache key
  # Caches the weather_data body_hash into the cache
  def current_weather_data
    @is_refresh = false
    Rails.cache.fetch("#{cache_key_with_version}/current_weather_data", expires_in: 2.minutes) do
      @is_refresh = true
      VisualCrossing::Request.on_current_weather_data(self)
    end
  end
end
