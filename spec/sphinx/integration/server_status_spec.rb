require "spec_helper"

describe Sphinx::Integration::ServerStatus do
  let(:server_status) { described_class.new("127.0.0.1") }

  describe "#available?" do
    it "by default is true" do
      expect(server_status.available?).to be true
    end
  end

  describe "#available=" do
    it "set right value" do
      server_status.available = false
      expect(server_status.available?).to be false
    end

    it "switch values and clear cache" do
      server_status.available = false
      expect(server_status.available?).to be false
      server_status.available = true
      expect(server_status.available?).to be true
    end
  end
end
