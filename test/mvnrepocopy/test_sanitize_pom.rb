require 'mvnrepocopy/sanitize_pom'

require 'minitest'
require 'nokogiri'

module Mvnrepocopy

  class TestSanitizePom < Minitest::Test
    def setup
      @sanitizer = SanitizePom::new
    end

    def test_packaging_jar
      @sanitizer.stub :contains_jar?, true do
        pretty = Nokogiri::XML(POM_JAR, &:noblanks).to_xml
        assert_equal pretty, @sanitizer.sanitize_pom('./foo.pom', POM_JAR)
        assert_equal pretty, @sanitizer.sanitize_pom('./foo.pom', POM_POM)
        assert_equal pretty, @sanitizer.sanitize_pom('./foo.pom', POM_DEFAULT)
      end
    end

    def test_packaging_pom
      @sanitizer.stub :contains_jar?, false do
        pretty = Nokogiri::XML(POM_POM, &:noblanks).to_xml
        assert_equal pretty, @sanitizer.sanitize_pom('./foo.pom', POM_JAR)
        assert_equal pretty, @sanitizer.sanitize_pom('./foo.pom', POM_POM)
        assert_equal pretty, @sanitizer.sanitize_pom('./foo.pom', POM_DEFAULT)
      end
    end

    POM_JAR="""
    <project>
      <name>foo</name>
      <groupId>foo.bar</groupId>
      <artifactId>baz</artifactId>
      <version>1.2.3</version>
      <packaging>jar</packaging>
    </project>
    """

    POM_POM = POM_JAR.sub('<packaging>jar</packaging>', '<packaging>pom</packaging>')
    POM_DEFAULT = POM_JAR.sub('<packaging>jar</packaging>', '')

  end

end
