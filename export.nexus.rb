#!/usr/bin/env ruby

require 'bundler/setup'
require 'mvnrepocopy/export_nexus_config'

options = Mvnrepocopy::ExportNexusConfig.parse(ARGV)

puts "Looks good: #{options}"
