require_relative 'config'


module Mvnrepocopy

  # Commandline parser for the upload.maven.rb command
  class UploadMavenConfig < Config
    def add_specific_options(opts, options)
      opts.on("--url=URL", "Base URL of the target maven repo") do |url|
        options.url = url
      end

      opts.on("--repo=REPO", "Name of the repository to copy") do |repo|
        options.repo = repo
      end

      opts.on("--server=SERVER", "ID of the target maven server, as defined in settingx.xml") do |server|
        options.server = server
      end
    end

    def validate(optparser, options)
      unless(options.url&.start_with?(%r_https?://_))
        error optparser, "'url' option missing or not an HTTP(s) URL"
      end

      unless (options.repo) && (options.repo.length > 2)
        error optparser, "'repo' option missing or empty"
      end

      unless (options.server) && (options.server.length > 2)
        error optparser, "'server' option missing or empty"
      end
    end
  end
end


