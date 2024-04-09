require 'open3'
require 'async'
require 'async/barrier'
require 'async/semaphore'
require 'base64'
require 'uri'
require 'httpclient'

require 'mvnrepocopy/storage'
require 'mvnrepocopy/progress'
require 'mvnrepocopy/sanitize_pom'

module Mvnrepocopy
  class UploadMaven
    def initialize(url, server, concurrency, filter, user: nil, passwd: nil, dry_run: false)
      @url = url
      @server = server
      @user = user
      @passwd = passwd
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

      http = HTTPClient.new(:force_basic_auth => true)
      http.set_auth(nil, @user, @passwd) if(@user && @passwd)
      http.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE 

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
      end
    end

    private #------------------------------------

    def upload_dir(dir, http)
      files = Dir.glob(File.join(dir,'*.pom')).concat(Dir.glob(File.join(dir, '*.jar')))

      files.each do |file|
        if exists_on_server?(file, http)
          @log.debug "Skipped #{file} - already exists on server"
          next
        end

        next if @dry_run

        contents = read_file(file)

        upload_file(file, contents, http)
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

    def upload_file(path, contents, http)
      url = "#{@url}/#{remotepath(path)}"

      response = http.put(url, :body => contents)

      case response.status_code
      in (200..299)
        @log.debug "Uploaded #{path}"
      else
        @log.error "Upload of #{path} failed with status #{response.status_code}"
        if(is_text_type?(response.content_type))
          @log.debug "Error response fron #{path}: #{response.body}"
        end
      end

      response.status_code
    end

    def is_text_type?(content_type)
      content_type && ! ['text/', '/json', '/xml'].select{|part| content_type.include? part }.empty?
    end

    def exists_on_server?(path, http)
      url = "#{@url}/#{remotepath(path)}"

      response = http.head(url)

      #@log.debug "HEAD #{url} => #{status}"
      response.status_code.to_i == 200
    end

    def remotepath(localpath)
      localpath.delete_prefix(@storage.repodir.path)
    end

    def basic_auth(user, passwd)
      Base64.strict_encode64("#{user}:#{passwd}")
    end
  end
end
