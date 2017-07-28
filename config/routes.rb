Rails.application.routes.draw do

  root 'welcome#index'
  resources :widgets
  
  get 'exchanges/index'
  resources :exchanges

  get 'wallets/index'
  resources :wallets
  get 'about/index'

  get 'welcome/index'
  resources :about
  

end
