require "spec_helper"

describe Sphinx::Integration::WasteRecords do
  let(:index) { double("index", name: "product", core_name: "product_core") }
  let(:mysql_client) do
    client = double("mysql client")
    allow(ThinkingSphinx::Configuration.instance).to receive(:mysql_client).and_return(client)
    client
  end

  describe "#add" do
    it "add record to a queue set" do
      waste_records = described_class.new(index)
      waste_records.add(1)
      expect(waste_records.size).to eq 1
    end
  end

  describe "#cleanup" do
    it "soft deletes records from core index" do
      waste_records = described_class.new(index)
      waste_records.add(1)

      expect(mysql_client).to receive(:soft_delete).with("product_core", [1])
      waste_records.cleanup
      expect(waste_records.size).to eq 0
    end
  end

  describe "#reset" do
    it "empty records set" do
      waste_records = described_class.new(index)
      waste_records.add(1)
      waste_records.reset
      expect(waste_records.size).to eq 0
    end
  end
end
