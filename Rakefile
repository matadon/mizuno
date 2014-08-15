require 'rspec/core/rake_task'
require 'open-uri'
require 'nokogiri'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

# http://rubydoc.info/gems/pompompom/1.1.3/frames

namespace :jetty do
    desc "Grab the latest Jetty from its Maven repository."
    task :update do
        # Manipulate files under the gem root.
        base_path = File.dirname(__FILE__)
        jar_path = File.join(base_path, 'lib', 'java')

        # Information about the Maven repository.
        group = "org.eclipse.jetty"
        artifact = "jetty-distribution"
        repository = 'http://repo1.maven.org/maven2/'

        # Parse Maven metadata and get the latest release version.
        url = File.join(repository, group.gsub('.', '/'), artifact)
        metadata_url = File.join(url, 'maven-metadata.xml')

        puts metadata_url
        metadata = Nokogiri::XML(open(metadata_url))
        versions = metadata.xpath('/metadata/versioning/versions') \
            .children.to_a.map { |v| v.content.strip } \
            .select { |v| v =~ /^8/ }
        release = versions.last

        puts "Latest Jetty release is #{release}"

        # Download the latest version to our tmpdir.
        filename = "#{artifact}-#{release}.tar.gz"
        artifact_url = File.join(url, release, filename)
        tempfile = File.join(base_path, 'tmp', filename)
        if(File.exists?(tempfile))
            puts "Using cached #{tempfile}"
        else
            File.open(tempfile, "wb") { |f| 
                f.write(open(artifact_url).read) }
            puts "Downloaded to #{tempfile}"
        end

        # Inventory contents of the tarball we picked up.
        inventory = `tar tzf #{tempfile}`.split(/\n/)

        # Figure out which JARs we should replce with tarball contents.
        replacements = {}
        Dir.entries(jar_path).each do |entry|
            next unless ((entry =~ /^jetty-\w.*\d\.jar$/) \
                or (entry =~ /^servlet-api.*\d\.jar$/))
            name = entry.sub(/\-\d.*$/, '')
            matcher = /\/#{name}\-[^\/]+\d\.jar$/
            archive_file = inventory.find { |i| i =~ matcher }
            next unless archive_file
            replacements[entry] = archive_file
        end

        # Extract replacements and verify that they aren't corrupted.
        replacements.keys.each do |original|
            replacement = replacements[original]
            outfile = File.join(base_path, 'tmp', 
                File.basename(replacement))
            system("tar xzOf #{tempfile} #{replacement} > #{outfile}") \
                unless File.exists?(outfile)
            # system("jar tf #{outfile} >/dev/null 2>/dev/null")
            # raise("#{outfile} from #{tempfile} corrupt.") unless ($? == 0)
            replacements[original] = outfile
        end

        # Remove old JARs, then add new JARs.
        replacements.keys.each do |entry| 
            file = File.join(jar_path, entry)
            puts "deleting: #{file}"
            FileUtils.rm(file)
        end
        replacements.values.each do |entry| 
            file = File.join(jar_path, File.basename(entry))
            puts "copying: #{file}"
            FileUtils.move(entry, file)
        end 
        puts "Update complete."
    end
end

namespace :java do
    desc "Build bundled Java source files."
    task :build do
        system(<<-END)
            javac -classpath lib/java/servlet-api-3.0.jar \
                src/org/jruby/rack/servlet/RewindableInputStream.java
            jar cf lib/java/rewindable-input-stream.jar -C src/ \
                org/jruby/rack/servlet/RewindableInputStream.class
        END
    end

    desc "Clean up after building."
    task :clean do
        system(<<-END)
            rm src/org/jruby/rack/servlet/RewindableInputStream.class
        END
    end
end
