require 'spec_helper'
require 'net/http'
require 'childprocess'
require 'fileutils'

class MizunoRunner
    MIN_TIMEOUT = 1

    MAX_TIMEOUT = 30

    WAIT_INTERVAL = 0.5

    PIDFILE = "tmp/mizuno.pid"

    attr_reader :process, :args

    def start(*args)
        @args = args.flatten
        jruby_command = %w(jruby -Ilib/ -Ispec/support
            -J-Djruby.compile.mode=OFF
            -J-Djruby.launch.inproc=false)
        mizuno_command = %w(bin/mizuno
            --log tmp/mizuno.log
            --host 127.0.0.1
            --port 9201
            --pidfile #{PIDFILE})
        command = jruby_command + mizuno_command + @args
        @process = ChildProcess.build(*command)
        process.io.inherit!
        process.start
        self
    end

    def stop
        return unless running?
        Process.kill("KILL", process.pid)
        wait
        raise("Runner failed to stop.") if online?
        FileUtils.rm(PIDFILE) if File.exists?(PIDFILE)
        self
    end

    def wait(timeout = MAX_TIMEOUT)
        timeout_at = current_time + timeout
        while(current_time < timeout_at)
            sleep(WAIT_INTERVAL)
            return(true) unless running?
        end
        false
    end

    def running?
        begin
            Process.getpgid(process.pid)
            true
        rescue Errno::ESRCH
            false
        end
    end

    def online?
        response = get
        return(false) if response.nil?
        status = response.code.to_i
        (status >= 200) and (status <= 400)
    end

    def get(path = "/", timeout = MAX_TIMEOUT)
        timeout_at = current_time + timeout
        begin
            Net::HTTP.start("127.0.0.1", 9201) do |http|
                http.read_timeout = timeout
                return(http.get(path))
            end
        rescue Errno::ECONNREFUSED, Errno::ECONNRESET
            return if (current_time > timeout_at)
            sleep(WAIT_INTERVAL)
            retry
        end
    end

    private

    def pid
        File.read(PIDFILE).to_i
    end

    def current_time
        Time.now.to_f
    end
end

describe "daemonization" do
    let(:daemon) { MizunoRunner.new }

    it "starts from a rackup file without daemonizing" do
        daemon.start("spec/support/success_app.ru")
        expect(daemon).to be_online
        daemon.stop
    end
end

