require 'open3'
require 'async'
require 'async/barrier'
require 'async/semaphore'

require 'mvnrepocopy/storage'
require 'mvnrepocopy/progress'

module Mvnrepocopy
  class UploadMaven
    def initialize(url, reponame, server, concurrency, filter)
      @url = url
      @reponame = reponame
      @server = server
      @concurrency = concurrency
      @filter_regex = filter ? Regexp.new(filter) : nil
      @storage = Storage.instance
      @log = @storage
    end

    def upload()
      jar_files = find_jars

      barrier = Async::Barrier.new
      semaphore = Async::Semaphore.new(@concurrency, parent: barrier)
      progress = Progress.new(jar_files.length, 20)

      Sync do
        jar_files.map do |file|
          semaphore.async do
            upload_file(file)
            progress.inc
          end
        end.map(&:wait)
      ensure
        barrier.stop
      end
    end

    private #------------------------------------

    def upload_file(file)
      pom = find_pom(file)
      if(!pom)
        @log.error("POM for '#{file}' not found")
        return
      end

      src_jar = file.sub(/\.jar$/, '-sources.jar')
      doc_jar = file.sub(/\.jar$/, '-javadoc.jar')

      opts = ["-DpomFile=#{pom}", "-Dfile=#{file}", "-DrepositoryId=#{@server}", "-Durl=#{@url}"]
      opts << "-Dsources=#{src_jar}" if File.exist?(src_jar)
      opts << "-Djavadoc=#{doc_jar}" if File.exist?(doc_jar)

      status = mvn_deploy_file(opts)

      if(status == 0)
        extras = []
        extras << "#{File.basename src_jar}" if File.exist?(src_jar)
        extras << "#{File.basename doc_jar}" if File.exist?(doc_jar)

        @log.debug "Uploaded #{file} with #{extras}"
      else
        @log.error "Upload of #{file} failed"
      end
    end

    def find_jars()
      Dir.glob('**/*.jar', base: @storage.repodir.path)
        .select{|f| not (f.end_with?('-sources.jar') || f.end_with?('-javadoc.jar'))}
        .map{|f| File.join(@storage.repodir.path, f)}
        .select{|f| !@filter_regex or f.match(@filter_regex)}
    end

    def find_pom(jarfile)
      pom = jarfile.sub(/\.jar$/, '.pom')

      return pom if File.exist?(pom)
      dir = File.dirname(jarfile)
      File.join(dir, Dir.glob("*.pom", base: dir).first)
    end

    def mvn_deploy_file(opts)
      cmdline = ['mvn', 'deploy:deploy-file'].concat(opts).join(' ')

      @log.debug "Running #{cmdline}"
      #output, status = cmdline.to_s, 0
      output, status = Open3.capture2e(cmdline)

      @log.debug output
      status
    end
  end
end
