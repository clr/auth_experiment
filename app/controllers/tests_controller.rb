class TestsController < ApplicationController
  include RestfulAuthentication
  before_filter :act_restfully
  before_filter :auth_required
  
  # GET /authentications/1/edit
  def get
    respond_to do |format|
      format.html
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
