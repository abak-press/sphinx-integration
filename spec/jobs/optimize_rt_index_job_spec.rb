# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sphinx::Integration::OptimizeRtIndexJob do
  describe '.perform' do
    let(:client) { ::Sphinx::Integration::Mysql::Client.new('127.0.0.1', 9306) }
    let(:vip_client) { ::Sphinx::Integration::Mysql::Client.new('127.0.0.1', 9111) }
    let(:riddle_client) { ::Riddle::Client.new('127.0.0.1', 10_001) }
    let(:server_pool) { ::Sphinx::Integration::ServerPool.new('127.0.0.1', 10_001) }
    let(:server) { ::Sphinx::Integration::Server.new('127.0.0.1', 10_001) }
    let(:server_status) { ::Sphinx::Integration::ServerStatus.new('127.0.0.1') }

    before do
      allow(described_class).to receive(:sleep)
      allow_any_instance_of(::Sphinx::Integration::Mysql::Client).to receive_messages(
        write: true,
        read: []
      )

      allow(riddle_client.class).to receive(:server_pool).and_return server_pool
      allow(server_pool).to receive(:find_server).and_return server
      allow(server).to receive(:server_status).and_return server_status

      allow(::ThinkingSphinx::Configuration.instance).to receive(:mysql_vip_client).and_return vip_client
      allow(::ThinkingSphinx::Configuration.instance).to receive(:mysql_client).and_return client
      allow(::ThinkingSphinx::Configuration.instance).to receive(:client).and_return riddle_client
    end

    it 'disables the node' do
      expect(server_status).to receive(:available=).ordered.with(false)

      expect(vip_client).to receive(:read).ordered.with('OPTIMIZE INDEX model_with_rt_rt0')
      expect(vip_client).to receive(:read).ordered.with('SHOW THREADS')
      expect(vip_client).to receive(:read).ordered.with('OPTIMIZE INDEX model_with_rt_rt1')
      expect(vip_client).to receive(:read).ordered.with('SHOW THREADS')

      expect(server_status).to receive(:available=).ordered.with(true).twice

      described_class.perform(index: 'model_with_rt')
    end

    context 'when optimization in progress' do
      before do
        allow(vip_client).to receive(:read).with('SHOW THREADS').and_return(
          [{'Info' => 'SYSTEM OPTIMIZE'}],
          []
        )
      end

      it 'retries if in progress' do
        expect(vip_client).to receive(:read).ordered.with('OPTIMIZE INDEX model_with_rt_rt0')
        # два rt-индекса, на первом 2 попытки чтения SHOW THREADS, на втором 1 попытка
        expect(vip_client).to receive(:read).ordered.with('SHOW THREADS').exactly(3).times
        expect(vip_client).to receive(:read).ordered.with('OPTIMIZE INDEX model_with_rt_rt1')
        expect(described_class).to receive(:sleep).exactly(3).times
        described_class.perform(index: 'model_with_rt')
      end
    end
  end
end
