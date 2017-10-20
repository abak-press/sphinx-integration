require "spec_helper"

describe Sphinx::Integration::Mysql::QueryLog do
  let(:query_log) { described_class.new(retry_delay: 0) }

  describe '#add' do
    it "adds encoded query to redis list" do
      query_log = described_class.new
      query_log.add("select 1")
      query_log.add("select 2")
      expect(query_log.size).to eq 2
    end
  end

  describe '#each' do
    before do
      query_log.add("select 1")
      query_log.add("select 2")
    end

    it "iterates over all queries" do
      queries = []
      query_log.each { |query| queries << query }

      expect(queries.first).to eq "select 1"
      expect(queries.second).to eq "select 2"
      expect(query_log.size).to eq 0
    end

    context "when something is wrong" do
      it "doesn't lose a querie" do
        expect { query_log.each { |_| raise 'error' } }.to raise_error
        expect(query_log.size).to eq 2
      end

      context "when sadness was small" do
        it "doesn't raise an error" do
          queries = []
          error_is_raised = false
          query_log.each do |query|
            if error_is_raised
              queries << query
            else
              error_is_raised = true
              raise
            end
          end

          expect(queries.first).to eq "select 1"
          expect(queries.second).to eq "select 2"
          expect(query_log.size).to eq 0
        end
      end
    end
  end
end
