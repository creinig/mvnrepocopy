require 'open3'
require 'async'
require 'async/barrier'
require 'async/semaphore'
require 'async/http/internet/instance'
require 'base64'
require 'net/http'
require 'uri'

require 'mvnrepocopy/storage'
require 'mvnrepocopy/progress'
require 'mvnrepocopy/sanitize_pom'

module Mvnrepocopy
  class UploadMaven
    def initialize(url, server, concurrency, filter, user: nil, passwd: nil, dry_run: false)
      @url = url
      @server = server
      @concurrency = concurrency
      @dry_run = dry_run
      @filter_regex = filter ? Regexp.new(filter) : nil
      @storage = Storage.instance
      @log = @storage
      @sanitize_pom = SanitizePom.new

      @basic_headers = (user && passwd) ? [['Authorization', "Basic #{basic_auth(user, passwd)}"]] : []
    end

    def upload()
      package_dirs = find_package_dirs

      barrier = Async::Barrier.new
      semaphore = Async::Semaphore.new(@concurrency, parent: barrier)
      progress = Progress.new(package_dirs.length, 20)

      Sync do
        package_dirs.map do |dir|
          semaphore.async do
            upload_dir(dir, barrier)
            progress.inc
          rescue => e
            @log.error "Error uploading package '#{dir}': #{e}"
            raise
          end
        end.map(&:wait)
      ensure
        barrier.stop
      end
    end

    private #------------------------------------

    def upload_dir(dir, barrier)
      files = Dir.glob(File.join(dir,'*.pom')).concat(Dir.glob(File.join(dir, '*.jar')))

      files.each do |file|
        if exists_on_server?(file, barrier)
          @log.debug "Skipped #{file} - already exists on server"
          next
        end

        next if @dry_run

        contents = read_file(file)

        upload_file(file, contents, barrier)
      end
    end

    def find_package_dirs()
      Dir.glob('**/*.pom', base: @storage.repodir.path)
        .select{|f| !@filter_regex or f.match(@filter_regex)}
        .map{|f| File.join(@storage.repodir.path, File.dirname(f))}
    end

    def read_file(file)
      if(file.end_with?(".pom"))
        @sanitize_pom.sanitize_pom(IO.read(file))
      else
        IO.read(file)
      end
    end

    def upload_file(path, contents, barrier)
      url = "#{@url}/#{remotepath(path)}"
      headers = @basic_headers #.concat([['Content-Length', contents.length.to_s]])

      response = barrier.async do
        internet = Async::HTTP::Internet.instance
        internet.put(url, headers, contents)
      #ensure
        #internet.close
      end.wait

      case response.status
      in (200..299)
        @log.debug "Uploaded #{path}"
      else
        @log.error "Upload of #{path} failed with status #{response.status}"
        if(is_text_type?(response.headers['content-type']))
          @log.debug "Error response fron #{path}: #{response.read}"
        end
      end

      response.status
    end

    def is_text_type?(content_type)
      not ['text/', '/json', '/xml'].select{|part| content_type.include? part }.empty?
    end

    def exists_on_server?(path, barrier)
      url = "#{@url}/#{remotepath(path)}"

      # Async::HTTP has problems with HEAD requests, so we have to sacrifice some performance here.
      # See https://github.com/socketry/async-http/issues/125
      uri = URI(url)
      headers = @basic_headers.to_h
      status = nil
      Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == "https")) do |http|
        status = http.head(uri.path, headers).code
      end

      #@log.debug "HEAD #{url} => #{status}"
      status.to_i == 200
    end

    def remotepath(localpath)
      localpath.delete_prefix(@storage.repodir.path)
    end

    def basic_auth(user, passwd)
      Base64.strict_encode64("#{user}:#{passwd}")
    end
  end
end
