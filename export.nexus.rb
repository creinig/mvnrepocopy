#!/usr/bin/env ruby

require 'bundler/setup'
require 'mvnrepocopy/export_nexus_config'

options = Mvnrepocopy::ExportNexusConfig.new.parse(ARGV)

# TODO: async PoC w/ HTTP requests
# TODO: local workdir mgmt
# TODO: HTML link parsing
# TODO: download tasks
# TODO: error & status logging & persisting
# XXX: config file
# XXX: support for incremental downloads
puts "Looks good: #{options}"
