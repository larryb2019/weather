class Api::UsersController < ApiController
  include RESTFramework::ModelControllerMixin

  self.fields = {include: [:calculated_popularity], exclude: [:impersonation_token]}
end