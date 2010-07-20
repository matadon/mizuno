#!/usr/bin/env ruby

require 'lib/java/netty-3.2.1.Final.jar'
require 'http_file_server.rb'
require 'http_pipeline_factory.rb'

class HttpServer
    java_import java.net.InetSocketAddress
    java_import java.util.concurrent.Executors
    java_import org.jboss.netty.bootstrap.ServerBootstrap
    java_import org.jboss.netty.channel.socket.nio \
	.NioServerSocketChannelFactory

    def run
	factory = NioServerSocketChannelFactory.new( \
	    Executors.newCachedThreadPool,
	    Executors.newCachedThreadPool)
        bootstrap = ServerBootstrap.new(factory)
        bootstrap.setPipelineFactory(HttpPipelineFactory.new)
        bootstrap.bind(InetSocketAddress.new(9292))
	puts "Listening."
    end
end

server = HttpServer.new
server.run
