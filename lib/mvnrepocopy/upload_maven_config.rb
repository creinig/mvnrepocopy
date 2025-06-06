require_relative "config"

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

      opts.on("-uU", "--user=USERNAME", "Username for the target maven repository (using HTTP basic auth)") do |user|
        options.user = user
      end

      opts.on("-pP", "--pass=USERNAME", "Password for the target maven repository (using HTTP basic auth)") do |pass|
        options.pass = pass
      end

      opts.on("--filter=REGEX", "Only upload packages matching this regular expression") do |regex|
        options.filter = regex
      end

      opts.on("-c", "--[no-]cache", "Cache info on which packages are already present in the target repo") do |v|
        options.cache = v
      end
    end

    def validate(optparser, options)
      unless options.url&.start_with?(%r{https?://})
        error optparser, "'url' option missing or not an HTTP(s) URL"
      end

      unless options.repo && (options.repo.length > 2)
        error optparser, "'repo' option missing or empty"
      end
    end
  end
end