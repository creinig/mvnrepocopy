#!/usr/bin/env ruby

require 'bundler/setup'

require 'mvnrepocopy/export_nexus_config'
require 'mvnrepocopy/scan_http_nexus'
require 'mvnrepocopy/storage'

include Mvnrepocopy

options = ExportNexusConfig.new.parse(ARGV)
log = Storage.instance
log.setup(options.repo, :export_nexus, options.verbose)

log.info "Scanning for download links in repo '#{options.repo}' at #{options.url}"
scanner = ScanHttpNexus.new(options.url, options.repo, options.concurrency, options.verbose)
download_urls = scanner.scan_recursive()

log.info "Found #{download_urls.length} files"
pp download_urls if Storage.instance.debug?
# DONE: async PoC w/ HTTP requests
# TODO: local workdir mgmt
# DONE: HTML link parsing
# TODO: download tasks
# TODO: error & status logging & persisting
# XXX: config file
# XXX: support for incremental downloads



