require 'thread'
require 'mizuno'
Mizuno.require_jars(%w(jetty-client jetty-http jetty-io jetty-util))
require 'mizuno/client_response_listener'

module Mizuno
  class Client
    java_import 'org.eclipse.jetty.client.HttpClient'
    java_import 'org.eclipse.jetty.util.thread.QueuedThreadPool'

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
      # TODO: @client.setConnectorType(HttpClient::CONNECTOR_SELECT_CHANNEL)
      @client.setMaxConnectionsPerDestination(100)
      # TODO: @client.setThreadPool(QueuedThreadPool.new(50))
      @client.setConnectTimeout(options[:timeout] * 1000)
      @client.start
      @lock = Mutex.new
      @listeners = []
    end

    def stop(wait = true)
      wait and @lock.synchronize do
        @listeners.each { |e| e.responseComplete() }
        @listeners.clear
      end
      @client.stop
    end

    def clear(exchange)
      return unless @lock.try_lock
      @listeners.delete(exchange)
      @lock.unlock
    end

    # def request(url, options={}, &block)
    #   response = @client.newRequest("http://google.com").send()
    #   status = response.status()

    #   # @client.newRequest(url).send()
    #   return status
    # end

    def request(url, options = {}, &block)
      listener = ClientResponseListener.new(&block)

      @lock.synchronize { @listeners << listener }
      @client.newRequest(url).send(listener)

      return(listener)
    end
  end
end

