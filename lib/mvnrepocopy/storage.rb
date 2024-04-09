require 'fileutils'

module Mvnrepocopy
  class Storage
    include Singleton

    # Supported target dir structures
    TARGETS = [:repo, :log, :cache]

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

    def logfile_name()
      logfile().path
    end

    # get all lines in the specified cache file
    def read_cache(name)
      fullname = mkdirs_for(name, :cache)

      File.exist?(fullname) ? File.open(fullname, 'r') {|f| f.readlines(chomp: true)} : []
    end

    def write_cache(name, lines)
      fullname = mkdirs_for(name, :cache)

      File.open(fullname, 'w') {|f| f.puts(lines) }
    end

    # create all directories for the given file, relative to the local repo
    #
    # returns:: the qualified path pointing to the file
    def mkdirs_for(file, target = :repo)
      dirname = File.dirname(file.to_s)
      dirname = '' if dirname == '.'
      dir = dir(target_dir(target), dirname)

      File.join(dir, File.basename(file.to_s))
    end

    private #----------------------------------

    def log2file(msg)
      timestamp = Time.now.strftime('%Y-%m-%d_%H:%M:%S')

      logfile().puts "#{timestamp} #{msg}"
    end

    def logfile()
      @logfile ||= File.new(mkdirs_for("#{@reponame}-#{@starttime_str}.log", :log), 'a')
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

    def target_dir(target)
      case target
      when :repo
        File.join(@basedir, 'repos', @reponame)
      when :log
        File.join(@basedir, @operation, 'log')
      when :cache
        File.join(@basedir, @operation, 'cache')
      else
        raise ArgumentError, "Unsupported target #{target}", caller
      end
    end
  end
end
