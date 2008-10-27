# require File.expand_path(File.dirname(__FILE__) + "/lib/insert_routes.rb")
require 'digest/sha1'
class AuthGenerator < Rails::Generator::NamedBase
  default_options :skip_migration => false,
                  :skip_routes    => false,
                  :jquery         => true,
                  :prototype      => false,
                  :include_activation => false

  attr_reader   :subject_name
  attr_reader   :controller_name,
                :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_singular_name,
                :controller_plural_name,
                :controller_routing_name,                 # authentication_path
                :controller_routing_path,                 # GET/POST/PUT /authentication
                :controller_controller_name,              # authentications
                :controller_file_name
  alias_method  :controller_table_name, :controller_plural_name
  attr_reader   :model_controller_name,
                :model_controller_class_path,
                :model_controller_file_path,
                :model_controller_class_nesting,
                :model_controller_class_nesting_depth,
                :model_controller_class_name,
                :model_controller_singular_name,
                :model_controller_plural_name,
                :model_controller_routing_name,           # user_path
                :model_controller_routing_path,           # GET /user
                :model_controller_controller_name         # users
  alias_method  :model_controller_file_name,  :model_controller_singular_name
  alias_method  :model_controller_table_name, :model_controller_plural_name

  def initialize(runtime_args, runtime_options = {})
    super

#    @rspec = has_rspec?

    @subject_name = ( args.shift || 'current_user' )
    @controller_name = ( args.shift || 'authentications' ).pluralize
    @model_controller_name = @name.pluralize

    # sessions controller
    base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
    @controller_class_name_without_nesting, @controller_file_name, @controller_plural_name = inflect_names(base_name)
    @controller_singular_name = @controller_file_name.singularize
    if @controller_class_nesting.empty?
      @controller_class_name = @controller_class_name_without_nesting
    else
      @controller_class_name = "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
    end
    @controller_routing_name  = @controller_singular_name
    @controller_routing_path  = @controller_file_path.singularize
    @controller_controller_name = @controller_plural_name

    # model controller
    base_name, @model_controller_class_path, @model_controller_file_path, @model_controller_class_nesting, @model_controller_class_nesting_depth = extract_modules(@model_controller_name)
    @model_controller_class_name_without_nesting, @model_controller_singular_name, @model_controller_plural_name = inflect_names(base_name)

    if @model_controller_class_nesting.empty?
      @model_controller_class_name = @model_controller_class_name_without_nesting
    else
      @model_controller_class_name = "#{@model_controller_class_nesting}::#{@model_controller_class_name_without_nesting}"
    end
    @model_controller_routing_name    = @table_name
    @model_controller_routing_path    = @model_controller_file_path
    @model_controller_controller_name = @model_controller_plural_name

#    load_or_initialize_site_keys()

    if options[:dump_generator_attribute_names]
      dump_generator_attribute_names
    end
  end

  def manifest
    recorded_session = record do |m|
      # Check for class naming collisions.
      m.class_collisions controller_class_path,       "#{controller_class_name}Controller", # Sessions Controller
                                                      "#{controller_class_name}Helper"
      m.class_collisions model_controller_class_path, "#{model_controller_class_name}Controller", # Model Controller
                                                      "#{model_controller_class_name}Helper"
