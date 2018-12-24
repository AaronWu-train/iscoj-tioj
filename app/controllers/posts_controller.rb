class PostsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :check_contest, :set_posts

  # GET /posts
  # GET /posts.json
  def index
    @posts = @posts.order("updated_at DESC").page(params[:page])
    set_page_title "Discuss"
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
    @post = @posts.find(params[:id])
    set_page_title "Discuss - " + @post.id.to_s
  end

  # GET /posts/new
  def new
    @post = @posts.build
    set_page_title "New post"
  end

  # GET /posts/1/edit
  def edit
    @post = @posts.find(params[:id])
    check_user!
    set_page_title "Edit post - " + @post.id.to_s
  end

  # POST /posts
  # POST /posts.json
  def create
    @post = @posts.build(post_params)
    @post.user_id = current_user.id

    respond_to do |format|
      if @post.save
        format.html { redirect_to posts_path, notice: 'Post was successfully created.' }
        format.json { render action: 'show', status: :created, location: @post }
      else
        format.html { render action: 'new' }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    @post = @posts.find(params[:id])
    check_user!
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to posts_path, notice: 'Post was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post = @posts.find(params[:id])
    check_user!
    @post.destroy
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to posts_url }
    end
  end

  private
  def check_contest
    unless user_signed_in? and current_user.admin?
      if Contest.where("start_time <= ? AND ? <= end_time AND disable_discussion", Time.now, Time.now).exists?
        redirect_to root_path, :alert => "No discussion during contest."
        return
      end
    end
  end
  
  # Use callbacks to share common setup or constraints between actions.
  def set_posts 
    @problem = Problem.find(params[:problem_id]) if params[:problem_id]
    @posts = @problem ? @problem.posts : Post.all
  end

  def check_user!
    if not current_user.admin? and current_user.id != @post.user_id
      flash[:alert] = 'Insufficient User Permissions.'
      redirect_to action:'index'
      return
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def post_params
    params.require(:post).permit(
      :title, 
      :content, 
      :user_id, 
      :problem_id,
      :page,
      comments_attributes: [
        :id,
        :title,
        :content,
        :post_id
      ]
    )
  end
end
