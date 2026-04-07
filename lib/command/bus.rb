require "securerandom"

require_relative "context"

module Command
  class Bus
    NOTIFICATION_NAME = "command_bus.call".freeze

    def call(command)
      ensure_command_executable!(command)
      ensure_command_valid!(command)

      context = build_context

      ActiveSupport::Notifications.instrument(
        NOTIFICATION_NAME,
        command: command.class.name,
        correlation_id: context[:correlation_id],
        causation_id: context[:causation_id]
      ) do
        with_context(context) do
          ApplicationRecord.transaction { command.call }
        end
      end
    end

    private

    def ensure_command_executable!(command)
      return if command.respond_to?(:call)

      raise ArgumentError, "Command must respond to #call"
    end

    def ensure_command_valid!(command)
      return unless command.respond_to?(:valid?)
      return if command.valid?

      raise ActiveRecord::RecordInvalid, command
    end

    def build_context
      {
        correlation_id: Command::Context.correlation_id || SecureRandom.uuid,
        causation_id: Command::Context.causation_id
      }
    end

    def with_context(context)
      previous_correlation_id = Command::Context.correlation_id
      previous_causation_id = Command::Context.causation_id

      Command::Context.correlation_id = context[:correlation_id]
      Command::Context.causation_id = context[:causation_id]

      yield
    ensure
      Command::Context.correlation_id = previous_correlation_id
      Command::Context.causation_id = previous_causation_id
    end
  end
end