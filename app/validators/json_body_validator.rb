# frozen_string_literal: true

# Validator for determining if Service gave
#  us a valid json document
class JsonBodyValidator < ActiveModel::Validator
  def validate(record)
    if record.body.is_a?(String)
      hash = JSON.parse(record.body)
      record.errors.add :base, 'You entered an invalid Address for the Weather Service' if hash.key?('bad_request')
    end
  rescue JSON::ParserError
    record.errors.add :base, 'Not a Json string'
  end
end
