require Rails.root.join("lib/command/bus")

Rails.configuration.command_bus = Command::Bus.new