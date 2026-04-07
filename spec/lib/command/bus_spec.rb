require "rails_helper"

RSpec.describe Command::Bus do
  subject(:bus) { described_class.new }

  def build_command_class
    Class.new do
      include ActiveModel::Model

      attr_accessor :event_id

      validates :event_id, presence: true

      def call; end
    end
  end

  describe "#call" do
    it "wraps command execution in a transaction" do
      stub_const("SpecCommand", build_command_class)
      command = SpecCommand.new(event_id: "evt-1")

      expect(ApplicationRecord).to receive(:transaction).and_yield
      expect(command).to receive(:call)

      bus.call(command)
    end

    it "raises for invalid commands" do
      stub_const("SpecCommand", build_command_class)
      command = SpecCommand.new(event_id: nil)

      expect { bus.call(command) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "raises when object is not executable" do
      expect { bus.call(Object.new) }
        .to raise_error(ArgumentError, "Command must respond to #call")
    end

    it "instruments command calls with context identifiers" do
      stub_const("SpecCommand", build_command_class)
      command = SpecCommand.new(event_id: "evt-2")
      captured = []

      subscription = ActiveSupport::Notifications.subscribe("command_bus.call") do |*args|
        captured << ActiveSupport::Notifications::Event.new(*args)
      end

      begin
        bus.call(command)
      ensure
        ActiveSupport::Notifications.unsubscribe(subscription)
      end

      expect(captured.size).to eq(1)
      expect(captured.first.payload[:command]).to eq("SpecCommand")
      expect(captured.first.payload[:correlation_id]).to be_present
      expect(captured.first.payload).to have_key(:causation_id)
    end
  end
end
