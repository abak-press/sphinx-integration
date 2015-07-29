require "spec_helper"

describe Sphinx::Integration::WasteRecords do
  let(:index) { double("index", name: "product", core_name_w: "product_core_w") }

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

      expect(ThinkingSphinx).to receive(:soft_delete).with("product_core_w", [1])
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
