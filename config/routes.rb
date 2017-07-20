Rails.application.routes.draw do

  
  resources :widgets
  get 'exchanges/index'
  resources :exchanges

  get 'wallets/index'
  resources :wallets
  get 'about/index'

  get 'welcome/index'
  resources :about
  root 'welcome#index'
  

end
