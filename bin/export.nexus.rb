#!/usr/bin/env ruby

require "bundler/setup"

require "mvnrepocopy/export_nexus_config"
require "mvnrepocopy/mirror_http_nexus"
require "mvnrepocopy/storage"

options = Mvnrepocopy::ExportNexusConfig.new.parse(ARGV)
log = Mvnrepocopy::Storage.instance
log.setup(options.repo, :export_nexus, options.verbose)
log.info "Detailed information will be written to #{log.logfile_name}"

mirror = Mvnrepocopy::MirrorHttpNexus.new(options.url, options.repo, options.concurrency, options.cache, dry_run: options.dry_run,
  filter: options.filter)
download_urls = mirror.scan_recursive

log.info "Found #{download_urls.length} files"
pp download_urls if Mvnrepocopy::Storage.instance.debug?

log.info "Downloading files"
mirror.download_files(download_urls)
