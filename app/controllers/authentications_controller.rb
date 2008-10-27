class AuthenticationsController < ApplicationController
  include RestfulAuthentication
  before_filter :act_restfully
  
  # GET /authentications/1/edit
  def get
#    @authentication = Authentication.find(params[:id])
    respond_to do |format|
      format.html
      format.js do
#        headers['WWW-Authenticate'] = 'Basic realm="Rails Authentication"'
#        render :inline => '' # , :status => 401
        if login_from_basic_auth
          render :template => "authentications/post.200.js.rjs", :status => 200
        else
          render :template => "authentications/post.401.js.rjs", :status => 200
        end
      end
    end
  end

  # POST /authentications
  def post
#    render :text => request.inspect and return 
    respond_to do |format|
      if login_from_basic_auth
        format.js { render :template => "authentications/post.200.js.rjs" }
      else
        format.js do
          render :template => "authentications/post.401.js.rjs"
        end
      end
    end
  end

  # PUT /authentications/1
  # PUT /authentications/1.xml
  def put
    @authentication = Authentication.find(params[:id])

    respond_to do |format|
      if @authentication.update_attributes(params[:authentication])
        flash[:notice] = 'Authentication was successfully updated.'
        format.html { redirect_to(@authentication) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @authentication.errors, :status => :unprocessable_entity }
      end
    end
  end

  def act_restfully
    case params[:grammatical_number]
    when 'plural'
      self.action_name = self.request.request_method.to_s.pluralize
    when 'singular'
      self.action_name = self.request.request_method.to_s.singularize
    end
  end
end
