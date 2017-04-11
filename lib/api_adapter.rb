
class ApiAdapter

	attr_accessor :params

	def initialize(params = {})
		@params = params
		resources = load_resources
		generate_adapters_for resources
	end


	def load_resources
		config = Configuration.new(params[:location])
		config.resources
	end

	def generate_adapters_for(resources)
		resources.each do |resource|
			Generator.new resource
		end

	end

end

require 'api_adapter/base'
require 'api_adapter/generator'
require 'api_adapter/configuration'
require 'active_support/hash_with_indifferent_access'
