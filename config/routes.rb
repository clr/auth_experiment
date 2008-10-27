ActionController::Routing::Routes.draw do |map|

  map.authentication 'authentication/:id', :controller => 'authentications', :id => nil, :grammatical_number => 'singular'
  map.authentications 'authentications', :controller => 'authentications', :grammatical_number => 'plural'
  map.test 'test/:id', :controller => 'tests', :id => nil, :grammatical_number => 'singular'

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
