#
# A Rack handler for Jetty 8.
#
# Written by Don Werve <don@madwombat.com>
#

require 'java'
jars = File.join(File.dirname(__FILE__), 'java', '*.jar')
Dir[jars].each { |j| require j }

require 'rack'
require 'mizuno/rack/chunked'
require 'mizuno/rack_servlet'
require 'mizuno/http_server'
