Rails.application.routes.draw do
  resources :posts, :only => :create
  resources :tbc_posts, :only => :create
end