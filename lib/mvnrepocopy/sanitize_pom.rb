require 'rchardet'

require 'mvnrepocopy/progress'
require 'mvnrepocopy/storage'

module Mvnrepocopy
  # Some maven repositories *cough*AzDO*cough* seem to have serious problems
  # with certain constructs in POM files => we automatically remove these
  # to be sure
  class SanitizePom
    def sanitize_pom(file, contents)
      contents = fix_encoding(contents)
      fix_packaging(file, contents)
    end

    private #------------------------

    # POMs may be in different encodings. Using the wrong one will trip up gsub() & co.
    # We also want to fix the encoding to UTF-8 to avoid problems with the remote repo
    def fix_encoding(str)
      return str if str.valid_encoding?

      cd = CharDet.detect(str)
      str.force_encoding cd['encoding']
      str.encode('UTF-8')
    end

    # Should be rare, but I've encountered POMs that were for a JAR, but had packaging "pom".
    # AzDO artifacts rejects those with a weirdly nonspecific XML parser exception
    def fix_packaging(file, contents)
      has_jar = !(Dir.glob(File.join(File.dirname(file), "*.jar")).empty?)

      if has_jar
        contents.gsub(%r{<packaging>pom</packaging>}, '<packaging>jar</packaging>')
      else
        contents
      end
    end
  end
end

