require 'spec_helper'
require 'mizuno/logger'

describe Mizuno::Logger do
    before do
      @logfile = File.join(File.dirname(__FILE__), '../tmp/logger.log')
      FileUtils.rm(@logfile) if File.exists?(@logfile)
    end
  
    after do
      Mizuno::Logger.reset
    end
    
    it "writes logs to a file" do
        Mizuno::Logger.configure(:log => @logfile, :debug => true)

        logger = Mizuno::Logger.logger
        logger.debug("uuwaf")
        logger.info("shaeg")
        logger.warn("zohch")
        logger.error("dooca")
        logger.fatal("einai")

        content = File.read(@logfile).lines.to_a
        content.grep(/DEBUG uuwaf/).count.should == 1
        content.grep(/INFO shaeg/).count.should == 1
        content.grep(/WARN zohch/).count.should == 1
        content.grep(/ERROR dooca/).count.should == 1
        content.grep(/FATAL einai/).count.should == 1
    end
    
    it "does not configure log4j if explicitly requested" do
        Mizuno::Logger.configure(:without_logging => true)
    
        logger = Mizuno::Logger.logger
        logger.debug("uuwaf")
    
        File.exist?(@logfile).should be_false
    end
    
end
