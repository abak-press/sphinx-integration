require "spec_helper"
require "sphinx/integration/helper"

describe Sphinx::Integration::HelperAdapters::Local do
  let!(:rye) { class_double("Rye").as_stubbed_const }
  let(:adapter) { described_class.new }

  describe "#stop" do
    it do
      expect(rye).to receive(:shell).with(:searchd, /--config/, "--stopwait")
      adapter.stop
    end
  end

  describe "#start" do
    it do
      expect(rye).to receive(:shell).with(:searchd, /--config/)
      adapter.start
    end

    it "starts searchd with start_args" do
      stub_sphinx_conf(start_args: ["--cpustats"])
      expect(rye).to receive(:shell).with(:searchd, /--config/, "--cpustats")
      adapter.start
    end
  end

  describe "#clean" do
    it do
      config = ThinkingSphinx::Configuration.instance
      expect(adapter).to receive(:remove_files).with("#{config.searchd_file_path}/*")
      expect(adapter).to receive(:remove_files).with("#{config.configuration.searchd.binlog_path}/*")
      adapter.clean
    end
  end

  describe "#index" do
    context "when is online" do
      let(:adapter) { described_class.new(rotate: true) }

      it do
        expect(rye).to receive(:shell).with(:indexer, /--config/, "--rotate", 'index_name')
        adapter.index('index_name')
      end
    end

    context "when is offline" do
      it do
        expect(rye).to receive(:shell).with(:indexer, /--config/, 'index_name')
        adapter.index('index_name')
      end
    end
  end
end
