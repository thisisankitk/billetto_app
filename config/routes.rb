Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "events#index"
  post "/events/:event_id/upvote", to: "votes#upvote"
  post "/events/:event_id/downvote", to: "votes#downvote"

  get "/sign-in", to: "sessions#new"
  get "/sign-up", to: "registrations#new"
  get "/sign-out", to: "sessions#destroy", as: :sign_out
  delete "/sign-out", to: "sessions#destroy"
end
