require 'pp'
require 'async'
require 'async/barrier'
require 'async/semaphore'
require 'async/http/internet/instance'
require 'nokogiri'

require 'mvnrepocopy/storage'

module Mvnrepocopy
  class MirrorHttp
    def initialize(baseurl, concurrency, verbose, cache)
      @baseurl = baseurl
      @verbose = verbose
      @cache = cache
      @concurrency = concurrency
      @storage = Storage.instance
      @log = @storage
    end

    # Fetch the given repository index, parse the response and recursively scan all relative links
    #
    # returns:: the list of download URLs found
    def scan_recursive()
      if(@cache) 
        urls = @storage.read_cache('download_urls')

        if(urls && !urls.empty?)
          @log.info "Download URLs read from cache file"
          return urls
        end
      end

      @log.info "Scanning for download links in repo #{@baseurl}"
      Sync do 
        urls = scan(@baseurl)

        # only return download URLs
        urls.reject{|u| is_index?(u)}

        @storage.write_cache('download_urls', urls)
        urls
      end
    end

    # Download all files represented by the given array of URLs
    def download_files(urls)
      barrier = Async::Barrier.new
      semaphore = Async::Semaphore.new(@concurrency, parent: barrier)

      Sync do
        urls.map do |url|
          semaphore.async do
            download(url)
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

    # Fetch the given URL, parse the response and recursively scan all relative links in the response HTML
    #
    # returns:: the list of found download URLs 
    def scan(url)
      request(url) do |url, response|
        if(response.headers['content-type']&.include?("html"))
          relative_links = extract_links(response.read, url)

          relative_links.map do |url|
            if(is_index?(url)) 
              scan(url)
            else
              [url]
            end
          end.flatten
        else
          @log.error "  Response for #{url}: Content-Type is #{response.headers['content-type']}"
          []
        end
      end
    end

    def is_redirect?(response)
      (300..399).include?(response.status) and response.headers['location']
    end

    def extract_links(html, url)
      doc = Nokogiri(html)
      refs = doc.xpath("//a/@href").to_a.map{|a| a.value}

      pp refs if @log.debug?
      refs
        .map {|path| sanitize_link(path, url)}
        .select {|path| path}
    end

    def download(url)
      localpath = to_repopath(url)

      request(url) do |url, response|
        localfile = @storage.mkdirs_for(localpath)
        response.save(localfile)
        puts "Downloaded #{url} to #{localfile}"
      rescue => e
        pp e
        exit
      end
    end

    def request(url, &success_handler)
      internet = Async::HTTP::Internet.instance

      @log.debug "Request to #{url}"
      response = internet.get(url)

      if(is_redirect?(response))
        @log.debug "  Redirect (#{response.status}) to #{response.headers['location']}"
        response = internet.get(response.headers['location'])
      end

      @log.debug "  Response for #{url}: #{response.status}"

      if(response.status == 200)
        success_handler.yield(url, response)
      else
        @log.error "  Response for #{url}: #{response.status}"
      end
    end
  end
end
