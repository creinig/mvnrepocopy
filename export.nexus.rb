#!/usr/bin/env ruby

require 'bundler/setup'

require 'mvnrepocopy/export_nexus_config'
require 'mvnrepocopy/mirror_http_nexus'
require 'mvnrepocopy/storage'

include Mvnrepocopy

options = ExportNexusConfig.new.parse(ARGV)
log = Storage.instance
log.setup(options.repo, :export_nexus, options.verbose)

log.info "Scanning for download links in repo '#{options.repo}' at #{options.url}"
mirror = MirrorHttpNexus.new(options.url, options.repo, options.concurrency, options.verbose)
download_urls = mirror.scan_recursive()

log.info "Found #{download_urls.length} files"
pp download_urls if Storage.instance.debug?
# DONE: async PoC w/ HTTP requests
# DONE: local workdir mgmt
# DONE: HTML link parsing
# TODO: download tasks
# TODO: progress output
# DONE: error & status logging & persisting
# XXX: config file, global config object?
# TODO: support for incremental downloads



