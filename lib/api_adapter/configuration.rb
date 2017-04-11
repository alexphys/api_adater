require 'find'
require 'yaml'
require 'dish'

class ApiAdapter::Configuration

  attr_accessor :resources, :location

  def initialize(location)
    @location = location || '.'
    yml_files = find_yml_files
    @resources = []
    yml_files.each do |file|
      resource_name = file.split(".yml").last.split("/").last
      # parse yml file containing resource configuration
      resource_hash = YAML.load_file(file)
      # Generate PORO out of each resource's hash
      @resources << [resource_name, Dish(resource_hash)]
    end
  end

private
  # find all yml files to be parsed
  def find_yml_files
    files = []
    Find.find(location) do |path|
      files << path if path =~ /.*\.yml$/
    end
    return files
  end

end


#curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "userKey: ca2ec64b-dd79-4d66-91c9-b2580d659e1e"  --header "Author ed70a2568f7e31d23487795fdc723e5b" -d "{\"SRID\": \"SR068374\"}" "https://uat-inapi-gateway.it.pccwglobal.com:8243/remedy-service/1.0/getRemedyTickets" -k
