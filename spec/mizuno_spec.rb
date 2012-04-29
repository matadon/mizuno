require 'spec_helper'
require 'net/http'
require 'childprocess'
require 'fileutils'

describe 'daemonization' do
    MIN_TIMEOUT = 1

    MAX_TIMEOUT = 15

    PIDFILE = "tmp/mizuno.pid"

    #
    # Run system commands in a child process.
    #
    def run(command)
        args = <<-END.strip.split(/\s+/)
            jruby -Ilib/ -Ispec/support bin/mizuno \
                --log tmp/mizuno.log \
                --host 127.0.0.1 \
                --port 9201 \
                --pidfile #{PIDFILE} #{command}
        END
        process = ChildProcess.build(*args)
        process.io.inherit!
        process.start
        return(process)
    end

    #
    # Wait until _timeout_ seconds for a successful http connection
    # and return the result; returns nil on failure.
    #
    def connect_to_server(path = '/', timeout = MAX_TIMEOUT)
        begin
            Net::HTTP.start('127.0.0.1', 9201) do |http|
                http.read_timeout = timeout
                return(http.get(path))
            end
        rescue Errno::ECONNREFUSED => error
            return unless ((timeout -= 1) > 0)
            sleep(1)
            retry
        end
    end

    before :each do
        response = connect_to_server('/', MIN_TIMEOUT)
        response.should be_nil
        FileUtils.rm(PIDFILE) if File.exists?(PIDFILE)
    end

    it "starts from a rackup file" do
        process = run("spec/support/success_app.ru")
        response = connect_to_server
        response.should_not be_nil
        response.code.should == "200"
        process.stop
        process.wait
        response = connect_to_server('/', MIN_TIMEOUT)
        response.should be_nil
    end

    it "starts and stops" do
        process = run("spec/support/success_app.ru --start")
        begin
            process.poll_for_exit(MAX_TIMEOUT)
        rescue ChildProcess::TimeoutError
            raise("Failed to daemonize.")
            process.stop
        end
        response = connect_to_server
        response.should_not be_nil
        response.code.should == "200"

        process = run("--stop")
        begin
            process.poll_for_exit(MAX_TIMEOUT)
        rescue ChildProcess::TimeoutError
            process.stop
            pidfile = PIDFILE
            raise("Failed to stop daemon.") unless File.exists?(pidfile)
            Process.kill("TERM", File.read(PIDFILE).to_i)
            raise("Failed to stop daemon; forced termination.")
        end
        response = connect_to_server('/', MIN_TIMEOUT)
        response.should be_nil
    end

    it "starts as a daemon even if the root is a 404" do
        process = run("spec/support/notfound_app.ru --start")
        process.wait
        response = connect_to_server
        response.should_not be_nil
        response.code.should == "404"
        process = run("--stop")
        process.wait
    end

    it "starts as a daemon even if the root is a 301" do
        process = run("spec/support/redirect_app.ru --start")
        process.wait
        response = connect_to_server
        response.should_not be_nil
        response.code.should == "301"
        process = run("--stop")
        process.wait
    end

    it "fails to start start if the root is a 500" do
        process = run("spec/support/error_app.ru --start")
        process.wait
        response = connect_to_server
        response.should be_nil
        process = run("--stop")
        process.wait
    end

    it "switches to a different group" do
        pending("To test uid/gid switching, run tests as root.") \
            unless (Process.uid == 0)
    end

    it "switches to a different user" do
        pending("To test uid/gid switching, run tests as root.") \
            unless (Process.uid == 0)
    end

    it "reloads on SIGHUP" do
        process = run("spec/support/test_app.ru --reloadable")
        response = connect_to_server('/version')
        response.should_not be_nil
        response.code.should == "200"
        first_version = response.body.to_i

        sleep(1)
        Process.kill("HUP", process.pid)
        sleep(1)

        response = connect_to_server('/version')
        response.should_not be_nil
        response.code.should == "200"
        second_version = response.body.to_i

        sleep(1)
        FileUtils.touch('spec/support/test_app.rb')
        sleep(1)
        Process.kill("HUP", process.pid)
        sleep(1)

        response = connect_to_server('/version')
        response.should_not be_nil
        response.code.should == "200"
        third_version = response.body.to_i

        process.stop
        process.wait

        second_version.should == first_version
        third_version.should > first_version
    end

    it "reloads when a trigger file is touched" do
        process = run("spec/support/test_app.ru --reloadable")
        response = connect_to_server('/version')
        response.should_not be_nil
        response.code.should == "200"
        first_version = response.body.to_i

        sleep(1)
        FileUtils.touch('tmp/restart.txt')
        sleep(1)

        response = connect_to_server('/version')
        response.should_not be_nil
        response.code.should == "200"
        second_version = response.body.to_i

        sleep(1)
        FileUtils.touch('spec/support/test_app.rb')
        FileUtils.touch('tmp/restart.txt')
        sleep(1)

        response = connect_to_server('/version')
        response.should_not be_nil
        response.code.should == "200"
        third_version = response.body.to_i

        process.stop
        process.wait

        second_version.should == first_version
        third_version.should > first_version
    end

    pending "handles ssl requests" do
    end

    pending "handles spdy requests" do
    end

    pending "writes server logs to a file" do
    end

    pending "allows for rotation of server logs" do
    end
end

