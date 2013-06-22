require 'spec_helper'
require 'java'
require 'lib/java/servlet-api-3.0.jar'
require 'lib/java/rewindable-input-stream.jar'
require 'support/test_app'

java_import org.jruby.rack.servlet.RewindableInputStream

describe RewindableInputStream do
  include HttpRequests

  before(:all) do
    start_server(TestApp.new, { :host => '127.0.0.1', :port => 9201,
      :embedded => true, :rewindable => true })
  end

  after(:all) do
    stop_server
  end

  it "should read data byte by byte" do
    input = 49.times.to_a
    stream = rewindable_input_stream(input.to_java(:byte), 6, 24)
    49.times { |i| stream.read.should == i }
    3.times { stream.read.should == -1 }
  end

  it "should read data then rewind and read again (in memory)" do
    @stream = it_should_read_127_bytes(32, 256)
    @stream.rewind
    it_should_read_127_bytes
  end

  it "should read data then rewind and read again (temp file)" do
    @stream = it_should_read_127_bytes(16, 64)
    @stream.rewind
    it_should_read_127_bytes
  end

  it "should read incomplete data rewind and read until end" do
    input = 100.times.to_a
    stream = rewindable_input_stream(input.to_java(:byte), 10, 50)
    data = new_byte_array(110)
    stream.read(data, 0, 5).should == 5
    5.times { |i| data[i].should == i }
    stream.rewind
    stream.read(data, 5, 88).should == 88
    88.times { |i| data[i + 5].should == i }
    stream.read.should == 88
    stream.read.should == 89
    stream.rewind
    stream.read(data, 10, 33).should == 33
    33.times { |i| data[i + 10].should == i }
    stream.rewind
    stream.read(data, 0, 101).should == 100
    100.times { |i| data[i].should == i }
    stream.read.should == -1
  end

  it "should rewind unread data" do
    input = []; 100.times { |i| input << i }
    stream = rewindable_input_stream(input.to_java(:byte), 10, 50)
    stream.rewind

    data = new_byte_array(120)
    stream.read(data, 10, 110).should == 100
    100.times do |i|
      data[i + 10].should == i
    end
  end

  it "should mark and reset" do
    input = []; 100.times { |i| input << i }
    stream = rewindable_input_stream(input.to_java(:byte), 5, 20)

    15.times { stream.read }
    stream.markSupported.should == true
    stream.mark(50)

    35.times { |i| stream.read.should == 15 + i }

    stream.reset

    50.times { |i| stream.read.should == 15 + i }
    35.times { |i| stream.read.should == 65 + i }

    stream.read.should == -1
  end

  it "should read data then rewind and read again (server)" do
    body = "Mizuno is a set of Jetty-powered running shoes for JRuby/Rack."
    response = post("/repeat_body", nil, {}, body)
    response.code.should == "200"
    response.body.should == body * 2
  end

  def rewindable_input_stream(input, buffer_size = nil, max_buffer_size = nil)
    input = to_input_stream(input) unless input.is_a?(java.io.InputStream)
    buffer_size ||= RewindableInputStream::INI_BUFFER_SIZE
    max_buffer_size ||= RewindableInputStream::MAX_BUFFER_SIZE
    RewindableInputStream.new(input, buffer_size, max_buffer_size)
  end

  def to_input_stream(content = @content)
    bytes = content.respond_to?(:to_java_bytes) ? content.to_java_bytes : content
    java.io.ByteArrayInputStream.new(bytes)
  end

  def new_byte_array(length)
    java.lang.reflect.Array.newInstance(java.lang.Byte::TYPE, length)
  end

  def it_should_read_127_bytes(init_size = nil, max_size = nil)
    input = 127.times.to_a
    stream = @stream || rewindable_input_stream(input.to_java(:byte),
      init_size, max_size)

    # read 7 bytes
    data = new_byte_array(7)
    stream.read(data, 0, 7).should == 7
    7.times { |i| data[i].should == i }

    # read 20 bytes
    data = new_byte_array(42)
    stream.read(data, 10, 20).should == 20
    10.times { |i| data[i].should == 0 }
    20.times { |i| data[i + 10].should == i + 7 }
    10.times { |i| data[i + 30].should == 0 }

    # read 100 bytes
    data = new_byte_array(200)
    stream.read(data, 0, 200).should == 100
    100.times { |i| data[i].should == i + 20 + 7 }
    100.times { |i| data[i + 100].should == 0 }

    stream
  end
end
