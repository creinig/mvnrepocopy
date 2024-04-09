module Mvnrepocopy
  class Storage
    include Singleton

    def setup(reponame, operation, verbose)
      @reponame = reponame
      @oeration = operation
      @verbose = verbose
      @starttime = Time.new
      @starttime_str = @starttime.strftime('%Y-%m-%d_%H:%M:%S')

      freeze
    end

    def debug(msg)
      puts msg if @verbose
    end

    def debug?()
      @verbose
    end

    def info(msg)
      puts msg
    end

    def error(msg)
      puts "ERROR ", msg
    end
  end
end
