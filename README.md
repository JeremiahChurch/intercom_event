# intercom_event

intercom_event is a port of the excellent stripe_event to support intercom webhooks. Define subscribers to handle specific event types. Subscribers can be a block or an object that responds to `#call`.

contributions are very welcome!

## Install

```ruby
# Gemfile
gem 'intercom_event', git: 'https://github.com/Tongboy/intercom_event'
```

setup a webhook URL in [intercom dev center](https://app.intercom.com/developers/_)

ultrahook or ngrok can be used for dev/testing

```ruby
# config/routes.rb
mount IntercomEvent::Engine, at: '/my-chosen-path' # provide a custom path that matches what you setup in intercom
```

## Usage

```ruby
# config/initializers/Intercom.rb
IntercomEvent.configure do |events|
  # https://developers.intercom.com/v2.0/reference#topics - has possible options
  events.subscribe 'conversation.' do |event|
    # Define subscriber behavior based on the event object
  end

  events.all do |event|
    puts event.topic
    puts event.data.type
    puts event.data.item.type
    # Handle all event types - logging, etc.
  end
end
```

### Subscriber objects that respond to #call

```ruby
class CustomerCreated
  def call(event)
    # Event handling
  end
end

class BillingEventLogger
  def initialize(logger)
    @logger = logger
  end

  def call(event)
    @logger.info "Convo:#{event.type}:#{event.id}"
  end
end
```

```ruby
IntercomEvent.configure do |events|
  events.all BillingEventLogger.new(Rails.logger)
  events.subscribe 'user.created', CustomerCreated.new
end
```

### Subscribing to a namespace of event types

```ruby
IntercomEvent.subscribe 'conversation.user.' do |event|
  # Will be triggered for any conversation.user.* events
end
```

## Securing your webhook endpoint

At this time we aren't consuming/working with the intercom Hub secret - we should

## Configuration

```

If you'd like to ignore particular webhook events (perhaps to ignore test webhooks in production, or to ignore webhooks for a non-paying customer), you can do so by returning `nil` in you custom `event_retriever`. For example:

```ruby
IntercomEvent.event_retriever = lambda do |params|
  return nil if Rails.env.production? && !params[:livemode]
  Intercom::Event.retrieve(params[:id])
end
```

## Without Rails

IntercomEvent can be used outside of Rails applications as well. Here is a basic Sinatra implementation:

```ruby
require 'json'
require 'sinatra'
require 'intercom_event'

IntercomEvent.subscribe 'user.created' do |event|
  # Look ma, no Rails!
end

post '/_billing_events' do
  data = JSON.parse(request.body.read, symbolize_names: true)
  IntercomEvent.instrument(data)
  200
end
```

## Testing

Verifying the behavior of IntercomEvent subscribers can be done fairly easily by stubbing out the HTTP request used to authenticate the webhook request. Tools like [Webmock](https://github.com/bblimke/webmock) and [VCR](https://github.com/vcr/vcr) work well. [RequestBin](http://requestb.in/) is great for collecting the payloads. For exploratory phases of development, [UltraHook](http://www.ultrahook.com/) and other tools can forward webhook requests directly to localhost. You can check out [test-hooks](https://github.com/invisiblefunnel/test-hooks), an example Rails application to see how to test IntercomEvent subscribers with RSpec request specs and Webmock. A quick look:

```ruby
# spec/requests/billing_events_spec.rb
require 'spec_helper'

describe "Billing Events" do
  def stub_event(fixture_id, status = 200)
    stub_request(:get, "https://api.Intercom.com/v1/events/#{fixture_id}").
      to_return(status: status, body: File.read("spec/support/fixtures/#{fixture_id}.json"))
  end

  describe "customer.created" do
    before do
      stub_event 'evt_customer_created'
    end

    it "is successful" do
      post '/_billing_events', id: 'evt_customer_created'
      expect(response.code).to eq "200"
      # Additional expectations...
    end
  end
end
```

### Versioning

Semantic Versioning 2.0 as defined at <http://semver.org>.

### License

[MIT License](https://github.com/tongboy/intercom_event/blob/master/LICENSE.md).

### TODO
* fix specs - they are *very* broken and haven't been ported from stripe_event
* enable intercom hub secret check
* add support for rails 4.x - intercom_event.rb instrument method needs to be modified to support the param differences
