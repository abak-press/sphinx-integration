# coding: utf-8
require 'spec_helper'

describe Sphinx::Integration::Helper do
  let(:adapter) { instance_double("Sphinx::Integration::HelperAdapters::Local") }
  let(:mysql_client) { instance_double("Sphinx::Integration::Mysql::Client") }
  let(:helper) { described_class.new }

  before do
    class_double("Sphinx::Integration::Mysql::Client", new: mysql_client).as_stubbed_const
    class_double("Sphinx::Integration::HelperAdapters::Local", new: adapter).as_stubbed_const
  end

  describe "#restart" do
    it do
      expect(helper).to receive(:stop)
      expect(helper).to receive(:start)
      helper.restart
    end
  end

  describe "#configure" do
    it do
      expect(ThinkingSphinx::Configuration.instance).to receive(:build).with(/test\.sphinx\.conf/)
      helper.configure
    end
  end

  describe "#index" do
    context "when online indexing" do
      it do
        expect(adapter).to receive(:index).with(true)
        expect(mysql_client).to receive(:write).with(/TRUNCATE RTINDEX model_with_rt_rt0/)
        helper.index(true)
        expect(helper.recent_rt.prev).to eq 0
      end
    end

    context "when offline indexing" do
      it do
        expect(adapter).to receive(:index).with(false)
        expect(mysql_client).to_not receive(:write)
        helper.index(false)
        expect(helper.recent_rt.prev).to eq 1
      end
    end
  end

  describe "#rebuild" do
    it do
      expect(helper).to receive(:stop)
      expect(helper).to receive(:configure)
      expect(helper).to receive(:copy_config)
      expect(helper).to receive(:remove_indexes)
      expect(helper).to receive(:remove_binlog)
      expect(helper).to receive(:index).with(false)
      expect(helper).to receive(:start)
      helper.rebuild
    end
  end
end
