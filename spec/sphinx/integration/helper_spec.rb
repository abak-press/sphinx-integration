# coding: utf-8
require 'spec_helper'

describe Sphinx::Integration::Helper do

  let(:config) { ThinkingSphinx::Configuration.instance }
  let(:current_node) { nil }
  let(:helper) { described_class.new(current_node) }
  let(:base_options) { {'test' => {}} }
  let(:agents) do
    {
      'slave1' => {
        'address' => 'sphinx1',
        'port' => 10301,
        'mysql41' => 9301
      },
      'slave2' => {
        'address' => 'sphinx2',
        'port' => 10302,
        'mysql41' => 9302
      }
    }
  end
  let(:replication_options) { {'replication' => true, 'agents' => agents} }

  before do
    config_path = "#{config.app_root}/config/sphinx.yml"
    File.stub(:exists?).with(config_path).and_return(true)
    IO.stub(:read).with(config_path).and_return(base_options.deep_merge('test' => spec_options).to_yaml)
    config.reset

    helper.stub(
      :master => double('master'),
      :agents => double('agents'),
      :nodes => double('nodes')
    )
  end

  context 'when local' do
    let(:spec_options) { {'remote' => false} }

    describe '#sphinx_running?' do
      it { expect(ThinkingSphinx).to receive(:sphinx_running?) }
      after { helper.sphinx_running? }
    end

    describe '#stop' do
      it { expect(helper).to receive(:local_searchd).with('--stopwait') }
      after { helper.stop }
    end

    describe '#start' do
      it { expect(helper).to receive(:local_searchd).with(no_args) }
      after { helper.start }
    end

    describe '#restart' do
      it do
        expect(helper).to receive(:stop).ordered
        expect(helper).to receive(:start).ordered
      end
      after { helper.restart }
    end

    describe '#configure' do
      it { expect(helper.send(:config)).to receive(:build) }
      after { helper.configure }
    end

    describe '#remove_indexes' do
      before { Dir.stub(:glob => ['/path/to/data']) }
      it { expect(FileUtils).to receive(:rm) }
      after { helper.remove_indexes }
    end

    describe '#remove_binlog' do
      let(:spec_options) { super().merge('binlog_path' => '/path/to/binlog') }
      before { Dir.stub(:glob => ['/path/to/binlog']) }
      it { expect(FileUtils).to receive(:rm) }
      after { helper.remove_binlog }
    end

    describe '#copy_config' do
      it { expect(helper.send(:config)).to_not receive(:replication?) }
      after { helper.copy_config }
    end

    describe '#index' do
      context 'when offline' do
        it do
          expect(helper).to receive(:local_indexer).with([])
          expect(helper).to_not receive(:catch_up_indexes)
        end
        after { helper.index(false) }
      end

      context 'when online' do
        it do
          expect(helper).to receive(:local_indexer).with(['--rotate'])
          expect(helper).to receive(:catch_up_indexes)
        end
        after { helper.index }
      end
    end

    describe '#rebuild' do
      it do
        expect(helper).to receive(:stop).ordered
        expect(helper).to receive(:configure).ordered
        expect(helper).to receive(:copy_config).ordered
        expect(helper).to receive(:remove_indexes).ordered
        expect(helper).to receive(:remove_binlog).ordered
        expect(helper).to receive(:index).with(false).ordered
        expect(helper).to receive(:start).ordered
      end
      after { helper.rebuild }
    end

    describe '#dump_delta_index' do
      let(:model) { double('model') }
      let(:records) { [double('record')] }
      let(:index) { double('index') }
      let(:connection) { double('connection') }

      before do
        model.stub(:primary_key => 'id')
        index.stub(:delta_rt_name => 'delta_rt_name')
        sphinx_result = double('sphinx_result')
        sphinx_result.stub(:to_a => [1])
        sphinx_result.stub(:results => {:matches => [{:doc => 10}]})
        helper.stub(:delta_index_results).and_yield(sphinx_result)
        ThinkingSphinx.stub(:take_connection).and_yield(connection)
      end

      it do
        expect(model).to receive(:where).with('id' => [1]).and_return(records)
        expect(records.first).to receive(:transmitter_update)
        expect(connection).to receive(:execute).with(/DELETE FROM delta_rt_name WHERE id = 10/)
      end
      after { helper.send(:dump_delta_index, model, index) }
    end

  end

  context 'when remote' do
    let(:spec_options) { {'remote' => true, 'remote_path' => '/path/on/remote'} }

    describe '#sphinx_running?' do
      it { expect(helper.nodes).to receive(:searchd).with('--status') }
      after { helper.sphinx_running? }
    end

    describe '#stop' do
      it { expect(helper.nodes).to receive(:searchd).with('--stopwait') }
      after { helper.stop }
    end

    describe '#start' do
      it { expect(helper.nodes).to receive(:searchd).with(no_args) }
      after { helper.start }
    end

    describe '#remove_indexes' do
      it { expect(helper.nodes).to receive(:remove_indexes) }
      after { helper.remove_indexes }
    end

    describe '#remove_indexes' do
      let(:spec_options) { super().merge('binlog_path' => '/path/to/binlog') }
      it { expect(helper.nodes).to receive(:remove_binlog) }
      after { helper.remove_binlog }
    end

    describe '#copy_config' do
      context 'when single' do
        it { expect(helper.master).to receive(:file_upload) }
        after { helper.copy_config }
      end

      context 'when replication' do
        let(:spec_options) { super().merge(replication_options) }

        context 'when work with all' do
          it do
            expect(helper.send(:config).agents['slave1'][:box]).to receive(:file_upload)
            expect(helper.send(:config).agents['slave2'][:box]).to receive(:file_upload)
            expect(helper.master).to receive(:file_upload)
          end
          after { helper.copy_config }
        end

        context 'when work with master' do
          let(:current_node) { 'master' }
          it { expect(helper.master).to receive(:file_upload) }
          after { helper.copy_config }
        end

        context 'when work with slave2' do
          let(:current_node) { 'slave2' }
          before { helper.nodes.stub(:boxes => [helper.send(:config).agents['slave2'][:box]] ) }
          it do
            expect(helper.send(:config).agents['slave1'][:box]).to_not receive(:file_upload)
            expect(helper.send(:config).agents['slave2'][:box]).to receive(:file_upload)
            expect(helper.master).to_not receive(:file_upload)
          end
          after { helper.copy_config }
        end
      end
    end

    describe '#index' do
      context 'when single' do
        context 'when online' do
          it do
            expect(helper.master).to receive(:indexer)
            expect(helper).to receive(:catch_up_indexes)
          end
          after { helper.index }
        end

        context 'when offline' do
          it do
            expect(helper.master).to receive(:indexer)
            expect(helper).to_not receive(:catch_up_indexes)
          end
          after { helper.index(false) }
        end
      end

      context 'when replication' do
        let(:spec_options) { super().merge(replication_options) }

        context 'when work with master' do
          let(:current_node) { 'master' }
          it { expect { helper.index }.to raise_error }
        end

        context 'when work with all' do
          it { expect(helper).to receive(:full_reindex_with_replication) }
          after { helper.index }
        end

        context 'when work with slave2' do
          let(:current_node) { 'slave2' }
          context 'when online' do
            it do
              expect(helper.nodes).to receive(:indexer).with(['--rotate', "--config %REMOTE_PATH%/conf/sphinx.conf"])
              expect(helper).to receive(:catch_up_indexes).with(:truncate => false)
            end
            after { helper.index }
          end

          context 'when offline' do
            it do
              expect(helper.nodes).to receive(:indexer).with(["--config %REMOTE_PATH%/conf/sphinx.conf"])
              expect(helper).to_not receive(:catch_up_indexes)
            end
            after { helper.index(false) }
          end
        end
      end
    end

    describe '#full_reindex_with_replication' do
      let(:spec_options) { super().merge(replication_options) }
      let(:slave1) { double('slave1') }
      let(:slave2) { double('slave2') }

      before do
        helper.agents.stub(:boxes => [slave1, slave2])
        helper.send(:config).agents['slave1'][:box] = slave1
        helper.send(:config).agents['slave2'][:box] = slave2
      end

      context 'when online' do
        it do
          expect(slave1).to receive(:execute).with(/sed/)
          expect(slave1).to receive(:indexer)
          expect(slave1).to receive(:rm)

          expect(slave1).to receive(:user)
          expect(slave1).to receive(:host)
          expect(helper.agents).to receive(:execute).with(/rsync/)
          expect(helper.agents).to receive(:kill).with(/SIGHUP/)
          expect(helper).to receive(:catch_up_indexes)
        end
        after { helper.send(:full_reindex_with_replication) }
      end

      context 'when offline' do
        it do
          expect(slave1).to receive(:indexer)

          expect(slave1).to receive(:user)
          expect(slave1).to receive(:host)
          expect(helper.agents).to receive(:execute).with(/rsync/)
          expect(helper).to_not receive(:catch_up_indexes)
        end
        after { helper.send(:full_reindex_with_replication, false) }
      end
    end
  end
end