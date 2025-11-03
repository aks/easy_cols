# frozen_string_literal: true

require_relative 'lib/easy_cols/version'

Gem::Specification.new do |spec|
  spec.name          = 'easy_cols'
  spec.version       = EasyCols::VERSION
  spec.authors       = ['Alan K. Stebbens']
  spec.email         = ['aks@stebbens.org']

  spec.summary       = 'A powerful command-line tool for extracting and processing columns from structured text data'
  spec.description   = <<~DESC
    EasyCols is a flexible command-line utility for extracting specific columns from
    structured text data in various formats (CSV, TSV, table, plain text). It supports
    sophisticated parsing options including quote handling, comment stripping, header
    processing, and language-specific comment patterns.  It can be used on both files and STDIN.
  DESC
  spec.homepage      = 'https://github.com/aks/easy_cols'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = ['easy_cols', 'ec']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.2.0'

  spec.add_dependency 'csv', '~> 3.0'
  spec.add_dependency 'optparse', '~> 0.1'

  spec.add_development_dependency 'fuubar', '~> 2.5'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.20'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'rake', '~> 13.0'

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri'] = 'https://github.com/aks/easy_cols'
  spec.metadata['changelog_uri']   = 'https://github.com/aks/easy_cols/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/aks/easy_cols/issues'
end
