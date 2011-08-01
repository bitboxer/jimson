spec = Gem::Specification.new do |s|
  s.name = "jimson-client"
  s.version = "0.2.3"
  s.author = "Chris Kite"
  s.homepage = "http://www.github.com/chriskite/jimson"
  s.platform = Gem::Platform::RUBY
  s.summary = "JSON-RPC 2.0 client"
  s.require_path = "lib"
  s.has_rdoc = false 
  #s.rdoc_options << '-m' << 'README.rdoc' << '-t' << 'Jimson'
  s.extra_rdoc_files = ["README.rdoc"]
  s.add_dependency("rest-client", ">= 1.6.3")
  s.add_dependency("json", ">= 1.5.1")

  s.files = %w[
    VERSION
    LICENSE.txt
    CHANGELOG.rdoc
    README.rdoc
    Rakefile
  ] + Dir['lib/**/*.rb']
end
