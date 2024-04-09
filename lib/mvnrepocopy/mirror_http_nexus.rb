require_relative 'mirror_http'

module Mvnrepocopy
  class MirrorHttpNexus < MirrorHttp
    def initialize(url, reponame, concurrency, cache, dry_run: false, filter: nil)
      @browseurl = "#{url.sub(%r{/+$}, '')}/service/rest/repository/browse/#{reponame}"
      @downloadurl = "#{url.sub(%r{/+$}, '')}/repository/#{reponame}"

      super(@browseurl, concurrency, cache, dry_run: dry_run, filter: filter)
    end

    protected #----------------------

    def sanitize_link(link, current_url)
      return link if link.start_with?(@downloadurl)
      return link if link.start_with?(@browseurl)

      return "#{current_url.sub(%r{/+$}, '')}/#{link}" if link.match(%r{^([\w-]+\.)*[\w-]+/?$}) 

      nil
    end

    def to_repopath(url)
      url.delete_prefix(@downloadurl)
    end
  end
end
