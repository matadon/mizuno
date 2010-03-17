# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rack-handler-jetty}
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Don Werve"]
  s.date = %q{2010-03-15}
  s.default_executable = %q{jetty}
  s.description = %q{Jetty handler for Rackup}
  s.email = %q{don@madwombat.com}
  s.executables = ["jetty"]
  s.extra_rdoc_files = ["bin/jetty", "lib/java/cometd-api-1.0.0rc0.jar", "lib/java/cometd-java-server-1.0.0rc0.jar", "lib/java/jetty-continuation-7.0.1.v20091125.jar", "lib/java/jetty-http-7.0.1.v20091125.jar", "lib/java/jetty-io-7.0.1.v20091125.jar", "lib/java/jetty-jmx-7.0.1.v20091125.jar", "lib/java/jetty-security-7.0.1.v20091125.jar", "lib/java/jetty-server-7.0.1.v20091125.jar", "lib/java/jetty-servlet-7.0.1.v20091125.jar", "lib/java/jetty-servlets-7.0.1.v20091125.jar", "lib/java/jetty-util-7.0.1.v20091125.jar", "lib/java/servlet-api-2.5.jar", "lib/rack/handler/jetty.rb", "lib/rack/servlet.rb", "lib/ruby_input_stream.rb"]
  s.files = ["Manifest", "Rakefile", "bin/jetty", "lib/java/cometd-api-1.0.0rc0.jar", "lib/java/cometd-java-server-1.0.0rc0.jar", "lib/java/jetty-continuation-7.0.1.v20091125.jar", "lib/java/jetty-http-7.0.1.v20091125.jar", "lib/java/jetty-io-7.0.1.v20091125.jar", "lib/java/jetty-jmx-7.0.1.v20091125.jar", "lib/java/jetty-security-7.0.1.v20091125.jar", "lib/java/jetty-server-7.0.1.v20091125.jar", "lib/java/jetty-servlet-7.0.1.v20091125.jar", "lib/java/jetty-servlets-7.0.1.v20091125.jar", "lib/java/jetty-util-7.0.1.v20091125.jar", "lib/java/servlet-api-2.5.jar", "lib/rack/handler/jetty.rb", "lib/rack/servlet.rb", "lib/ruby_input_stream.rb", "rack-handler-jetty.gemspec"]
  s.homepage = %q{http://github.com/madwombat/rack-handler-jetty}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Rack-handler-jetty"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rack-handler-jetty}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Implements Rack::Handler::Jetty}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
