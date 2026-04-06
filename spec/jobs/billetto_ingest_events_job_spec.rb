require "rails_helper"

RSpec.describe BillettoIngestEventsJob, type: :job do
  describe "#perform" do
    it "invokes Billetto::IngestEvents with fetch_all enabled" do
      service = instance_double(Billetto::IngestEvents)
      expect(Billetto::IngestEvents).to receive(:new).with(url: "/next-page").and_return(service)
      expect(service).to receive(:call).with(fetch_all: true)

      described_class.perform_now(url: "/next-page")
    end
  end
end
