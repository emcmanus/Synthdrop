Rails.application.routes.draw do
  get 'profile', to: 'profile#edit', as: :edit_profile
  put 'profile', to: 'profile#update'
  resources :scripts, except: :delete
  devise_for :users
  get 'editor', to: 'editor#index', as: :editor
  root 'index#index'
end
