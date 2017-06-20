require 'rails_helper'
require 'spec_helper'

describe IntercomEvent::WebhookController do
  def stub_event(identifier, status = 200)
    stub_request(:get, "https://api.Intercom.com/v1/events/#{identifier}").
      to_return(status: status, body: File.read("spec/support/fixtures/#{identifier}.json"))
  end

  def webhook(params)
    post :event, params
  end

  routes { IntercomEvent::Engine.routes }

  it "succeeds with valid event data" do
    count = 0
    IntercomEvent.subscribe('charge.succeeded') { |evt| count += 1 }
    stub_event('evt_charge_succeeded')

    webhook id: 'evt_charge_succeeded'

    expect(response.code).to eq '200'
    expect(count).to eq 1
  end

  it "succeeds when the event_retriever returns nil (simulating an ignored webhook event)" do
    count = 0
    IntercomEvent.event_retriever = lambda { |params| return nil }
    IntercomEvent.subscribe('charge.succeeded') { |evt| count += 1 }
    stub_event('evt_charge_succeeded')

    webhook id: 'evt_charge_succeeded'

    expect(response.code).to eq '200'
    expect(count).to eq 0
  end

  it "denies access with invalid event data" do
    count = 0
    IntercomEvent.subscribe('charge.succeeded') { |evt| count += 1 }
    stub_event('evt_invalid_id', 404)

    webhook id: 'evt_invalid_id'

    expect(response.code).to eq '401'
    expect(count).to eq 0
  end

  it "ensures user-generated Intercom exceptions pass through" do
    # IntercomEvent.subscribe('charge.succeeded') { |evt| raise Intercom::IntercomError, "testing" }
    stub_event('evt_charge_succeeded')

    # expect { webhook id: 'evt_charge_succeeded' }.to raise_error(Intercom::IntercomError, /testing/)
  end
  
  context "with an authentication secret" do
    def webhook_with_secret(secret, params)
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('user', secret)
      webhook params
    end
    
    before(:each) { IntercomEvent.authentication_secret = "secret" }
    after(:each) { IntercomEvent.authentication_secret = nil }
  
    it "rejects requests with no secret" do
      stub_event('evt_charge_succeeded')
    
      webhook id: 'evt_charge_succeeded'
      expect(response.code).to eq '401'
    end
  
    it "rejects requests with incorrect secret" do
      stub_event('evt_charge_succeeded')
    
      webhook_with_secret 'incorrect', id: 'evt_charge_succeeded'
      expect(response.code).to eq '401'
    end
  
    it "accepts requests with correct secret" do
      stub_event('evt_charge_succeeded')
    
      webhook_with_secret 'secret', id: 'evt_charge_succeeded'
      expect(response.code).to eq '200'
    end
  end
end
