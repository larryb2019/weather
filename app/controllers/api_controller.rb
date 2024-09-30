class ApiController < ApplicationController
  include RESTFramework::BaseControllerMixin

  # Setting up a paginator class here makes more sense than defining it on every child controller.
  self.paginator_class = RESTFramework::PageNumberPaginator

  # The page_size attribute doesn't exist on the `BaseControllerMixin`, but for child controllers
  # that include the `ModelControllerMixin`, they will inherit this attribute and will not overwrite
  # it.
  class_attribute(:page_size, default: 30)
end