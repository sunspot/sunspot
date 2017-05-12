class PostsController < ApplicationController
  def create
    PostWithAuto.create(post_params)
    # render :nothing => true
    render body: nil
  end

  private

  def post_params
    params.require(:post).permit(:title)
  end
end
