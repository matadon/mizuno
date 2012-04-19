require 'thread'
require 'spec_helper'
require 'mizuno/client'

describe Mizuno::Client do
    pending "times out when the server doesn't respond" do
        called = false
        client = Mizuno::Client.new(:timeout => 1)
        client.request('http://127.0.0.1:9293/') do |response|
            response.should be_timeout
            called = true
        end
        client.stop
        called.should be_true
    end

    it "makes http requests to google" do
        called = false
        client = Mizuno::Client.new(:timeout => 30)
        client.request('http://google.com/') do |response|
            response.should_not be_timeout
            response.should_not be_ssl
            response.should be_success
            called = true
        end
        client.stop
        called.should be_true
    end

    it "makes multiple requests" do
        queue = Queue.new
        client = Mizuno::Client.new(:timeout => 30)
        client.request('http://google.com/') do |response|
            response.should be_success
            queue.push(true)
        end
        client.request('http://yahoo.com/') do |response|
            response.should be_success
            queue.push(true)
        end
        client.stop
        queue.size.should == 2
    end

    pending "makes https requests to google" do
        called = false
        client = Mizuno::Client.new(:timeout => 30)
        client.request('https://google.com/') do |response|
            response.should_not be_timeout
            response.should be_ssl
            response.should be_success
            called = true
        end
        client.stop
        called.should be_true
    end

    it "has a root exchange" do
        called = false
        Mizuno::Client.request('http://google.com/') do |response|
            called = true
            response.should be_success
        end
        Mizuno::Client.stop
        called.should be_true
    end
end
