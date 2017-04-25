require 'active_support/inflector'

class ApiAdapter::Generator

  attr_accessor :resource_name, :resource_config, :adapter_class, :defaults

  def initialize(resource)

    @defaults = {
      headers: {
        :"Content-Type" => 'application/json'
      }
    }

    @resource_name = resource.first.classify + "Adapter"
    @resource_config = resource.last
    generate_class
    generate_all_methods
  end


private
  def generate_class
    @adapter_class = Class.new ApiAdapter::Base do

    end

    Object.const_set resource_name, adapter_class
  end


  def generate_all_methods
    adapter_methods = resource_config.actions.to_h.keys

    adapter_methods.each do |m|
      action_object = resource_config.actions.send(m.to_sym)
      generate_request_method m, action_object
      generate_method m, action_object
    end
  end

  # Request methods return a Typhoeus request object, to be run either as a single request,
  # or via a Hydra, allowing for parallel API requests

  def generate_request_method(method_name, action_object)
    required_arguments = required_arguments(action_object)
    optional_arguments = optional_arguments(action_object)
    argument_mapping = extract_argument_mapping(action_object)

    url = method_url(action_object)

    config = resource_config && resource_config.client_options ? resource_config.client_options.to_h : {}
    config[:method] = method_verb(action_object)
    config[:headers] = extract_headers(action_object)
    body = extract_body(action_object)
    http_params = extract_params(action_object)
    method_text = <<-CODE
      def request_for_#{method_name}(args = {})
        args = HashWithIndifferentAccess.new(args)
        argument_mapping = #{argument_mapping}
        validate_inclusion_of_arguments_in_expected(args, #{required_arguments + optional_arguments})
        validate_presence_of_required_arguments(args, #{optional_arguments})

        params = {}
        body = #{body}
        http_params = #{http_params}
        params[:body] = transform_body_based_on_mapping(body, args, argument_mapping) if body
        params[:params] = transform_params_based_on_mapping(http_params, args, argument_mapping) if http_params
        url = "#{url}"
        url = replace_url_dynamic_segments(url, args)
        http_call(url, params, #{config})
      end
    CODE
    adapter_class.class_eval method_text
  end

  def generate_method(method_name, action_object)
    content_type = extract_headers(action_object)["Content-Type"]
    method_text = <<-CODE
      def #{method_name}(args = {})
        request = request_for_#{method_name} args
        response = request.run.body
        parse_response response, "#{content_type}"
      end
    CODE
    adapter_class.class_eval method_text

  end

  def extract_body(action_object)
    action_object && action_object.endpoint && action_object.endpoint.to_h["body"] || []
  end

  def extract_params(action_object)
    action_object && action_object.endpoint && action_object.endpoint.to_h["params"] || []
  end

  def extract_argument_mapping(action_object)
    mappings = {}
    if action_object && action_object.argument_mapping
      mappings = action_object.argument_mapping.to_h
    else
      {}
    end
  end

  def required_arguments(action_object)
    if action_object && action_object.arguments && action_object.arguments.required
      action_object.arguments.required
    else
      []
    end
  end

  def optional_arguments(action_object)
     if action_object && action_object.arguments && action_object.arguments.optional
      action_object.arguments.optional
    else
      []
    end
  end


  # Endpoint path must always be set. Host and namespace are optional to cover for cases where
  # methods refer to different hosts
  def method_url(action_object)
      host = resource_config.host
      namespace = resource_config.namespace
      endpoint = action_object.endpoint.path
      raise RuntimeError.new "Undefined endpoint path" if endpoint.nil?
      [host, namespace, endpoint].reject{|s| s.nil? || s.empty?}.map{|s|
       s[-1] == "/" ? s[0..-2] : s
      }.join('/')
  end

  # Verb is optional. Default is GET.
  def method_verb(action_object)
    if action_object && action_object.endpoint
      action_object.endpoint.verb || :get
    end
  end

  # headers will be retrieved from the generic section, or from the endpoint specific section if available
  # Will fallback to defaults if none of the above is present, in order to make sure Content-Type is defined
  def extract_headers(action_object)
    headers = defaults[:headers]

    # First retrieve generic headers
    headers_hash = resource_config.headers.to_h if resource_config.headers

    # Override with method specific ones if present
    if action_object && action_object.endpoint && action_object.endpoint.headers
      headers_hash = action_object.endpoint.headers.to_h
    end

    headers_hash.keys.each do |key|
      headers[key.to_sym] = headers_hash[key]
    end
    headers
  end



end
