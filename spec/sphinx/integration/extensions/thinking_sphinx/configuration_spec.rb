# coding: utf-8
require 'spec_helper'

describe ThinkingSphinx::Configuration do

  let(:config) { ThinkingSphinx::Configuration.instance }
  let(:base_options) do
    {'test' => {}}
  end
  let(:spec_options) { {} }

  before do
    config_path = "#{config.app_root}/config/sphinx.yml"
    File.stub(:exists?).with(config_path).and_return(true)
    IO.stub(:read).with(config_path).and_return(base_options.deep_merge(spec_options).to_yaml)
    config.reset
  end

  describe '`remote` option' do
    context 'when default' do
      it { expect(config.remote?).to be_false }
    end

    context 'when enabled' do
      let(:spec_options){ {'test' => {'remote' => true}} }
      it { expect(config.remote?).to be_true }
    end
  end

  describe '`replication` option' do
    context 'when default' do
      it { expect(config.replication?).to be_false }
    end

    context 'when enabled' do
      let(:spec_options){ {'test' => {'replication' => true}} }
      it { expect(config.replication?).to be_true }
    end
  end

  describe '`agents` option' do
    context 'when default' do
      it { expect(config.agents).to be_empty }
    end

    context 'when specified' do
      let(:spec_options){ {'test' => {'agents' => {'slave' => {'address' => 'index', 'port' => 123, 'mysql41' => 321, 'name' => 'slave'}}}} }
      it { expect(config.agents).to have(1).item }
      it { expect(config.agents).to eq spec_options['test']['agents'] }
    end
  end

  describe '`agent_connect_timeout` option' do
    context 'when default' do
      it { expect(config.agent_connect_timeout).to eq 50 }
    end

    context 'when specified' do
      let(:spec_options){ {'test' => {'agent_connect_timeout' => 100}} }
      it { expect(config.agent_connect_timeout).to eq 100 }
    end
  end

  describe '`ha_strategy` option' do
    context 'when default' do
      it { expect(config.ha_strategy).to eq 'nodeads' }
    end

    context 'when specified' do
      let(:spec_options){ {'test' => {'ha_strategy' => 'roundrobin'}} }
      it { expect(config.ha_strategy).to eq 'roundrobin' }
    end
  end

end