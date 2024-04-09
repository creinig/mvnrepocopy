require "pp"
require "async"
require "async/barrier"
require "async/semaphore"
require "nokogiri"
require "httpclient"

require "mvnrepocopy/storage"
require "mvnrepocopy/progress"

module Mvnrepocopy
  class MirrorHttp
    def initialize(baseurl, concurrency, cache, dry_run: false, filter: nil)
      @baseurl = baseurl
      @cache = cache
      @concurrency = concurrency
      @dry_run = dry_run
      @filter = filter
      @storage = Storage.instance
      @log = @storage

      @http = HTTPClient.new
      @http.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @http.keep_alive_timeout = 60
    end

    # Fetch the given repository index, parse the response and recursively scan all relative links
    #
    # returns:: the list of download URLs found
    def scan_recursive()
      if (@cache)
        urls = @storage.read_cache("download_urls")

        if (urls && !urls.empty?)
          @log.info "Download URLs read from cache file"
          return urls
        end
      end

      @log.info "Scanning for download links in repo #{@baseurl}"
      Sync do
        urls = scan(@baseurl)
        @storage.write_cache("download_urls", urls)
        urls
      end
    end

    # Download all files represented by the given array of URLs
    def download_files(urls)
      urls = urls.select { |u| u.match? @filter } if @filter

      barrier = Async::Barrier.new
      semaphore = Async::Semaphore.new(@concurrency, parent: barrier)
      progress = Progress.new(urls.length)

      Sync do
        urls.map do |url|
          semaphore.async do
            download(url)
            progress.inc
          end
        end.map(&:wait)
      ensure
        barrier.stop
      end
    end

    protected #---------------------

    # Sanitize / canonicalize the given link or return +nil+ if it should not be followed
    def sanitize_link(link, current_url)
      link
    end

    # Check whether the given link points to an index page that should be followed recursively
    def is_index?(link)
      link.end_with?("/")
    end

    # Convert the given URL to a path relative to the repo
    def to_repopath(url)
      url.delete_prefix(@baseurl)
    end

    private # ----------------

    # Fetch the given URL, parse the response and "recursively" scan all
    # relative links in the response HTML
    #
    # returns:: the list of found download URLs
    def scan(url)
      index_urls = [url]
      download_urls = []
      barrier = Async::Barrier.new
      semaphore = Async::Semaphore.new(@concurrency, parent: barrier)
      progress = Progress.new

      while !index_urls.empty?
        new_links = index_urls.map do |index|
          semaphore.async do
            progress.inc

            response = @http.get(index, :follow_redirect => true)
            if response.status_code != 200
              @log.error "Error reading index page '#{index}': status #{response.status_code}"
              next
            end

            extract_links(response.body, index)
          rescue => e
            @log.error "Error reading index page '#{index}': #{e}"
          end
        end.map(&:wait).flatten

        index_urls = new_links.select { |l| is_index?(l) }
        download_urls.concat(new_links.select { |l| not is_index?(l) })
      end

      download_urls
    end

    def extract_links(html, url)
      doc = Nokogiri(html)
      refs = doc.xpath("//a/@href").to_a.map { |a| a.value }

      # pp refs if @log.debug?
      refs
        .map { |path| sanitize_link(path, url) }
        .select { |path| path }
    end

    def download(url)
      localfile = @storage.mkdirs_for(to_repopath(url))

      if (File.exist?(localfile))
        @log.debug "Skipping #{url} - already exists locally"
        return
      end

      return if @dry_run

      response = @http.get(url, :follow_redirect => true)
      if response.status_code != 200
        @log.error "Error downloading file '#{url}': status #{response.status_code}"
      else
        IO.write(localfile, response.body)
        @log.debug "Downloaded #{url}"
      end
    end
  end
end
