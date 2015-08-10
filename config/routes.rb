Rails.application.routes.draw do
  resources :scripts, except: :delete
  devise_for :users
  get 'editor', to: 'editor#index', as: :editor
  root 'index#index'
end
