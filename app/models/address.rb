class Address < ApplicationRecord
  validates :input, presence: true
  validates_with JsonBodyValidator, on: :create

  def body_hash
    @body_hash ||= JSON.parse(body || "")
  rescue JSON::ParserError
    @body_hash = {}
  end

  def on_create(params)

  end
end
