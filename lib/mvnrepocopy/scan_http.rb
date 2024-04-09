module Mvnrepocopy
  class ScanHttp
    def initialize(concurrency, verbose)
      @verbose = verbose
      @barrier = Async::Barrier.new
      @semaphore = Async::Semaphore.new(concurrency, parent: @barrier)
    end

    # Fetch the given repository index, parse the response and recursively scan all relative links
    #
    # returns:: the list of scanned URLs 
    def scan_recursive(baseurl)
      urls = []
      Sync do
        urls = @semaphore.async do
          scan(baseurl)
        end.wait
      ensure
        @barrier.stop
      end

      urls
    end

    private # ----------------

    # Fetch the given URL, parse the response and recursively scan all relative links in the response HTML
    #
    # returns:: the list of scanned URLs 
    def scan(url)
      internet = Async::HTTP::Internet.instance
      scanned = [url]

      begin
        puts "Request to #{url}"
        response = internet.get(url)
        if(is_redirect?(response))
          puts "Redirect (#{response.status}) to #{response.headers['location']}"
          response = internet.get(response.headers['location'])
        end

        puts "Response for #{url}: "
        pp response
      end

      scanned
    end

    def is_redirect?(response)
      response.status in (300..399) and response.headers['location']
    end

  end
end
