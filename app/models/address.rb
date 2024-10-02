class Address < ApplicationRecord

  delegate :cache_expires_in, to: :class

  validates :input, presence: true
  validates_with JsonBodyValidator, on: :create

  # number of minutes to keep current_weather_data cache
  def self.cache_expires_in
    @cache_expires_in ||= 30.minutes
  end

  def body_hash
    @body_hash ||= JSON.parse(body || "")
  rescue JSON::ParserError
    @body_hash = {}
  end

  def cache_refreshed?
    @cache_refreshed
  end

  # request:
  #   Cache the forecast details for 30 minutes for all subsequent requests by zip codes.
  #     Display indicator if result is pulled from cache.
  #   - not able to use Zip Code since VisualCrossing does not always return zip_code
  #   - could add a USPS request with address to get it.
  #   - using update_at as cache_key for now.
  # callers:
  #   Request#on_show
  # if current_weather_data cache expired then
  #   get new weather data and store the
  #   body_json response into body and update
  #   the generated_at, without setting the updated_at
  #   used in the cache key
  # Caches the weather_data body_hash into the cache
  def current_weather_data
    @cache_refreshed = false
    Rails.cache.fetch("#{cache_key_with_version}/current_weather_data", expires_in: cache_expires_in) do
      @cache_refreshed = true
      VisualCrossing::Request.on_current_weather_data(self)
    end
  end
end
