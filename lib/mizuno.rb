#
# A Rack handler for Jetty 7.
#
# Written by Don Werve <don@madwombat.com>
#

# Java integration for talking to Jetty.
require 'java'

# Load Jetty JARs.
require 'rjack-jetty'

require 'rack'
require 'mizuno/rack_servlet'
require 'mizuno/http_server'
