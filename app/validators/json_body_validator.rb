class JsonBodyValidator < ActiveModel::Validator
  def validate(record)
    if record.body.is_a?(String)
      hash = JSON.parse(record.body)
      if hash.key?("bad_request")
        record.errors.add :base, "You entered an invalid Address for the Weather Service"
      end
    end
  rescue JSON::ParserError
    record.errors.add :base, "Not a Json string"
  end
end
