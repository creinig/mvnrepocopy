require 'pp'
require 'async'
require 'async/barrier'
require 'async/semaphore'
require 'async/http/internet/instance'
require 'nokogiri'

require 'mvnrepocopy/storage'

module Mvnrepocopy
  class ScanHttp
    def initialize(baseurl, concurrency, verbose)
      @baseurl = baseurl
      @verbose = verbose
      @barrier = Async::Barrier.new
      @semaphore = Async::Semaphore.new(concurrency, parent: @barrier)
      @storage = Storage.instance
      @log = @storage
    end

    # Fetch the given repository index, parse the response and recursively scan all relative links
    #
    # returns:: the list of download URLs found
    def scan_recursive()
      urls = []
      Sync do
        urls = @semaphore.async do
          scan(@baseurl)
        end.wait
      ensure
        @barrier.stop
      end

      # only return download URLs
      urls.reject{|u| is_index?(u)}
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

    private # ----------------

    # Fetch the given URL, parse the response and recursively scan all relative links in the response HTML
    #
    # returns:: the list of found download URLs 
    def scan(url)
      internet = Async::HTTP::Internet.instance
      scanned = []

      begin
        @log.debug "Request to #{url}"
        response = internet.get(url)
        if(is_redirect?(response))
          @log.debug "  Redirect (#{response.status}) to #{response.headers['location']}"
          response = internet.get(response.headers['location'])
        end

        @log.debug "  Response for #{url}: #{response.status}"

        if((response.status == 200) && response.headers['content-type']&.include?("html"))
          relative_links = extract_links(response.read, url)
          relative_links.each do |url|
            if(is_index?(url)) 
              @semaphore.async do
                scan(url)
              end.wait.each {|link| scanned << link}
            else
              scanned << url
            end
          end
        else
          @log.error "  Response for #{url}: #{response.status}"
        end
      end

      scanned
    end

    def is_redirect?(response)
      (300..399).include?(response.status) and response.headers['location']
    end

    def extract_links(html, url)
      paths = []

      doc = Nokogiri(html)
      refs = doc.xpath("//a/@href").to_a.map{|a| a.value}

      pp refs if @log.debug?
      refs
        .map {|path| sanitize_link(path, url)}
        .select {|path| path}
    end
  end
end
