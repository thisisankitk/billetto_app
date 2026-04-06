module Command
  class Bus
    def call(command)
      command.call
    end
  end
end