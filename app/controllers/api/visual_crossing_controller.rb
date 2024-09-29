module Api
  class VisualCrossingController < ApiController
    include RESTFramework::ModelControllerMixin

    self.fields = [:id, :name, :release_date, :enabled]
    self.extra_member_actions = { first: :get }

    def first
      # Always use the bang method, since the framework will rescue `RecordNotFound` and return a
      # sensible error response.
      return api_response(self.get_records.first!)
    end

    def get_recordset
      return Movie.where(enabled: true)
    end
  end
end