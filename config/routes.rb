Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "pages#dashboard"
  get "dashboard", to: "pages#dashboard"
  get "creation", to: "items#new"
  get "inward", to: "inventory_batches#inward"
  get "outward", to: "inventory_batches#outward"
  post "inward", to: "inventory_batches#create_inward"
  post "outward", to: "inventory_batches#create_outward"
  get "inventory/check", to: "inventory_batches#check", as: :check_inventory_batch
  get "batches/:id", to: "inventory_batches#show", as: :inventory_batch
  resources :items
end
