if Rails::VERSION::MAJOR == 2
  ActionController::Routing::Routes.draw do |map|
    map.resources :posts, :only => :create
  end
elsif Rails::VERSION::MAJOR == 3
  Rails.application.routes.draw do
    resources :posts, :only => :create
  end
end
