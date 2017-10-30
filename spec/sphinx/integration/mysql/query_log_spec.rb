require "spec_helper"

describe Sphinx::Integration::Mysql::QueryLog do
  let(:query_log) { described_class.new }

  describe '#add' do
    it "adds encoded query to redis list" do
      query_log = described_class.new
      query_log.add("update 1")
      query_log.add("update 2")
      expect(query_log.size).to eq 2
    end
  end

  describe '#each_batch' do
    before do
      query_log.add("update 1")
      query_log.add("update 2")
    end

    it "iterates over all queries" do
      queries = []
      query_log.each_batch { |batch| queries += batch }

      expect(queries.first).to eq "update 1"
      expect(queries.second).to eq "update 2"
      expect(query_log.size).to eq 0
    end

    context "when something is wrong" do
      it "doesn't lose a querie" do
        expect { query_log.each_batch { |_| raise 'error' } }.to raise_error
        expect(query_log.size).to eq 2
      end
    end
  end
end
