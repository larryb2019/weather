class Api::RootController < ApiController
  self.extra_actions = {test: :get}

  def root
    return api_response(
      {
        message: "Welcome to the API.",
        how_to_authenticate: <<~END.lines.map(&:strip).join(" "),
          You can use this API with your normal login session. Otherwise, you can insert your API
          key into a Bearer Authorization header, or into the URL parameters with the name
          `api_key`.
        END
      },
      )
  end

  def test
    return api_response({message: "Hello, world!"})
  end
end