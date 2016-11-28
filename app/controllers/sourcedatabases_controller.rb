class SourcedatabasesController < ApplicationController

before_action :set_sourcedatabase, only: [:edit, :update, :show, :destroy]

def destroy
 @sourcedatabase.destroy
 flash[:notice] = "Source Database was successfully deleted"
 redirect_to sourcedatabases_path
 
end

    def new
        @sourcedatabase = Sourcedatabase.new
    end
    
    def index
        @sourcedatabases = Sourcedatabase.all
    end
    
    def edit
    end
    
    def update

        if @sourcedatabase.update(sourcedatabase_params)
            flash[:notice] = "Source Database details successfully updated"
            redirect_to sourcedatabase_path(@sourcedatabase)    
        else
            render 'edit'
        end
    end
    def create
        #render plain: params[:sourcedatabase].inspect
       @sourcedatabase = Sourcedatabase.new(sourcedatabase_params)
       if @sourcedatabase.save
           flash[:notice] = "Sourcedatabase was successfully created"
           redirect_to sourcedatabase_path(@sourcedatabase)
        else
           render 'new' 
        end
           
    end
    
    def show
    end
    
    private
    def sourcedatabase_params
        params.require(:sourcedatabase).permit(:DBName,:Engine, :MasterUser,:MasterUserPassword,:Server,:Port
        
        
        )
    end
    
    private 
    def set_sourcedatabase
        @sourcedatabase = Sourcedatabase.find(params[:id])
    end
end