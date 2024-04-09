require 'optparse'
require 'ostruct'
require_relative 'config'


module Mvnrepocopy

  # Commandline parser for the export.nexus.rb command
  class ExportNexusConfig < Config
    def add_specific_options(opts, options)
      opts.on("--url=URL", "Base URL of the source nexus") do |url|
        options.url = url
      end

      opts.on("--repo=REPO", "Name of the repository to copy") do |repo|
        options.repo = repo
      end
    end

    def validate(optparser, options)
      unless(options.url&.start_with?(%r_https?://_))
        error optparser, "'url' option missing or not an HTTP(s) URL"
      end

      unless (options.repo) && (options.repo.length > 2)
        error optparser, "'repo' option missing or empty"
      end
    end
  end
end

