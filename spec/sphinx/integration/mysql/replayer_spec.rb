require 'spec_helper'

describe Sphinx::Integration::Mysql::Replayer do
  let(:config) { ThinkingSphinx::Configuration.instance }
  let(:app_mysql_client) { config.mysql_client }
  let(:helper_mysql_client) { instance_double("Sphinx::Integration::Mysql::Client") }

  before do
    allow(app_mysql_client).to receive(:execute).with(/TRUNCATE RTINDEX model_with_rt_rt0/, any_args)
    allow(app_mysql_client).to receive(:execute).with(/TRUNCATE RTINDEX model_with_rt_rt1/, any_args)
  end

  describe '#replay', with_sphinx: true do
    context 'when full reindex' do
      it "replay a queries to core" do
        expect(app_mysql_client).to receive(:execute).with(/UPDATE model_with_rt_rt0 SET region_id/, any_args)
        expect(app_mysql_client).to receive(:execute).with(/UPDATE model_with_rt_rt1 SET region_id/, any_args)
        expect(app_mysql_client).to receive(:execute).with(/UPDATE model_with_rt_core SET region_id/, any_args)
        expect(app_mysql_client).to receive(:execute).with(/UPDATE model_with_rt_core SET sphinx_deleted/, any_args)

        sphinx_adapter = instance_double("Sphinx::Integration::HelperAdapters::Remote")
        expect(sphinx_adapter).to receive(:index) do
          ::ModelWithRt.update_sphinx_fields({region_id: 1}, sphinx_internal_id: 10)
          app_mysql_client.soft_delete('model_with_rt_core', 20)
        end

        expect(helper_mysql_client).to receive(:log_enabled=).with(false)
        expect(helper_mysql_client).to receive(:batch_write) do |queries|
          expect(queries.size).to eq 1
          expect(queries[0]).to match(/UPDATE model_with_rt_core/)
        end
        expect(helper_mysql_client).to receive(:soft_delete).with('model_with_rt_core', [20])

        helper = Sphinx::Integration::Helper.new(rotate: true,
                                                 sphinx_adapter: sphinx_adapter,
                                                 mysql_client: helper_mysql_client)
        helper.index

        expect(config.update_log.size).to eq 0
        expect(config.soft_delete_log.size).to eq 0
      end
    end
  end
end
