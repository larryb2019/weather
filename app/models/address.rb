class Address < ApplicationRecord
  validates :input, presence: true

  def body_hash
    @body_hash ||= JSON.parse(body)
  end
end
