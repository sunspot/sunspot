class PostsController < ApplicationController
  def create
    PostWithAuto.create(params[:post])
    render :nothing => true
  end
end
