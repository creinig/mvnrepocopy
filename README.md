# Mvnrepocopy

Set of commandline tools for copying maven repositories between remote hosts. The workflow is designed to allow you to also merge or split repositories while you're at it.

## Installation

Dependencies are managed by [bundler](https://bundler.io), so to install everything needed you just have to run `bundle install` in this directory.

## Usage

### export_nexus.rb

`bin/export.nexus.rb` exports a maven repository from a [nexus 3](https://www.sonatype.com/products/sonatype-nexus-repository) server to the local file system.
Since this can take a while, the script provides options for parallel transfer (`-j`)and local caching of the remote directory structure (`--cache`), and will
not re-transfer already downloaded files (i.e. will simply resume after an aborted run). See `bin/export.nexus.rb --help` for all available options.

Example usage:

```bash
bin/export.nexus.rb --url https://nexus.internal.mycompany.com/nexus --repo public -j 8 --cache

bin/export.nexus.rb --url https://nexus.internal.mycompany.com/nexus --repo thirdparty -j 8 --cache --filter org/apache/commons-lang3
```

### upload.maven.rb

`bin/upload.maven.rb` uploads a local maven repository to a remote maven repository. It has been tested with Azure DevOps Artifacts so far, but should work with 
any repository using HTTP basic auth for authentication.

The supported options are similar to those of `bin/export.nexus.rb` and you'll get the details by running `bin/upload.maven.rb --help`

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake` to run style analysis and the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/creinig/mvnrepocopy.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
