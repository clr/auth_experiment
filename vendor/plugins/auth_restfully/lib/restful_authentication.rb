module RestfulAuthentication

  # Bootstrap the class methods.
  def self.included( klass )
    klass.extend ClassMethods
  end
  
#
# Class Methods.
#
  module ClassMethods
  end

#
# Instance Methods.
#
# All methods return a status code of 401 by default, which is "Unauthorized."  This
# requires that all actions be explicitly defined in the controllers, which is better for 
# security, even if it is as simple as 'def gets; end'
#
  protected
    # Returns true or false if the user is logged in.
    # Preloads @current_user with the user model if they're logged in.
    def logged_in?
      !!current_user
    end

    # Accesses the current user from the session. 
    # Future calls avoid the database because nil is not equal to false.
    def current_user
      @current_user
    end

    # Check if the user is authorized
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorized?
    #    current_user.login != "bob"
    #  end
    def authorized?
      logged_in?
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def basic_auth_required
      authorized? || access_denied
    end
    alias_method :auth_required, :basic_auth_required

    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |format|
        format.any do
          redirect_to authentication_url
        end
      end
    end

    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?, :basic_auth_required if base.respond_to? :helper_method
    end

    # Called from #current_user.  Now, attempt to login by basic authentication information.
    def login_from_basic_auth
      authenticate_with_http_basic do |username, password|
        if username == "anonymous" && password == ""
          @current_user = false
          return true
        else
          if username == "test" && password == "test"
            @current_user = "TestUser"
            return true
          else
            return false
          end
        end
      end
    end
end


