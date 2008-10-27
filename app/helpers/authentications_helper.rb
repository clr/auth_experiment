module AuthenticationsHelper

  def basic_auth_form_tag( options = {}, &block )
    options[:requestHeaders] = "{ Authorization: Base64.encode( $F('username') + ':' + $F('password') ) }"
    options[:script] = true
    form_remote_tag( options, &block )
  end
  alias_method :auth_form_tag, :basic_auth_form_tag

  def options_for_ajax(options)
    js_options = build_callbacks(options)
    
    js_options['requestHeaders'] = options[:requestHeaders] if options[:requestHeaders]
    js_options['asynchronous']   = options[:type] != :synchronous
    js_options['method']         = method_option_to_s(options[:method]) if options[:method]
    js_options['insertion']      = "Insertion.#{options[:position].to_s.camelize}" if options[:position]
    js_options['evalScripts']    = options[:script].nil? || options[:script]
    
    if options[:form]
      js_options['parameters'] = 'Form.serialize(this)'
    elsif options[:submit]
      js_options['parameters'] = "Form.serialize('#{options[:submit]}')"
    elsif options[:with]
      js_options['parameters'] = options[:with]
    end
    
    if protect_against_forgery? && !options[:form]
      if js_options['parameters']
        js_options['parameters'] << " + '&"
      else
        js_options['parameters'] = "'"
      end
        js_options['parameters'] << "#{request_forgery_protection_token}=' + encodeURIComponent('#{escape_javascript form_authenticity_token}')"
    end
      
    options_for_javascript(js_options)
  end

end
