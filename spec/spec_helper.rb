require 'webmock/rspec'
require File.expand_path('../../lib/intercom_event', __FILE__)
Dir[File.expand_path('../spec/support/**/*.rb', __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.order = 'random'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    @event_retriever = IntercomEvent.event_retriever
    @notifier = IntercomEvent.backend.notifier
    IntercomEvent.backend.notifier = @notifier.class.new
  end

  config.after do
    IntercomEvent.event_retriever = @event_retriever
    IntercomEvent.backend.notifier = @notifier
  end
end
