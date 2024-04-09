require 'fileutils'

module Mvnrepocopy
  class Storage
    include Singleton

    def setup(reponame, operation, verbose)
      @reponame = reponame
      @operation = operation.to_s
      @verbose = verbose
      @starttime = Time.new
      @starttime_str = @starttime.strftime('%Y-%m-%d_%H:%M:%S')

      Dir.mkdir('work') unless Dir.exist?('work')
      @basedir = Dir.new("work")

      ObjectSpace.define_finalizer(self, self.class.create_finalizer(logfile()))
    end

    def debug(msg)
      puts msg if @verbose
      log2file "DEBUG #{msg}"
    end

    def debug?()
      @verbose
    end

    def info(msg)
      puts msg
      log2file "INFO  #{msg}"
    end

    def error(msg)
      puts "ERROR ", msg
      log2file "ERROR #{msg}"
    end

    # create all directories for the given file, relative to the local repo
    #
    # returns:: the qualified path pointing to the file
    def mkdirs_for(file)
      dir = mkdirs('repos', @reponame, File.dirname(file.to_s))
      File.join(dir, File.basename(file.to_s))
    end

    def mkdirs(*path_parts)
      dir @basedir, *path_parts
    end

    private #----------------------------------

    def log2file(msg)
      timestamp = Time.now.strftime('%Y-%m-%d_%H:%M:%S')

      logfile().puts "#{timestamp} #{msg}"
    end

    def logfile()
      @logfile ||= File.new(File.join(dir(@basedir, @operation, "log"), "#{@reponame}-#{@starttime_str}.log"), 'a')
    end

    def dir(*parts)
      name = File.join(*parts)
      FileUtils.mkdir_p(name)
      Dir.new(name)
    end

    def self.create_finalizer(logfile)
      proc {
        logfile.close if logfile
      }
    end
  end
end