#      m.class_collisions class_path,                  "#{class_name}", "#{class_name}Mailer", "#{class_name}MailerTest", "#{class_name}Observer"
      m.class_collisions [], 'RestfulAuthentication'

      # Controller, helper, views, and test directories.
      m.directory File.join( 'app/models', class_path )
      m.directory File.join( 'app/controllers', controller_class_path )
      m.directory File.join( 'app/controllers', model_controller_class_path )
      m.directory File.join( 'app/helpers', controller_class_path )
      m.directory File.join( 'app/views', controller_class_path, controller_file_name )
      m.directory File.join( 'app/views', class_path, "#{file_name}_mailer" ) if options[:include_activation]

      m.directory File.join( 'app/controllers', model_controller_class_path )
      m.directory File.join( 'app/helpers', model_controller_class_path )
      m.directory File.join( 'app/views', model_controller_class_path, model_controller_file_name )
      m.directory File.join( 'config/initializers' )

      m.template 'model.rb', File.join( 'app/models', class_path, "#{file_name}.rb" )

      m.template 'controller.rb', File.join( 'app/controllers', controller_class_path, "#{controller_file_name}_controller.rb" )

      m.template 'model_controller.rb', File.join( 'app/controllers', model_controller_class_path, "#{model_controller_file_name}_controller.rb" )

      m.template 'authenticated_system.rb', File.join( 'lib', 'authenticated_system.rb' )

      m.template 'helper.rb', File.join( 'app/helpers', controller_class_path, "#{controller_file_name}_helper.rb" )

      m.template 'model_helper.rb', File.join( 'app/helpers', model_controller_class_path, "#{model_controller_file_name}_helper.rb" )

      # Controller templates
      m.template 'login.html.erb',  File.join( 'app/views', controller_class_path, controller_file_name, "new.html.erb" )
      m.template 'signup.html.erb', File.join( 'app/views', model_controller_class_path, model_controller_file_name, "new.html.erb" )
      m.template '_model_partial.html.erb', File.join( 'app/views', model_controller_class_path, model_controller_file_name, "_#{file_name}_bar.html.erb" )

      unless options[:skip_migration]
        m.migration_template 'migration.rb', 'db/migrate', :assigns => {
          :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}"
        }, :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
      end
      unless options[:skip_routes]
        # Note that this fails for nested classes -- you're on your own with setting up the routes.
        m.route_resource  controller_singular_name
        m.route_resources model_controller_plural_name
        m.route_name('signup',   '/signup',   {:controller => model_controller_plural_name, :action => 'new'})
        m.route_name('register', '/register', {:controller => model_controller_plural_name, :action => 'create'})
        m.route_name('login',    '/login',    {:controller => controller_controller_name, :action => 'new'})
        m.route_name('logout',   '/logout',   {:controller => controller_controller_name, :action => 'destroy'})
      end
    end

    #
    # Post-install notes
    #
    action = File.basename($0) # grok the action from './script/generate' or whatever
    case action
    when "generate"
      puts "Ready to generate."
      puts ("-" * 70)
      puts "Once finished, don't forget to:"
      puts
      if options[:include_activation]
        puts "- Add an observer to config/environment.rb"
        puts "    config.active_record.observers = :#{file_name}_observer"
      end
      puts "- Add routes to these resources. In config/routes.rb, insert routes like:"
      puts %(    map.signup '/signup', :controller => '#{model_controller_file_name}', :action => 'new')
      puts %(    map.login  '/login',  :controller => '#{controller_file_name}', :action => 'new')
      puts %(    map.logout '/logout', :controller => '#{controller_file_name}', :action => 'destroy')
      if options[:include_activation]
        puts %(    map.activate '/activate/:activation_code', :controller => '#{model_controller_file_name}', :action => 'activate', :activation_code => nil)
      end
      puts
      puts ("-" * 70)
    when "destroy"
      puts
      puts ("-" * 70)
      puts
      puts "Thanks for using restful_authentication"
      puts
      puts "Don't forget to comment out the observer line in environment.rb"
      puts "  (This was optional so it may not even be there)"
      puts "  # config.active_record.observers = :#{file_name}_observer"
      puts
      puts ("-" * 70)
      puts
    else
      puts "Didn't understand the action '#{action}' -- you might have missed the 'after running me' instructions."
    end

    #
    # Do the thing
    #
    recorded_session
  end


protected
  def banner
    "Usage: #{$0} auth_restfully ModelName subject [controller_name]\n" +
    "Example: #{$0} auth_restfully User current_user authentications --jquery"
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--skip-migration",
      "Don't generate a migration file for this model")           { |v| options[:skip_migration] = v }
    opt.on("--include-activation",
      "Generate signup 'activation code' confirmation via email") { |v| options[:include_activation] = true }
    opt.on("--jquery",
      "Use jQuery javascript hooks.")                             { |v| options[:jquery] = true; options[:prototype] = false }
    opt.on("--prototype",
      "Use Prototype javascript hooks.")                          { |v| options[:jquery] = false; options[:prototype] = true }
    opt.on("--rspec",
      "Force rspec mode (checks for RAILS_ROOT/spec by default)") { |v| options[:rspec] = true }
    opt.on("--no-rspec",
      "Force test (not RSpec mode")                               { |v| options[:rspec] = false }
    opt.on("--skip-routes",
      "Don't generate a resource line in config/routes.rb")       { |v| options[:skip_routes] = v }
    opt.on("--old-passwords",
      "Use the older password encryption scheme (see README)")    { |v| options[:old_passwords] = v }
    opt.on("--dump-generator-attrs",
      "(generator debug helper)")                                 { |v| options[:dump_generator_attribute_names] = v }
  end

  def dump_generator_attribute_names
    generator_attribute_names = [
      :table_name,
      :file_name,
      :class_name,
      :controller_name,
      :controller_class_path,
      :controller_file_path,
      :controller_class_nesting,
      :controller_class_nesting_depth,
      :controller_class_name,
      :controller_singular_name,
      :controller_plural_name,
      :controller_routing_name,                 # authentication_path
      :controller_routing_path,                 # GET/POST/PUT /authentication
      :controller_controller_name,              # authentications
      :controller_file_name,
      :controller_table_name, :controller_plural_name,
      :model_controller_name,
      :model_controller_class_path,
      :model_controller_file_path,
      :model_controller_class_nesting,
      :model_controller_class_nesting_depth,
      :model_controller_class_name,
      :model_controller_singular_name,
      :model_controller_plural_name,
      :model_controller_routing_name,           # user_path
      :model_controller_routing_path,           # GET /user
      :model_controller_controller_name,        # users
      :model_controller_file_name,  :model_controller_singular_name,
      :model_controller_table_name, :model_controller_plural_name,
    ]
    generator_attribute_names.each do |attr|
      puts "%-40s %s" % ["#{attr}:", self.send(attr)]  # instance_variable_get("@#{attr.to_s}"
    end

  end
end


