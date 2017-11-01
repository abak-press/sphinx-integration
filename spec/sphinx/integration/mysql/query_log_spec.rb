require "spec_helper"

describe Sphinx::Integration::Mysql::QueryLog do
  let(:query_log) { described_class.new(namespace: "test") }

  describe '#add' do
    it "adds encoded query to redis list" do
      query_log.add(query: "update 1")
      query_log.add(query: "update 2")
      expect(query_log.size).to eq 2
    end
  end

  describe '#each_batch' do
    before do
      query_log.add(query: "update 1")
      query_log.add(query: "update 2")
    end

    it "iterates over all queries" do
      batches = []
      query_log.each_batch(batch_size: 1) { |batch| batches << batch }

      expect(batches.size).to eq 2
      expect(batches[0][0]).to include(query: "update 1")
      expect(batches[1][0]).to include(query: "update 2")
      expect(query_log.size).to eq 0
    end

    context "when something is wrong" do
      it "doesn't lose a query" do
        expect { query_log.each_batch(batch_size: 2) { |_| raise 'error' } }.to raise_error(RuntimeError)
        expect(query_log.size).to eq 2
      end
    end
  end
end
