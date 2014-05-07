require "thread"
require "mizuno"
Mizuno.require_jars(%w(jetty-client jetty-http jetty-io jetty-util))
require "mizuno/client_exchange"

module Mizuno
    class Client
        java_import "org.eclipse.jetty.client.HttpClient"
        java_import "org.eclipse.jetty.util.thread.QueuedThreadPool"

        @lock = Mutex.new

        def Client.request(*args, &block)
            @lock.synchronize { @root ||= new }
            @root.request(*args, &block)
        end

        def Client.stop
            @lock.synchronize do
                return unless @root
                @root.stop
                @root = nil
            end
        end

        def initialize(options = {})
            defaults = { :timeout => 60 }
            options = defaults.merge(options)
            @client = HttpClient.new
            @client.setConnectorType(HttpClient::CONNECTOR_SELECT_CHANNEL)
            @client.setMaxConnectionsPerAddress(100)
            @client.setThreadPool(QueuedThreadPool.new(50))
            @client.setTimeout(options[:timeout] * 1000)
            @client.start
            @lock = Mutex.new
            @exchanges = []
        end

        def stop(wait = true)
            wait and @lock.synchronize do
                @exchanges.each { |e| e.waitForDone }
                @exchanges.clear
            end
            @client.stop
        end

        def clear(exchange)
            return unless @lock.try_lock
            @exchanges.delete(exchange)
            @lock.unlock
        end

        def request(url, options = {}, &block)
            exchange = ClientExchange.new(self)
            @lock.synchronize { @exchanges << exchange }
            exchange.setup(url, options, &block)
            @client.send(exchange)
            return(exchange)
        end
    end
end

