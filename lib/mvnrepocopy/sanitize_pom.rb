require 'rchardet'

require 'mvnrepocopy/progress'
require 'mvnrepocopy/storage'

module Mvnrepocopy
  # Some maven repositories *cough*AzDO*cough* seem to have serious problems
  # with certain constructs in POM files => we automatically remove these
  # to be sure
  class SanitizePom
    def initialize(reponame)
      @reponame = reponame
      @storage = Storage.instance
      @log = @storage
    end

    def sanitize_poms_in_repo
      poms = find_poms
      progress = Progress.new(poms.length)

      poms.each do |pom|
        sanitize(pom)
        progress.inc
      end
    end

    private #------------------------

    def sanitize(pom)
      begin
        contents = IO.read(pom)
        contents = fix_encoding(contents)
        contents.gsub! %r{<packaging>pom</packaging>}, ''
        IO.write(pom, contents, external_encoding: 'UTF-8')
      rescue 
        @log.error "Failed sanitizing '#{pom}'"
        raise
      end
    end

    def find_poms()
      Dir.glob('**/*.pom', base: @storage.repodir.path)
        .map{|f| File.join(@storage.repodir.path, f)}
    end

    # POMs may be in different encodings. Using the wrong one will trip up gsub() & co
    def fix_encoding(str)
      return str if str.valid_encoding?

      cd = CharDet.detect(str)
      str.force_encoding cd['encoding']
      str
    end
  end
end

