class PostsController < ApplicationController
  def create
    PostWithAuto.create(permitted_params[:post])
    head(:ok)
  end

  private

  def permitted_params
    if ::Rails::VERSION::MAJOR >= 4
      params.permit! # ActionController::Parameters
    else
      params
    end
  end
end
