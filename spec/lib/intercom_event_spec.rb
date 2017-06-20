require 'spec_helper'

describe IntercomEvent do
  let(:events) { [] }
  let(:subscriber) { ->(evt){ events << evt } }
  let(:charge_succeeded) { double('charge succeeded') }
  let(:charge_failed) { double('charge failed') }

  describe ".configure" do
    it "yields itself to the block" do
      yielded = nil
      IntercomEvent.configure { |events| yielded = events }
      expect(yielded).to eq IntercomEvent
    end

    it "requires a block argument" do
      expect { IntercomEvent.configure }.to raise_error ArgumentError
    end

    describe ".setup - deprecated" do
      it "evaluates the block in its own context" do
        ctx = nil
        IntercomEvent.setup { ctx = self }
        expect(ctx).to eq IntercomEvent
      end
    end
  end

  describe "subscribing to a specific event type" do
    before do
      expect(charge_succeeded).to receive(:[]).with(:topic).and_return('company.created')
      # expect(Intercom::Event).to receive(:retrieve).with('company_created').and_return(charge_succeeded)
    end

    context "with a block subscriber" do
      it "calls the subscriber with the retrieved event" do
        IntercomEvent.subscribe('company.created', &subscriber)

        IntercomEvent.instrument(id: 'company_created', topic: 'company.created')

        expect(events).to eq [company_created]
      end
    end

    context "with a subscriber that responds to #call" do
      it "calls the subscriber with the retrieved event" do
        IntercomEvent.subscribe('company.created', subscriber)

        IntercomEvent.instrument(id: 'company_created', topic: 'company.created')

        expect(events).to eq [company_created]
      end
    end
  end

  describe "subscribing to the 'account.application.deauthorized' event type" do
    before do
      # expect(Intercom::Event).to receive(:retrieve).with('evt_account_application_deauthorized').and_raise(Intercom::AuthenticationError)
    end

    context "with a subscriber params with symbolized keys" do
      it "calls the subscriber with the retrieved event" do
        IntercomEvent.subscribe('account.application.deauthorized', subscriber)

        IntercomEvent.instrument(id: 'evt_account_application_deauthorized', topic: 'account.application.deauthorized')

        expect(events.first.type).to eq 'account.application.deauthorized'
        expect(events.first[:topic]).to eq 'account.application.deauthorized'
      end
    end

    # The Intercom api expects params to be passed into their IntercomObject's
    # with symbolized keys, but the params that we pass through from a
    # accont.application.deauthorized webhook are a HashWithIndifferentAccess
    # (keys stored as strings always.
    context "with a subscriber params with indifferent access (stringified keys)" do
      it "calls the subscriber with the retrieved event" do
        IntercomEvent.subscribe('account.application.deauthorized', subscriber)

        IntercomEvent.instrument({ id: 'evt_account_application_deauthorized', topic: 'account.application.deauthorized' }.with_indifferent_access)

        expect(events.first.type).to eq 'account.application.deauthorized'
        expect(events.first[:topic]).to eq 'account.application.deauthorized'
      end
    end
  end

  describe "subscribing to a namespace of event types" do
    let(:card_created) { double('company_created') }
    let(:card_updated) { double('card updated') }

    before do
      expect(card_created).to receive(:[]).with(:topic).and_return('customer.card.created')
      # expect(Intercom::Event).to receive(:retrieve).with('evt_card_created').and_return(card_created)

      expect(card_updated).to receive(:[]).with(:topic).and_return('customer.card.updated')
      # expect(Intercom::Event).to receive(:retrieve).with('evt_card_updated').and_return(card_updated)
    end

    context "with a block subscriber" do
      it "calls the subscriber with any events in the namespace" do
        IntercomEvent.subscribe('conversation.user', &subscriber)

        IntercomEvent.instrument(id: 'evt_card_created', topic: 'conversation.user.created')
        IntercomEvent.instrument(id: 'evt_card_updated', topic: 'conversation.user.replied')

        expect(events).to eq [converations_user_created, converations_user_replied]
      end
    end

    context "with a subscriber that responds to #call" do
      it "calls the subscriber with any events in the namespace" do
        IntercomEvent.subscribe('conversation.', subscriber)

        IntercomEvent.instrument(id: 'evt_card_updated', topic: 'conversation.user.created')
        IntercomEvent.instrument(id: 'evt_card_created', topic: 'conversation.admin.replied')

        expect(events).to eq [converations_user_created, conversations_admin_replied]
      end
    end
  end

  describe "subscribing to all event types" do
    before do
      expect(charge_succeeded).to receive(:[]).with(:topic).and_return('company.created')
      # expect(Intercom::Event).to receive(:retrieve).with('company_created').and_return(charge_succeeded)

      expect(charge_failed).to receive(:[]).with(:topic).and_return('user.created')
      # expect(Intercom::Event).to receive(:retrieve).with('user_created').and_return(charge_failed)
    end

    context "with a block subscriber" do
      it "calls the subscriber with all retrieved events" do
        IntercomEvent.all(&subscriber)

        IntercomEvent.instrument(id: 'company_created', topic: 'company.created')
        IntercomEvent.instrument(id: 'user_created', topic: 'user.created')

        expect(events).to eq [company_created, user_created]
      end
    end

    context "with a subscriber that responds to #call" do
      it "calls the subscriber with all retrieved events" do
        IntercomEvent.all(subscriber)

        IntercomEvent.instrument(id: 'company_created', topic: 'company.created')
        IntercomEvent.instrument(id: 'user_created', topic: 'user.created')

        expect(events).to eq [company_created, user_created]
      end
    end
  end

  describe ".listening?" do
    it "returns true when there is a subscriber for a matching event type" do
      IntercomEvent.subscribe('customer.', &subscriber)

      # expect(IntercomEvent.listening?('customer.card')).to be true
      # expect(IntercomEvent.listening?('customer.')).to be true
    end

    it "returns false when there is not a subscriber for a matching event type" do
      IntercomEvent.subscribe('customer.', &subscriber)

      # expect(IntercomEvent.listening?('account')).to be false
    end

    it "returns true when a subscriber is subscribed to all events" do
      IntercomEvent.all(&subscriber)

      expect(IntercomEvent.listening?('customer.')).to be true
      expect(IntercomEvent.listening?('account')).to be true
    end
  end

  describe IntercomEvent::NotificationAdapter do
    let(:adapter) { IntercomEvent.adapter }

    it "calls the subscriber with the last argument" do
      expect(subscriber).to receive(:call).with(:last)

      adapter.call(subscriber).call(:first, :last)
    end
  end

  describe IntercomEvent::Namespace do
    let(:namespace) { IntercomEvent.namespace }

    describe "#call" do
      it "prepends the namespace to a given string" do
        expect(namespace.call('foo.bar')).to eq 'intercom_event.foo.bar'
      end

      it "returns the namespace given no arguments" do
        expect(namespace.call).to eq 'intercom_event.'
      end
    end

    describe "#to_regexp" do
      it "matches namespaced strings" do
        expect(namespace.to_regexp('foo.bar')).to match namespace.call('foo.bar')
      end

      it "matches all namespaced strings given no arguments" do
        expect(namespace.to_regexp).to match namespace.call('foo.bar')
      end
    end
  end
end
