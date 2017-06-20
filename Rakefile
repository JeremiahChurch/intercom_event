require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

if ENV['CI']
  task default: :spec
else
  task :default do
    system('bundle exec rake spec')
  end
end
