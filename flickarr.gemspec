require_relative 'lib/flickarr/version'

Gem::Specification.new do |spec|
  spec.name    = 'flickarr'
  spec.version = Flickarr::VERSION
  spec.authors = ['Shane Becker']
  spec.email   = ['veganstraightedge@gmail.com']

  spec.summary     = 'Export and archive your Flickr photo library'
  spec.description = 'Flickarr exports and archives your Flickr photo library — photos, metadata, tags, albums, and more.'
  spec.homepage    = 'https://github.com/veganstraightedge/flickarr'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 4.0.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/veganstraightedge/flickarr'
  spec.metadata['changelog_uri']   = 'https://github.com/veganstraightedge/flickarr/blob/main/CHANGELOG.md'

  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'cgi', '~> 0.5'
  spec.add_dependency 'down', '~> 5.4'
  spec.add_dependency 'flickr', '~> 2.1'
  spec.add_dependency 'http', '~> 5.2'
  spec.add_dependency 'slugify', '~> 1.0'
end
