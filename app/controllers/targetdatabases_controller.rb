class TargetdatabasesController < ApplicationController
  before_action :set_targetdatabase, only: [:show, :edit, :update, :destroy]

  # GET /targetdatabases
  # GET /targetdatabases.json
  def index
    @targetdatabases = Targetdatabase.all
  end

  # GET /targetdatabases/1
  # GET /targetdatabases/1.json
  def show
  end

  # GET /targetdatabases/new
  def new
    @targetdatabase = Targetdatabase.new
  end

  # GET /targetdatabases/1/edit
  def edit
  end

  # POST /targetdatabases
  # POST /targetdatabases.json
  def create
    @targetdatabase = Targetdatabase.new(targetdatabase_params)

    respond_to do |format|
      if @targetdatabase.save
        format.html { redirect_to @targetdatabase, notice: 'Targetdatabase was successfully created.' }
        format.json { render :show, status: :created, location: @targetdatabase }
      else
        format.html { render :new }
        format.json { render json: @targetdatabase.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /targetdatabases/1
  # PATCH/PUT /targetdatabases/1.json
  def update
    respond_to do |format|
      if @targetdatabase.update(targetdatabase_params)
        format.html { redirect_to @targetdatabase, notice: 'Targetdatabase was successfully updated.' }
        format.json { render :show, status: :ok, location: @targetdatabase }
      else
        format.html { render :edit }
        format.json { render json: @targetdatabase.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /targetdatabases/1
  # DELETE /targetdatabases/1.json
  def destroy
    @targetdatabase.destroy
    respond_to do |format|
      format.html { redirect_to targetdatabases_url, notice: 'Targetdatabase was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_targetdatabase
      @targetdatabase = Targetdatabase.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def targetdatabase_params
      params.fetch(:targetdatabase, {})
    end
end
