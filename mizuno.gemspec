Gem::Specification.new do |spec|
    spec.name = "mizuno"
    spec.version = "0.3.7"
    spec.required_rubygems_version = Gem::Requirement.new(">= 1.2") \
        if spec.respond_to?(:required_rubygems_version=)
    spec.authors = [ "Don Werve" ]
    spec.description = 'Jetty-powered running shoes for JRuby/Rack.'
    spec.summary = 'Rack handler for Jetty 7 on JRuby.  Features multithreading, event-driven I/O, and async support.'
    spec.email = 'don@madwombat.com'
    spec.executables = [ "mizuno" ]
    spec.files = %w( .gitignore
        README 
        LICENSE
        mizuno.gemspec
        lib/java/bayeux-api-2.1.0.jar
        lib/java/cometd-java-server-2.1.0.jar
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
        lib/rack/handler/mizuno/http_server.rb
        lib/rack/handler/mizuno/rack_servlet.rb
        lib/rack/handler/mizuno.rb
        bin/mizuno )
    spec.homepage = 'http://github.com/matadon/mizuno'
    spec.has_rdoc = false
    spec.require_paths = [ "lib" ]
    spec.rubygems_version = '1.3.6'
end
