require 'xmlsimple'
require 'json'
require 'typhoeus'

class ApiAdapter::Base

  attr_accessor :dynamic_headers, :logger

  def initialize(args = {})
    @dynamic_headers = args[:dynamic_headers]
    @logger = Logger.new(STDOUT)
  end

  # params includes body, params and dynamic segment arguments
  def http_call(url, params, config)

    params[:body] = params[:body].to_json if params[:body] && config[:json_body]
    puts config[:json_body]
    config.delete(:json_body)

    config[:body] = params[:body] if params[:body]
    config[:params] = params[:params] if params[:params]
    config[:headers].merge! dynamic_headers if dynamic_headers

    request = Typhoeus::Request.new(url, config)

    request.on_complete do |response|
      if response.success?
        logger.info("Request succeeded for #{url}")
      elsif response.timed_out?
        logger.warn("Request timed out for #{url}")
      elsif response.code == 0
        logger.info(response.return_message)
      else
        logger.error("HTTP request for #{url} failed: " + response.code.to_s + " " + response.response_body + "\n" + request.inspect)
      end
    end
    request
  end

  # assigns each body key the value passed from arguments, then replaces key names with
  # the names the API expects. Inclusion of arguments in expected fields is already checked.
  def transform_body_based_on_mapping(body, args, argument_mapping)
    begin
      deep_replace(body, args, argument_mapping)
    rescue
      raise RuntimeError.new("Failed to apply mapping on body and assign values to it")
    end
  end

  def deep_replace(obj, args, argument_mapping)
    if obj.is_a? Array
      # IMPORTANT: Node names do NOT need replacement as they cannot be assigned to method arguments,
      # they are just containers (objects)
      node = obj.map{|k| deep_replace(k, args, argument_mapping)}
      node.reduce({}, :merge)
    elsif obj.is_a? Hash
      content = deep_replace(obj[obj.keys.first], args, argument_mapping)
      if (content.is_a?(Hash) && !content.keys.empty?) || (content.is_a?(Array) && !content.empty?)
        {obj.keys.first => content}
      else
        {}
      end
    else
      # a value was passed in the arguments
      if args[obj]
        if argument_mapping[obj]
          {argument_mapping[obj] => args[obj]}
        else
          {obj => args[obj]}
        end
      else
        {}
      end
    end
  end

  def transform_params_based_on_mapping(params, args, argument_mapping)
    result = params.map do |p|
      if args[p]
        if argument_mapping[p]
          {argument_mapping[p] => args[p]}
        else
          {p => args[p]}
        end
      else
        {}
      end
    end
    result.reduce({}, :merge)
  end

  # TODO add error handling for when a dynamic segment is missing in the arguments
  def replace_url_dynamic_segments(url, args)
    url.split("/").map{ |segment| segment[0] == ":" ? args[segment[1..-1]] : segment}.join("/")
  end

  # args is a hash, expected is an array. If expected is empty, no validation takes place.
  def validate_inclusion_of_arguments_in_expected(args, expected)

  end

  # args is a hash, expected is an array
  def validate_presence_of_required_arguments(args, expected)
  end


  def parse_response(response, content_type = 'application/json')
    case content_type
    when 'xml'
      XmlSimple.xml_in(response)
    else
      JSON.parse(response)
    end
  end


end
