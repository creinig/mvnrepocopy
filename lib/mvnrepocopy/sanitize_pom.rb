require "nokogiri"
require "rchardet"

module Mvnrepocopy
  # Some maven repositories *cough*AzDO*cough* seem to have serious problems
  # with certain constructs in POM files => we automatically remove these
  # to be sure
  class SanitizePom
    def sanitize_pom(file, contents)
      contents = fix_encoding(contents)
      fix_packaging(file, contents)
    end

    def contains_jar?(dir)
      Dir.glob(File.join(dir, "*.jar")).any?
    end

    private #------------------------

    # POMs may be in different encodings. Using the wrong one will trip up gsub() & co.
    # We also want to fix the encoding to UTF-8 to avoid problems with the remote repo
    def fix_encoding(str)
      return str if str.valid_encoding?

      cd = CharDet.detect(str)
      str.force_encoding cd["encoding"]
      str.encode("UTF-8")
    end

    # Should be rare, but I've encountered POMs that were for a JAR, but had packaging "pom".
    # AzDO artifacts rejects those with a weirdly nonspecific XML parser exception
    def fix_packaging(file, contents)
      doc = Nokogiri::XML(contents, &:noblanks)
      packaging = doc.at_css("project>packaging") || doc.at_css("project>version").add_next_sibling("<packaging>pom</packaging>").first
      packaging.content = (contains_jar?(File.dirname(file)) ? "jar" : "pom")

      doc.to_xml
    end
  end
end
