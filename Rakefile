# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require_relative 'lib/easy_cols/version'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :version do
  desc 'Show current version'
  task :current do
    puts "Current version: #{EasyCols::VERSION}"
  end

  def bump_version(type)
    version_file = File.join(__dir__, 'lib', 'easy_cols', 'version.rb')
    content = File.read(version_file)

    current_version = EasyCols::VERSION
    major, minor, patch = current_version.split('.').map(&:to_i)

    case type
    when :major
      major += 1
      minor = 0
      patch = 0
    when :minor
      minor += 1
      patch = 0
    when :patch
      patch += 1
    else
      raise "Unknown version type: #{type}"
    end

    new_version = "#{major}.#{minor}.#{patch}"

    # Update version file
    new_content = content.sub(/VERSION = ['"]#{current_version}['"]/, "VERSION = '#{new_version}'")
    File.write(version_file, new_content)

    puts "Version bumped from #{current_version} to #{new_version}"
    puts "Updated #{version_file}"
    puts "\nDon't forget to:"
    puts "  git add #{version_file}"
    puts "  git commit -m 'Bump version to #{new_version}'"

    new_version
  end

  desc 'Bump major version (x.0.0)'
  task :major do
    bump_version(:major)
  end

  desc 'Bump minor version (0.x.0)'
  task :minor do
    bump_version(:minor)
  end

  desc 'Bump patch version (0.0.x)'
  task :patch do
    bump_version(:patch)
  end
end

# Override Bundler's release task with our custom one
begin
  Rake::Task['release'].clear
rescue RuntimeError
  # Task doesn't exist yet, that's fine
end

desc 'Create and push release tag for current version'
task :release do
  require 'open3'

  version = EasyCols::VERSION
  tag_name = "v#{version}"

  # Check we're on main branch
  current_branch, _ = Open3.capture2('git', 'rev-parse', '--abbrev-ref', 'HEAD')
  current_branch = current_branch.strip
  unless current_branch == 'main'
    raise "Must be on main branch to release. Current branch: #{current_branch}"
  end

  # Check for uncommitted changes
  status, _ = Open3.capture2('git', 'status', '--porcelain')
  unless status.strip.empty?
    raise "Working directory has uncommitted changes. Commit or stash them first."
  end

  # Check if tag already exists
  tag_check, _ = Open3.capture2('git', 'tag', '-l', tag_name)
  unless tag_check.strip.empty?
    raise "Tag #{tag_name} already exists. Did you forget to bump the version?"
  end

  # Check if we're up to date with remote
  Open3.capture2('git', 'fetch', 'origin')
  local_commit, _ = Open3.capture2('git', 'rev-parse', 'HEAD')
  remote_commit, _ = Open3.capture2('git', 'rev-parse', 'origin/main')
  if local_commit.strip != remote_commit.strip
    raise "Local main is not up to date with origin/main. Please pull or push first."
  end

  # Create and push tag
  puts "Creating release tag #{tag_name}..."
  system('git', 'tag', '-a', tag_name, '-m', "Release #{tag_name}") or raise "Failed to create tag"
  puts "Pushing tag to origin..."
  system('git', 'push', 'origin', tag_name) or raise "Failed to push tag"

  puts "\n✓ Release tag #{tag_name} created and pushed!"
  puts "CI will automatically create the GitHub release and publish to RubyGems."
end

