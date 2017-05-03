# coding: utf-8
require 'spec_helper'

describe Sphinx::Integration::Helper do
  let(:adapter) { instance_double("Sphinx::Integration::HelperAdapters::Local") }
  let(:mysql_client) { instance_double("Sphinx::Integration::Mysql::Client") }

  before do
    class_double("Sphinx::Integration::Mysql::Client", new: mysql_client).as_stubbed_const
    class_double("Sphinx::Integration::HelperAdapters::Local", new: adapter).as_stubbed_const
  end

  describe "#configure" do
    it do
      expect(ThinkingSphinx::Configuration.instance).to receive(:build).with(/test\.sphinx\.conf/)
      described_class.new.configure
    end
  end

  describe "#index" do
    context "when online indexing" do
      it do
        helper = described_class.new(rotate: true)
        expect(adapter).to receive(:index)
        expect(mysql_client).to receive(:write).with(/TRUNCATE RTINDEX model_with_rt_rt0/)
        helper.index
        expect(helper.recent_rt.prev).to eq 0
      end
    end

    context "when offline indexing" do
      it do
        helper = described_class.new
        expect(adapter).to receive(:index)
        expect(mysql_client).to_not receive(:write)
        helper.index
        expect(helper.recent_rt.prev).to eq 1
      end
    end

    context "when raised exception" do
      it "logs a error" do
        logger = spy(:logger)
        notificator = spy(:notificator)
        helper = described_class.new(logger: logger, notificator: notificator)

        expect(adapter).to receive(:index).and_raise(StandardError.new("error message"))
        expect { helper.index }.to raise_error(StandardError)
        expect(logger).to have_received(:error).with("error message")
        expect(notificator).to have_received(:call).with("error message")
      end
    end
  end

  describe "#rebuild" do
    it do
      helper = described_class.new
      expect(helper).to receive(:stop)
      expect(helper).to receive(:configure)
      expect(helper).to receive(:copy_config)
      expect(helper).to receive(:remove_indexes)
      expect(helper).to receive(:remove_binlog)
      expect(helper).to receive(:index)
      expect(helper).to receive(:start)
      helper.rebuild
    end
  end
end
