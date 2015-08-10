class ScriptsController < ApplicationController
  before_action :authenticate_user!, except: :show
  before_action :set_script, only: [:edit, :update, :destroy]

  protect_from_forgery with: :exception

  def index
    @scripts = Script.all
  end

  def show
    @script = Script.find(params[:id])
  end

  def new
    @script = Script.new
  end

  def edit
  end

  def create
    @script = Script.new(script_params)
    @script.user = current_user

    respond_to do |format|
      if @script.save
        format.html { redirect_to @script, notice: 'Script was successfully created.' }
        format.json { render :show, status: :created, location: @script }
      else
        format.html { render :new }
        format.json { render json: @script.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @script.update(script_params)
        format.html { redirect_to edit_script_path(@script) }
        format.json { render json: {}, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @script.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_script
      @script = current_user.scripts.find(params[:id])
    end

    def script_params
      params.require(:script).permit(:title, :description, :content)
    end
end
