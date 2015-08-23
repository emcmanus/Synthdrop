Rails.application.routes.draw do

  devise_for :users

  get 'profile', to: 'profile#edit', as: :edit_profile
  put 'profile', to: 'profile#update'
  get 'profile/rc', to: 'profile#rc'

  resources :scripts do
    member do
      get 'editor'
    end
  end

  root 'index#index'
end
