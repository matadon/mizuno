Gem::Specification.new do |spec|
    spec.name = "mizuno"
    spec.version = "0.4.0"
    spec.required_rubygems_version = Gem::Requirement.new(">= 1.2") \
        if spec.respond_to?(:required_rubygems_version=)
    spec.authors = [ "Don Werve" ]
    spec.description = 'Jetty-powered running shoes for JRuby/Rack.'
    spec.summary = 'Rack handler for Jetty 7 on JRuby.  Features multithreading, event-driven I/O, and async support.'
    spec.email = 'don@madwombat.com'
    spec.executables = [ "mizuno" ]
    spec.files = %w( .gitignore
        README.markdown
        LICENSE
        mizuno.gemspec
        lib/mizuno/http_server.rb
        lib/mizuno/rack_servlet.rb
        lib/mizuno.rb
        bin/mizuno )
    spec.homepage = 'http://github.com/matadon/mizuno'
    spec.has_rdoc = false
    spec.require_paths = [ "lib" ]
    spec.rubygems_version = '1.3.6'
    spec.add_dependency('rack', '>= 1.0.0')
    spec.add_dependency('rjack-jetty', '~> 7.4')
end
