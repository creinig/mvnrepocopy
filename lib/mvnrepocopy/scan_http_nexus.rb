require_relative 'scan_http'

module Mvnrepocopy
  class ScanHttpNexus < ScanHttp
    def initialize(url, reponame, concurrency, verbose)
      @browseurl = "#{url.sub(%r{/+$}, '')}/service/rest/repository/browse/#{reponame}"
      @downloadurl = "#{url.sub(%r{/+$}, '')}/repository/#{reponame}"

      super(@browseurl, concurrency, verbose)
    end

    protected #----------------------

    def sanitize_link(link, current_url)
      return link if link.start_with?(@downloadurl)
      return link if link.start_with?(@browseurl)

      return "#{current_url.sub(%r{/+$}, '')}/#{link}" if link.match(%r{^(\w+\.)*\w+/?$}) 

      nil
    end
  end
end
