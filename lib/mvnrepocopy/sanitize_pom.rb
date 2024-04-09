require 'rchardet'

require 'mvnrepocopy/progress'
require 'mvnrepocopy/storage'

module Mvnrepocopy
  # Some maven repositories *cough*AzDO*cough* seem to have serious problems
  # with certain constructs in POM files => we automatically remove these
  # to be sure
  class SanitizePom
    def sanitize_pom(contents)
      contents = fix_encoding(contents)
      contents.gsub(%r{<packaging>pom</packaging>}, '')
    end

    private #------------------------

    # POMs may be in different encodings. Using the wrong one will trip up gsub() & co
    def fix_encoding(str)
      return str if str.valid_encoding?

      cd = CharDet.detect(str)
      str.force_encoding cd['encoding']
      str
    end
  end
end

