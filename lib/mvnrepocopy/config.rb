require "optparse"
require "ostruct"

require_relative "version"

module Mvnrepocopy
  class Config
    def parse(args)
      options = OpenStruct.new
      options.concurrency = 1
      options.verbose = false

      parser = OptionParser.new do |opts|
        opts.banner = "usage: #{$0} [options]"
        opts.separator ""
        opts.separator "Specific options:"

        add_specific_options(opts, options)

        add_common_options(opts, options)
      end

      parser.parse!(args)

      validate(parser, options)

      options
    end

    # override in concrete implementations
    def add_specific_options(opts, options)
    end

    # override in concrete implementations
    def validate(optparser, options)
    end

    def error(optparser, msg)
      puts "ERROR: #{msg}"
      puts
      puts optparser.help
      exit
    end

    private def add_common_options(opts, options)
      opts.separator ""
      opts.separator "Common Options:"

      opts.on("--filter=REGEX", "Only upload/download packages matching this regular expression") do |regex|
        options.filter = regex
      end

      opts.on("-n", "--[no-]dry-run", "Do not actually upload anything") do |dry|
        options.dry_run = dry
      end

      opts.on("-jN", "--concurrency=N", Integer, "Maximum number of concurrent requests") do |concurrency|
        options.concurrency = concurrency
      end

      opts.on("-v", "--[no-]verbose", "Print verbose output") do |v|
        options.verbose = v
      end

      opts.on("-h", "--help", "Print this heip") do
        puts opts
        exit
      end

      opts.on_tail("--version", "Show Version") do
        puts VERSION
        exit
      end

      opts
    end
  end
end
