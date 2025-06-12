#!/usr/bin/env ruby

require "bundler/setup"

require "mvnrepocopy/upload_maven_config"
require "mvnrepocopy/upload_maven"
require "mvnrepocopy/storage"
require "mvnrepocopy/sanitize_pom"

options = Mvnrepocopy::UploadMavenConfig.new.parse(ARGV)
log = Mvnrepocopy::Storage.instance
log.setup(options.repo, :upload_maven, options.verbose)
log.info "Detailed information will be written to #{log.logfile_name}"

log.info "Uploading packages to #{options.url}"
upload = Mvnrepocopy::UploadMaven.new(options.url, options.repo, options.concurrency, options.filter, options.cache, user: options.user,
  passwd: options.pass, dry_run: options.dry_run)
upload.upload