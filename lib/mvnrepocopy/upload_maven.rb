require "open3"
require "async"
require "async/barrier"
require "async/semaphore"
require "base64"
require "uri"
require "http"

require "mvnrepocopy/storage"
require "mvnrepocopy/progress"
require "mvnrepocopy/sanitize_pom"

module Mvnrepocopy
  # Upload a local maven repository to a remote one.
  #
  # This emulates the "mvn deploy:deploy-file" task by uploading the files via
  # HTTP PUT, since maven tends to hide the actual error responses, making it *very*
  # hard to diagnose upload problems.
  #
  # To further improve this, the code performs a HEAD request before uploading each file.
  # This allows for distinguishing between "file already exists" and "some other conflict"
  # (e.g. a version conflict with a proxied upstream repo).
  #
  class UploadMaven
    CACHE_NAME = "uploaded_packages"

    def initialize(url, server, concurrency, filter, cache, user: nil, passwd: nil, dry_run: false)
      @url = url
      @server = server
      @user = user
      @passwd = passwd
      @concurrency = concurrency
      @dry_run = dry_run
      @filter_regex = filter ? Regexp.new(filter) : nil
      @storage = Storage.instance
      @cache = cache && @storage.read_cache(CACHE_NAME).to_set
      @log = @storage
      @sanitize_pom = SanitizePom.new
    end

    def upload
      package_dirs = find_package_dirs

      barrier = Async::Barrier.new
      semaphore = Async::Semaphore.new(@concurrency, parent: barrier)
      progress = Progress.new(package_dirs.length, 20)
      http = new_http_client

      Sync do
        package_dirs.map do |dir|
          semaphore.async do
            upload_dir(dir, http)
            progress.inc
          rescue => e
            @log.error "Error uploading package '#{dir}': #{e}"
            raise
          end
        end.map(&:wait)
      ensure
        barrier.stop
        @storage.write_cache(CACHE_NAME, @cache) if @cache
      end
    end

    private #------------------------------------

    def new_http_client
      HTTP.basic_auth(user: @user, pass: @passwd)
      # http.debug_dev = $stderr if @log.debug?
    end

    def upload_dir(dir, http)
      files = Dir.glob(File.join(dir, "*.pom")).concat(Dir.glob(File.join(dir, "*.jar")))

      files.each do |file|
        @log.debug "Trying to upload '#{file}'"
        if exists_on_server?(file, http)
          @log.debug "Skipped #{file} - already exists on server"
          next
        end

        next if @dry_run

        contents = read_file(file)

        upload_file(file, contents, http)
      end
    end

    def find_package_dirs
      Dir.glob("**/*.pom", base: @storage.repodir.path)
        .select { |f| !@filter_regex or f.match(@filter_regex) }
        .map { |f| File.join(@storage.repodir.path, File.dirname(f)) }
        .sort
        .uniq
    end

    def read_file(file)
      if file.end_with?(".pom")
        @sanitize_pom.sanitize_pom(file, IO.read(file))
      else
        IO.read(file)
      end
    end

    def upload_file(path, contents, http)
      url = "#{@url}/#{remotepath(path)}"

      @log.debug("  Uploading to '#{url}'")
      response = http.put(url, body: contents)

      case response.code
      in (200..299)
        @log.debug "Uploaded #{path}"
        @cache << url if @cache
      else
        @log.error "Upload of #{path} failed with status #{response.code}"
        if is_text_type?(response.content_type)
          @log.debug "Error response fron #{path}: #{response.body}"
        end
      end

      response.code
    end

    def is_text_type?(content_type)
      content_type && ["text/", "/json", "/xml"].select { |part| content_type.to_s.include? part }.any?
    end

    def exists_on_server?(path, http)
      url = "#{@url}/#{remotepath(path)}"

      return true if @cache&.include?(url)

      @log.debug("  Checking '#{url}'")
      response = http.head(url)

      # @log.debug "HEAD #{url} => #{status}"
      exists = response.code == 200
      @cache << url if @cache && exists
      exists
    end

    def remotepath(localpath)
      localpath.delete_prefix(@storage.repodir.path)
    end
  end
end