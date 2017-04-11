Gem::Specification.new do |s|
  s.name        = 'api_adapter'
  s.version     = '0.0.0'
  s.date        = '2017-03-28'
  s.summary     = "API adapter generator"
  s.description = ""
  s.authors     = ["Giorgos Koumparoulis"]
  s.email       = 'gkoumparoulis@crypteianetworks.com'
  s.files       = ["lib/api_adapter.rb"]
  s.homepage    =
    'http://rubygems.org/gems/api_adapter'
  s.license       = 'MIT'


  s.add_runtime_dependency 'dish', '~>0.0.6'
  s.add_runtime_dependency 'xml-simple', '~>1.1.5'
  s.add_runtime_dependency 'activesupport', '~>4.2.5.1'
  s.add_runtime_dependency 'typhoeus', '~>1.1.0'


end
