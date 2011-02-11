#
# A Rack handler for Jetty 7.
#
# Written by Don Werve <don@madwombat.com>
#

# Java integration for talking to Jetty.
require 'java'

# Load Jetty JARs.
jars = File.join(File.dirname(__FILE__), 'java', '*.jar')
Dir[jars].each { |j| require j }

require 'rack'
require 'mizuno/rack_servlet'
require 'mizuno/http_server'
