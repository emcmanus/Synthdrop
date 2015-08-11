Rails.application.routes.draw do

  devise_for :users

  get 'profile', to: 'profile#edit', as: :edit_profile
  put 'profile', to: 'profile#update'
  get 'profile/rc', to: 'profile#rc'

  resources :scripts, except: :delete

  get 'editor', to: 'editor#index', as: :editor

  root 'index#index'
end
