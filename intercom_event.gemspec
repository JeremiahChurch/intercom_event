$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "intercom_event/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "intercom_event"
  s.version     = IntercomEvent::VERSION
  s.license     = "MIT"
  s.authors     = ["Jeremiah Church"]
  s.email       = "jeremiahchurch@gmail.com"
  s.homepage    = "https://github.com/tongboy/intercom_event"
  s.summary     = "Intercom webhook integration for Rails applications."
  s.description = "Intercom webhook integration for Rails applications."

  s.files       = `git ls-files`.split("\n")

  s.add_dependency "activesupport", ">= 3.1"

  s.add_development_dependency "rails", [">= 3.1", "<5.0"]
  s.add_development_dependency "rake", "< 11.0"
  s.add_development_dependency "rspec-rails", "~> 2.12"
  s.add_development_dependency "webmock", "~> 1.9"
end
