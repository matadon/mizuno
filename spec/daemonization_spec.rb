require "spec_helper"
require "net/http"
require "fileutils"

class MizunoDaemon
    MIN_TIMEOUT = 1

    MAX_TIMEOUT = 30

    WAIT_INTERVAL = 0.5

    PIDFILE = "tmp/mizuno.pid"

    def start(*args)
        run(args.flatten + [ "--start" ])
        self
    end

    def stop
        return unless running?
        run("--stop")
        kill if running?
        self
    end

    def reload(options = {})
        sleep(3)
        case(options[:method])
            when :sighup then Process.kill("HUP", pid)
            when :file then FileUtils.touch("tmp/restart.txt")
            when :command then run(options[:config], "--reload", "--restart")
            else raise("Unknown reload method: #{options[:method]}")
        end
        sleep(3)
    end

    def running?
        begin
            return unless pid
            Process.getpgid(pid)
            true
        rescue Errno::ESRCH
            false
        end
    end

    def online?(timeout = MAX_TIMEOUT)
        return(false) unless running?
        not get("/", timeout).nil?
    end

    def offline?
        not online?(0)
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

    def run(*args)
        jruby_command = %W(jruby -Ilib/ -Ispec/support
            -J-Djruby.compile.mode=OFF
            -J-Djruby.launch.inproc=false)
        mizuno_command = %W(bin/mizuno
            --log tmp/mizuno.log
            --host 127.0.0.1
            --port 9201
            --pidfile #{PIDFILE})
        system(*(jruby_command + mizuno_command + args.flatten))
    end

    def delete_stale_pidfile
        FileUtils.rm(PIDFILE) if File.exists?(PIDFILE)
    end

    def kill
        Process.kill("KILL", process.pid)
        raise("Daemon failed to stop.") unless wait_for { not running? }
        delete_stale_pidfile
    end

    def wait_for(timeout = MAX_TIMEOUT)
        timeout_at = current_time + timeout
        while(current_time < timeout_at)
            sleep(WAIT_INTERVAL)
            return(true) if yield
        end
        false
    end

    def pid
        File.exists?(PIDFILE) ? File.read(PIDFILE).to_i : nil
    end

    def current_time
        Time.now.to_f
    end
end

describe "daemonization" do
    let(:daemon) { MizunoDaemon.new }

    it "starts and stops" do
        daemon.start("spec/support/success_app.ru")
        expect(daemon).to be_online
        daemon.stop
        expect(daemon).to be_offline
    end

    it "starts as a daemon even if the root is a 404" do
        daemon.start("spec/support/notfound_app.ru")
        expect(daemon).to be_online
        daemon.get.code.should == "404"
        daemon.stop
        expect(daemon).to be_offline
    end

    it "starts as a daemon even if the root is a 301" do
        daemon.start("spec/support/redirect_app.ru")
        expect(daemon).to be_online
        daemon.get.code.should == "301"
        daemon.stop
        expect(daemon).to be_offline
    end

    it "fails to start start if the root is a 500" do
        daemon.start("spec/support/error_app.ru")
        expect(daemon).to be_offline
    end

    it "reloads on SIGHUP only if app has been updated" do
        daemon.start("spec/support/test_app.ru", "--reloadable")
        expect(daemon).to be_online

        first = daemon.get("/version").body.to_i

        daemon.reload(method: :sighup)
        second = daemon.get("/version").body.to_i

        FileUtils.touch('spec/support/test_app.rb')
        daemon.reload(method: :sighup)
        third = daemon.get("/version").body.to_i

        daemon.stop
        expect(daemon).to be_offline

        expect(second).to be == first
        expect(third).to be > first
    end

    it "reloads when a trigger file is touched" do
        daemon.start("spec/support/test_app.ru", "--reloadable")
        expect(daemon).to be_online

        first = daemon.get("/version").body.to_i

        daemon.reload(method: :file)
        second = daemon.get("/version").body.to_i

        FileUtils.touch('spec/support/test_app.rb')
        daemon.reload(method: :file)
        third = daemon.get("/version").body.to_i

        daemon.stop
        expect(daemon).to be_offline

        expect(second).to be == first
        expect(third).to be > first
    end

    it "reloads from the command line" do
        daemon.start("spec/support/test_app.ru", "--reloadable")
        expect(daemon).to be_online

        first = daemon.get("/version").body.to_i

        daemon.reload(method: :command, config: "spec/support/test_app.ru")
        second = daemon.get("/version").body.to_i

        FileUtils.touch('spec/support/test_app.rb')
        daemon.reload(method: :command, config: "spec/support/test_app.ru")
        third = daemon.get("/version").body.to_i

        daemon.stop
        expect(daemon).to be_offline

        expect(second).to be == first
        expect(third).to be > first
    end

    it "starts a new server if asked to reload one that isn't running" do
        expect(daemon).to be_offline
        daemon.reload(method: :command, config: "spec/support/test_app.ru")
        expect(daemon).to be_online
        daemon.stop
    end

    pending "handles ssl requests" do
    end

    pending "handles spdy requests" do
    end

    pending "writes server logs to a file" do
    end

    pending "allows for rotation of server logs" do
    end

    pending "switches to a different group" do
        pending("To test uid/gid switching, run tests as root.") \
            unless (Process.uid == 0)
    end

    pending "switches to a different user" do
        pending("To test uid/gid switching, run tests as root.") \
            unless (Process.uid == 0)
    end
end


