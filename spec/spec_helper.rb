# Load our local copy of Mizuno before anything else.
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# All dependencies for testing.
require 'yaml'
require 'net/http'
require 'rack/urlmap'
require 'rack/lint'
require 'mizuno'

Thread.abort_on_exception = true
