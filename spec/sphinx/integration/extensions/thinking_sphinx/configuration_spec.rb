# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::Configuration do
  let(:config) { ThinkingSphinx::Configuration.instance }

  describe '`remote` option' do
    context 'when default' do
      it { expect(config.remote?).to be false }
    end

    context 'when enabled' do
      it do
        stub_sphinx_conf(remote: true)
        expect(config.remote?).to be true
      end
    end
  end

  describe '#excluded_klasses' do
    context 'when file have not `exclude` section' do
      it { expect(config.exclude).to eq [] }
    end

    context 'when file have `exclude` section' do
      it do
        stub_sphinx_conf(exclude: ['apress/product_denormalization/sphinx_index'])
        expect(config.exclude).to eq ['apress/product_denormalization/sphinx_index']
      end
    end
  end

  describe "#mysql_client" do
    context "when one address" do
      it do
        stub_sphinx_conf(address: "s1", mysql41: true)
        expect(Sphinx::Integration::Mysql::Client).to receive(:new).with(%w(s1), 9306)
        config.mysql_client
      end
    end

    context "when many addresses" do
      it do
        stub_sphinx_conf(address: %w(s1 s2), mysql41: 9300)
        expect(Sphinx::Integration::Mysql::Client).to receive(:new).with(%w(s1 s2), 9300)
        config.mysql_client
      end
    end
  end

  describe "#mysql_vip_client" do
    before { config.instance_variable_set(:@mysql_vip_client, {}) }
    after { config.instance_variable_set(:@mysql_vip_client, {}) }

    context "when configured vip port" do
      it do
        stub_sphinx_conf(address: "s1", mysql41: 9300, mysql41_vip: 9111)
        expect(Sphinx::Integration::Mysql::Client).to receive(:new).with(%w(s1), 9111)
        config.mysql_vip_client
      end
    end

    context "when one address" do
      it do
        stub_sphinx_conf(address: "s1", mysql41: true)
        expect(Sphinx::Integration::Mysql::Client).to receive(:new).with(%w(s1), 9306)
        config.mysql_vip_client
      end
    end

    context "when many addresses" do
      it do
        stub_sphinx_conf(address: %w(s1 s2), mysql41: 9300)
        expect(Sphinx::Integration::Mysql::Client).to receive(:new).with(%w(s1 s2), 9300)
        config.mysql_vip_client
      end
    end

    context "when priviledged" do
      it do
        stub_sphinx_conf(address: %w(s1 s2), mysql41: 9300, mysql41_vip: 9111)
        expect(Sphinx::Integration::Mysql::Client).to receive(:new).with('s1', 9111)
        config.mysql_vip_client('s1')
      end
    end
  end
end
