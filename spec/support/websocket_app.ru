require 'rubygems'
require 'rack'
require 'websocket_app'
require 'mizuno/websockets/adapter/echo'

run WebsocketApp.new
