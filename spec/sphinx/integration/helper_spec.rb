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
        expect_any_instance_of(Sphinx::Integration::Mysql::Replayer).to_not receive(:reset)
        expect_any_instance_of(RedisMutex).to_not receive(:with_lock).and_yield
        expect(adapter).to_not receive(:index)
        expect(::ThinkingSphinx::Configuration.instance.mysql_client).
          not_to receive(:write)
        expect(::ThinkingSphinx::Configuration.instance.mysql_vip_client).
          not_to receive(:write)
        expect(::Sphinx::Integration::ReplayerJob).to_not receive(:enqueue)
        helper.index
        expect(ModelWithRt.sphinx_indexes.first.recent_rt.current).to eq 0
      end
    end

    context "when product indexing" do
      it do
        helper = described_class.new(default_options.merge(rotate: true, indexes: 'product'))
        expect_any_instance_of(Sphinx::Integration::Mysql::Replayer).to_not receive(:reset)
        expect_any_instance_of(RedisMutex).to_not receive(:with_lock).and_yield
        expect(adapter).to_not receive(:index)
        expect(::ThinkingSphinx::Configuration.instance.mysql_client).to_not receive(:write)
        expect(::ThinkingSphinx::Configuration.instance.mysql_vip_client).to_not receive(:write)
        expect(::Sphinx::Integration::ReplayerJob).to_not receive(:enqueue).with('product_core')
        helper.index
        expect(Product.sphinx_indexes.first.recent_rt.current).to eq 0
      end
    end

    context "when offline indexing" do
      it do
        helper = described_class.new(default_options.merge(indexes: 'model_with_rt'))
        expect_any_instance_of(Sphinx::Integration::Mysql::Replayer).to_not receive(:reset)
        expect_any_instance_of(RedisMutex).to_not receive(:with_lock)
        expect(adapter).to_not receive(:index)

        expect(::ThinkingSphinx::Configuration.instance.mysql_client).to_not receive(:write)
        expect(::Sphinx::Integration::ReplayerJob).to_not receive(:enqueue)
        helper.index
        expect(ModelWithRt.sphinx_indexes.first.recent_rt.current).to eq 0
      end
    end

    context "when only core indexing" do
      it do
        helper = described_class.new(default_options.merge(indexes: 'model_with_second_disk'))
        expect(adapter).to_not receive(:index)

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
          expect_any_instance_of(::Logger).to_not receive(:error)
          expect(Sphinx::Integration[:di][:error_notificator]).to_not receive(:call)

          helper.index
        end.to_not raise_error(StandardError)
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
