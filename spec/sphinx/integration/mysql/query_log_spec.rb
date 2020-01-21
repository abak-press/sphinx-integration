require "spec_helper"

describe Sphinx::Integration::Mysql::QueryLog do
  let(:index_name1) { 'model_core' }
  let(:index_name2) { 'other_model_core' }
  let(:query_log) { described_class.new(namespace: "test") }

  before do
    query_log.add(index_name1, query: "update 1")
    query_log.add(index_name1, query: "update 2")
    query_log.add(index_name2, query: "update all")
  end

  describe '#add' do
    it "adds encoded query to redis list" do
      expect(query_log.size(index_name1)).to eq 2
      expect(query_log.size(index_name2)).to eq 1
    end
  end

  describe '#each_batch' do
    it "iterates over all queries" do
      batches = []
      query_log.each_batch(index_name1, batch_size: 1) { |batch| batches << batch }

      expect(batches.size).to eq 2
      expect(batches[0][0]).to include(query: "update 1")
      expect(batches[1][0]).to include(query: "update 2")
      expect(query_log.size(index_name1)).to eq 0

      batches = []
      query_log.each_batch(index_name2, batch_size: 1) { |batch| batches << batch }

      expect(batches.size).to eq 1
      expect(batches[0][0]).to include(query: "update all")
      expect(query_log.size(index_name2)).to eq 0
    end

    context "when something is wrong" do
      it "doesn't lose a query" do
        expect { query_log.each_batch(index_name1, batch_size: 2) { |_| raise 'error' } }.to raise_error(RuntimeError)
        expect(query_log.size(index_name1)).to eq 2
      end
    end
  end
end
