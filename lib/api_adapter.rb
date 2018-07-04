
class ApiAdapter

	attr_accessor :params, :override_options

	def initialize(params = {}, override_options = {})
		@params = params
    self.override_options = override_options
		resources = load_resources
		generate_adapters_for resources
	end


	def load_resources
		config = Configuration.new(params[:location])
		config.resources
	end

	def generate_adapters_for(resources)
		resources.each do |resource|
			Generator.new resource, override_options
		end

	end

end

require 'api_adapter/base'
require 'api_adapter/generator'
require 'api_adapter/configuration'
require 'active_support/hash_with_indifferent_access'
