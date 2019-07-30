lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'unlinked_headings/version'

Gem::Specification.new do |spec|
  spec.name          = 'unlinked_headings'
  spec.version       = UnlinkedHeadings::VERSION
  spec.authors       = ['ldss-jm']
  spec.email         = ['ldss-jm@users.noreply.github.com']

  spec.summary       = 'Process unlinked headings reports from marcive'
  spec.homepage      = 'https://github.com/ldss-jm/authority-control-unlinked-headings-prep'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_runtime_dependency 'i18n', '~> 1.6.0'
  spec.add_runtime_dependency 'sierra_postgres_utilities', '~> 0.3.0'
  spec.add_runtime_dependency 'thor', '~> 0.20.3'
end
