Rails.application.routes.draw do
  root "addresses#index"
  resources :addresses
  resources :articles

  namespace :api do
    rest_root  # Will route `Api::RootController#root` to '/' in this namespace ('/api').
    rest_resources :movies
    rest_resources :users
    rest_resources :visual_crossings
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
