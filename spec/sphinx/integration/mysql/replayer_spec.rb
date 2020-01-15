require 'spec_helper'

describe Sphinx::Integration::Mysql::Replayer do
  let(:config) { ThinkingSphinx::Configuration.instance }
  let(:mysql_client) { config.mysql_client }

  describe '#replay' do
    it "replay a queries to core" do
      index = ::ModelWithRt.sphinx_indexes.first

      expect(mysql_client).to receive(:execute).with(/UPDATE model_with_rt_core SET region_id/, any_args)
      expect(mysql_client).to receive(:execute).with(/UPDATE model_with_rt_core SET sphinx_deleted/, any_args)

      index.indexing do
        index.plain.update({region_id: 1}, where: {sphinx_internal_id: 10})
        index.plain.soft_delete(20)
      end

      expect(config.update_log.size(index.core_name)).to eq 1
      expect(config.soft_delete_log.size(index.core_name)).to eq 1

      expect(mysql_client).to receive(:batch_write) do |queries|
        expect(queries.size).to eq 1
        expect(queries[0]).to match(/UPDATE model_with_rt_core/)
      end

      expect(mysql_client).to receive(:execute).with(/UPDATE model_with_rt_core SET sphinx_deleted/, any_args)

      ::Sphinx::Integration::Mysql::Replayer.new(index.core_name).replay

      expect(config.update_log.size(index.core_name)).to eq 0
      expect(config.soft_delete_log.size(index.core_name)).to eq 0
    end
  end
end
