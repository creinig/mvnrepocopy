#!/usr/bin/env ruby

require 'bundler/setup'

require 'mvnrepocopy/upload_maven_config'
require 'mvnrepocopy/upload_maven'
require 'mvnrepocopy/storage'

include Mvnrepocopy

options = UploadMavenConfig.new.parse(ARGV)
log = Storage.instance
log.setup(options.repo, :upload_maven, options.verbose)
log.info "Detailed information will be written to #{log.logfile_name}"

upload = UploadMaven.new(options.url, options.repo, options.server, options.concurrency)
upload.upload()

