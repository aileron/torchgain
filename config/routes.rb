Rails.application.routes.draw do
  root "home#index"
  get "locations/:id/(:zoom)", to: "locations#show", as: :location
end
