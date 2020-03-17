require 'spec_helper'

describe Sphinx::Integration::Mysql::Replayer do
  let(:config) { ThinkingSphinx::Configuration.instance }
  let(:mysql_client) { config.mysql_client }

  describe '#replay' do
    it "replay a queries to core" do
      index = ::ModelWithRt.sphinx_indexes.first

      index.indexing do
        index.plain.update({region_id: 1}, where: {sphinx_internal_id: 10})
        index.plain.soft_delete(20)
      end

      expect(config.update_log.size(index.core_name)).to eq 1
      expect(config.soft_delete_log.size(index.core_name)).to eq 1

      expect(mysql_client).to receive(:write).with(
        "UPDATE model_with_rt_core SET sphinx_deleted = 1 WHERE `id` IN (20) AND `sphinx_deleted` = 0"
      )

      expect(mysql_client).to receive(:read).with(
        /SELECT id FROM model_with_rt_rt0 WHERE `id` > 0 AND `sphinx_deleted` = 0 ORDER BY `id` ASC LIMIT 500/
      ).and_return([{'id' => 11}, {'id' => 12}])

      expect(mysql_client).to receive(:write).with(
        "UPDATE model_with_rt_core SET sphinx_deleted = 1 WHERE `id` IN (11, 12) AND `sphinx_deleted` = 0"
      )

      expect(mysql_client).to receive(:batch_write).with(
        ["UPDATE model_with_rt_core SET region_id = 1 WHERE `sphinx_internal_id` = 10 AND `sphinx_deleted` = 0"]
      )

      ::Sphinx::Integration::Mysql::Replayer.new(index.core_name).replay

      expect(config.update_log.size(index.core_name)).to eq 0
      expect(config.soft_delete_log.size(index.core_name)).to eq 0
    end
  end
end
