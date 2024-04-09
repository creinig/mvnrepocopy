#!/usr/bin/env ruby

require 'bundler/setup'

require 'mvnrepocopy/export_nexus_config'
require 'mvnrepocopy/scan_http_nexus'

options = Mvnrepocopy::ExportNexusConfig.new.parse(ARGV)


scanner = Mvnrepocopy::ScanHttpNexus.new(options.url, options.repo, options.concurrency, options.verbose)
download_urls = scanner.scan_recursive()

pp download_urls
# DONE: async PoC w/ HTTP requests
# TODO: local workdir mgmt
# TODO: HTML link parsing
# TODO: download tasks
# TODO: error & status logging & persisting
# XXX: config file
# XXX: support for incremental downloads



