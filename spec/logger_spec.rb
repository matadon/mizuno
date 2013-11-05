require 'spec_helper'
require 'mizuno/logger'

java_import 'java.util.Properties'

describe Mizuno::Logger do
    it "writes logs to a file" do
        logfile = File.join(File.dirname(__FILE__), '../tmp/logger.log')
        FileUtils.rm(logfile) if File.exists?(logfile)
        Mizuno::Logger.configure(:log => logfile, :debug => true)

        logger = Mizuno::Logger.logger
        logger.debug("uuwaf")
        logger.info("shaeg")
        logger.warn("zohch")
        logger.error("dooca")
        logger.fatal("einai")

        content = File.read(logfile).lines.to_a
        content.grep(/DEBUG uuwaf/).count.should == 1
        content.grep(/INFO shaeg/).count.should == 1
        content.grep(/WARN zohch/).count.should == 1
        content.grep(/ERROR dooca/).count.should == 1
        content.grep(/FATAL einai/).count.should == 1
    end

    context 'when the "log4j" option is enabled' do
        it 'does not set up the logger' do
            Properties.should_not_receive(:new)
            Mizuno::Logger.configure(:log4j => true)
        end
    end
end
