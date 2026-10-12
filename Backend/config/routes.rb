Rails.application.routes.draw do
  namespace :api do
    post "auth/register", to: "auth#register"
    post "auth/login", to: "auth#login"
    post "auth/google", to: "auth#google"
    post "auth/refresh", to: "auth#refresh"
    delete "auth/logout", to: "auth#logout"
    post "auth/verify-email", to: "auth#verify_email"
    namespace :admin do
      resources :users, only: [ :index, :destroy ]
    end
    namespace :seller do
      resources :products, only: [ :index, :create, :update, :destroy ]
    end
    resources :products, only: [:index, :show], param: :slug
    resource :cart, only: [:show] do
      resources :items, controller: "cart_items", only: [:create, :update, :destroy]
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
