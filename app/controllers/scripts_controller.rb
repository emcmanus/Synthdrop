class ScriptsController < ApplicationController
  before_action :authenticate_user!, except: :show
  before_action :set_script, only: [:edit, :editor, :update, :destroy]

  protect_from_forgery with: :exception

  def index
    @scripts = current_user.scripts.order("updated_at DESC")
    @script_count = current_user.scripts.count
  end

  def show
    @script = Script.find(params[:id])
  end

  def new
    @script = Script.new
  end

  def edit
  end

  def editor
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
    @script.touch
    respond_to do |format|
      if @script.update(script_params)
        format.html { redirect_to script_path(@script), notice: 'Updated script' }
        format.json { render json: {}, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @script.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @script.destroy
      redirect_to({action: :index}, {notice: "Deleted #{@script.title}"})
    else
      redirect_to({action: :index}, {alert: "Unable to delete #{@script.title}"})
    end
  end

  private
    def set_script
      @script = current_user.scripts.find(params[:id])
    end

    def script_params
      params.require(:script).permit(:title, :description, :compiled_content, :content, :language)
    end
end
