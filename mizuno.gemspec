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
        lib/java/jetty-continuation-7.3.0.v20110203.jar
        lib/java/jetty-http-7.3.0.v20110203.jar
        lib/java/jetty-io-7.3.0.v20110203.jar
        lib/java/jetty-jmx-7.3.0.v20110203.jar
        lib/java/jetty-security-7.3.0.v20110203.jar
        lib/java/jetty-server-7.3.0.v20110203.jar
        lib/java/jetty-servlet-7.3.0.v20110203.jar
        lib/java/jetty-servlets-7.3.0.v20110203.jar
        lib/java/jetty-util-7.3.0.v20110203.jar
        lib/java/servlet-api-2.5.jar
        lib/mizuno/http_server.rb
        lib/mizuno/rack_servlet.rb
        lib/mizuno.rb
        bin/mizuno )
    spec.homepage = 'http://github.com/matadon/mizuno'
    spec.has_rdoc = false
    spec.require_paths = [ "lib" ]
    spec.rubygems_version = '1.3.6'
    spec.add_dependency('rack', '>= 1.0.0')
    spec.add_dependency('rjack-slf4j', '~> 1.6.1')
    spec.add_development_dependency('rjack-logback', '~> 1.1')
end
