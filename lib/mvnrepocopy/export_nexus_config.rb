require 'optparse'
require 'ostruct'
require_relative 'config_common'


module Mvnrepocopy

  # Commandline parser for the export.nexus.rb command
  class ExportNexusConfig
    def self.parse(args)
      options = OpenStruct.new
      options.concurrency = 1
      options.verbose = false

      parser = OptionParser.new do |opts|
        opts.banner = "usage: export.nexus.rb [options]"
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("--url=URL", "Base URL of the source nexus") do |url|
          options.url = url
        end

        opts.on("--repo=REPO", "Name of the repository to copy") do |repo|
          options.repo = repo
        end

        opts.on("-jN", "--concurrency=N", Integer,  "Maximum number of concurrent requests") do |concurrency|
          options.concurrency = concurrency
        end

        ::Mvnrepocopy::add_common_opts(options, opts)
      end

      parser.parse!(args)

      unless(options.url&.start_with?(%r_https?://_))
        puts "'url' option missing or not an HTTP(s) URL"
        puts
        puts parser.help
        exit
      end

      unless (options.repo) && (options.repo.length > 2)
        puts "'repo' option missing or empty"
        puts
        puts parser.help
        exit
      end

      options
    end
  end
end

