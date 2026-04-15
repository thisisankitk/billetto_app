class Fact < RailsEventStore::Event
  def self.strict(data:)
    new(data: data)
  end
end
