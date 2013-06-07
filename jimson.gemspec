spec = Gem::Specification.new do |s|
  s.name = "jimson"
  s.version = "0.9.1"
  s.author = "Chris Kite"
  s.homepage = "http://www.github.com/chriskite/jimson"
  s.platform = Gem::Platform::RUBY
  s.summary = "JSON-RPC 2.0 client and server"
  s.require_path = "lib"
  s.has_rdoc = false
  #s.rdoc_options << '-m' << 'README.rdoc' << '-t' << 'Jimson'
  s.extra_rdoc_files = ["README.md"]
  s.add_dependency("blankslate", "~> 3.1.2")
  s.add_dependency("rest-client", "~> 1.6.7")
  s.add_dependency("multi_json", "~> 1.7.6")
  s.add_dependency("rack", "~> 1.4.5")

  s.files = %w[
    VERSION
    LICENSE.txt
    CHANGELOG.rdoc
    README.md
    Rakefile
  ] + Dir['lib/**/*.rb']

  s.test_files = Dir['spec/*.rb']
end
