#!/usr/bin/env ruby

require 'bundler/setup'
require 'pp'
require 'async'
require 'async/barrier'
require 'async/semaphore'
require 'async/http/internet/instance'

require 'mvnrepocopy/export_nexus_config'
require 'mvnrepocopy/scan_http'

options = Mvnrepocopy::ExportNexusConfig.new.parse(ARGV)


baseurl = "#{options.url.sub(%r{/+$}, '')}/service/rest/repository/browse/#{options.repo}"
scanner = Mvnrepocopy::ScanHttp.new(options.concurrency, options.verbose)
scanner.scan_recursive(baseurl)

# TODO: async PoC w/ HTTP requests
# TODO: local workdir mgmt
# TODO: HTML link parsing
# TODO: download tasks
# TODO: error & status logging & persisting
# XXX: config file
# XXX: support for incremental downloads



