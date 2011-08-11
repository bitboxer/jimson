spec = Gem::Specification.new do |s|
  s.name = "jimson"
  s.version = "0.3.1"
  s.author = "Chris Kite"
  s.homepage = "http://www.github.com/chriskite/jimson"
  s.platform = Gem::Platform::RUBY
  s.summary = "JSON-RPC 2.0 client and server"
  s.require_path = "lib"
  s.has_rdoc = false 
  #s.rdoc_options << '-m' << 'README.rdoc' << '-t' << 'Jimson'
  s.extra_rdoc_files = ["README.rdoc"]
  s.add_dependency("rest-client", ">= 1.6.3")
  s.add_dependency("json", ">= 1.5.1")
  s.add_dependency("rack", ">= 1.3")

  s.files = %w[
    VERSION
    LICENSE.txt
    CHANGELOG.rdoc
    README.rdoc
    Rakefile
  ] + Dir['lib/**/*.rb']

  s.test_files = Dir['spec/*.rb']
end
