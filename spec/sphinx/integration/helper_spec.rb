require 'spec_helper'

describe Sphinx::Integration::Helper do
  let(:adapter) { instance_double("Sphinx::Integration::HelperAdapters::Local") }
  let(:default_options) { {sphinx_adapter: adapter} }

  describe "#configure" do
    it do
      expect(ThinkingSphinx::Configuration.instance).to receive(:build).with(/test\.sphinx\.conf/)
      described_class.new(default_options).configure
    end
  end

  describe "#index" do
    context "when online indexing" do
      it do
        helper = described_class.new(default_options.merge(rotate: true, indexes: 'model_with_rt'))
        expect_any_instance_of(Sphinx::Integration::Mysql::Replayer).to receive(:reset)
        expect_any_instance_of(RedisMutex).to receive(:with_lock).and_yield
        expect(adapter).to receive(:index).with('model_with_rt_core')
        expect(helper).to receive(:sleep).with(60)
        expect(::ThinkingSphinx::Configuration.instance.mysql_client).
          to receive(:write).with('TRUNCATE RTINDEX model_with_rt_rt0')
        expect(::Sphinx::Integration::ReplayerJob).to receive(:enqueue).with('model_with_rt_core')
        helper.index
        expect(ModelWithRt.sphinx_indexes.first.recent_rt.current).to eq 1
      end
    end

    context "when offline indexing" do
      it do
        helper = described_class.new(default_options.merge(indexes: 'model_with_rt'))
        expect_any_instance_of(Sphinx::Integration::Mysql::Replayer).to_not receive(:reset)
        expect_any_instance_of(RedisMutex).to_not receive(:with_lock)
        expect(adapter).to receive(:index).with('model_with_rt_core')
        expect(::ThinkingSphinx::Configuration.instance.mysql_client).to_not receive(:write)
        expect(::Sphinx::Integration::ReplayerJob).to_not receive(:enqueue)
        helper.index
        expect(ModelWithRt.sphinx_indexes.first.recent_rt.current).to eq 0
      end
    end

    context "when only core indexing" do
      it do
        helper = described_class.new(default_options.merge(indexes: 'model_with_second_disk'))
        expect(adapter).to receive(:index).with('model_with_second_disk_core')
        expect(::ThinkingSphinx::Configuration.instance.mysql_client).to_not receive(:write)
        expect(::Sphinx::Integration::ReplayerJob).to_not receive(:enqueue).with('model_with_second_disk_core')
        helper.index
      end
    end

    context "when raised exception" do
      it "logs a error" do
        helper = described_class.new(default_options)

        allow(adapter).to receive(:index).and_raise(StandardError.new("error message"))

        expect do
          expect_any_instance_of(::Logger).to receive(:error).with("error message")
          expect(Sphinx::Integration[:di][:error_notificator]).to receive(:call).with("error message")

          helper.index
        end.to raise_error(StandardError)
      end
    end
  end

  describe "#rebuild" do
    it do
      helper = described_class.new(default_options)
      expect(helper).to receive(:stop)
      expect(helper).to receive(:clean)
      expect(helper).to receive(:configure)
      expect(helper).to receive(:copy_config)
      expect(helper).to receive(:index)
      expect(helper).to receive(:start)
      helper.rebuild
    end
  end
end
