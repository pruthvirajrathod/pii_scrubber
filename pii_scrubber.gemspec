# frozen_string_literal: true

require_relative 'lib/pii_scrubber/version'

Gem::Specification.new do |spec|
  spec.name          = 'pii_scrubber'
  spec.version       = PiiScrubber::VERSION
  spec.authors       = ['Pruthviraj Rathod']
  spec.homepage      = 'https://github.com/pruthvirajrathod/pii_scrubber'
  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/pruthvirajrathod/pii_scrubber'

  spec.summary       = 'Fast, flexible international PII & secret redaction and reversible LLM anonymization for Ruby and Rails.'
  spec.description   = 'Detects and sanitizes Personally Identifiable Information (emails, phone numbers, credit cards, SSNs, IP addresses, IBANs, UK NINOs, Canadian SINs, Indian PAN & Aadhaar) and API secrets / Database connection strings in strings, hashes, logs, Faraday HTTP requests, and Rack. Features a bidirectional Vault for LLM prompt anonymization and response restoration.'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.files         = Dir['{exe,lib}/**/*', 'README.md', 'LICENSE.txt', 'Rakefile']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'logger', '>= 1.4'

  spec.add_development_dependency 'bundler', '>= 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
end
