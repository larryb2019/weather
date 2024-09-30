Rails.application.routes.draw do
  root "addresses#index"
  resources :addresses
  resources :articles
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
