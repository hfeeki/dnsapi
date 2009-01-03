class DomainsController < ApplicationController
  
  require_role [ "admin", "owner" ], :unless => "token_user?"
  
  # Keep token users in line
  before_filter :restrict_token_movements, :except => :show
  
  def index
    @domains = Domain.paginate :page => params[:page], :user => current_user, :order => 'name'
  end
  
  def show
    if current_user
      @domain = Domain.find( params[:id], :user => current_user, :include => :records )
      @users = User.active_owners if current_user.admin?
    else
      @domain = Domain.find( current_token.domain_id, :include => :records )
    end
    
    @record = @domain.records.new
  end
  
  def new
    @domain = Domain.new
    @zone_templates = ZoneTemplate.find( :all, :require_soa => true, :user => current_user )
  end
  
  def create
    @zone_template = ZoneTemplate.find(params[:domain][:zone_template_id]) unless params[:domain][:zone_template_id].blank?
    @zone_template ||= ZoneTemplate.find_by_name(params[:domain][:zone_template_name]) unless params[:domain][:zone_template_name].blank?
    
    @domain = Domain.new( params[:domain] )
    unless @zone_template.nil?
      begin
        @domain = @zone_template.build( params[:domain][:name] )
      rescue ActiveRecord::RecordInvalid => e
        @domain.attach_errors(e)
      end
    end
    @domain.user = current_user unless current_user.has_role?( 'admin' )

    respond_to do |format|
      if @domain.save
        format.html { 
          flash[:info] = "Domain created"
          redirect_to domain_path( @domain ) 
        }
        format.xml { render :xml => @domain, :status => :created, :location => domain_url( @domain ) }
      else
        format.html {
          @zone_templates = ZoneTemplate.find( :all )
          render :action => :new
        }
        format.xml { render :xml => @domain.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def edit
    @domain = Domain.find( params[:id] )
  end
  
  def update
    @domain = Domain.find( params[:id] )
    if @domain.update_attributes( params[:domain] )
      flash[:info] = "Domain was updated!"
      redirect_to domain_path(@domain)
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @domain = Domain.find( params[:id] )
    @domain.destroy

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.xml { render :xml => @domain, :status => :no_content }
    end
  end
  
  # Non-CRUD methods
  def update_note
    @domain = Domain.find( params[:id] )
    @domain.update_attribute( :notes, params[:domain][:notes] )
  end
  
  def change_owner
    @domain = Domain.find( params[:id] )
    @domain.update_attribute :user_id, params[:domain][:user_id]
  end

  # GET: list of macros to apply
  # POST: apply selected macro
  def apply_macro
    @domain = Domain.find( params[:id], :user => current_user )
    
    if request.get?
      @macros = Macro.find(:all, :user => current_user)

      respond_to do |format|
        format.html
        format.xml { render :xml => @macros }
      end
      
    else
      @macro = Macro.find( params[:macro_id], :user => current_user )
      @macro.apply_to( @domain )

      respond_to do |format|
        format.html {
          flash[:notice] = "Macro applied to domain"
          redirect_to domain_path(@domain)
        }
        format.xml { render :xml => @domain.reload, :status => :accepted, :location => domain_path(@domain) }
      end
      
    end
    
  end
  
  private
  
  def restrict_token_movements
    redirect_to domain_path( current_token.domain ) if current_token
  end

end
