#
# A Rack handler for Jetty 8.
#
# Written by Don Werve <don@madwombat.com>
#

require 'java'
jars = File.join(File.dirname(__FILE__), 'java', '*.jar')
Dir[jars].each { |j| require j }

# Tell log4j not to complain to the console about a missing
# log4j.properties file, as we configure it programmatically in
# Mizuno::HttpServer (http://stackoverflow.com/questions/6849887)
Java.org.apache.log4j.Logger.getRootLogger().setLevel( \
    Java.org.apache.log4j.Level::INFO)

require 'rack'
require 'mizuno/rack/chunked'
require 'mizuno/rack_servlet'
require 'mizuno/http_server'
