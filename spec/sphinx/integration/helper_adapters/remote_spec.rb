require "spec_helper"
require "sphinx/integration/helper"

describe Sphinx::Integration::HelperAdapters::Remote do
  let!(:ssh) { instance_double("Sphinx::Integration::HelperAdapters::SshProxy") }
  let(:adapter) { described_class.new }

  before do
    class_double("Sphinx::Integration::HelperAdapters::SshProxy", new: ssh).as_stubbed_const
  end

  describe "#running?" do
    it do
      expect(ssh).to receive(:execute).with("searchd", /--config/, "--status")
      adapter.running?
    end
  end

  describe "#stop" do
    it do
      expect(ssh).to receive(:execute).with("searchd", /--config/, "--stopwait")
      adapter.stop
    end
  end

  describe "#start" do
    it do
      expect(ssh).to receive(:execute).with("searchd", /--config/)
      adapter.start
    end

    it "starts searchd with start_args" do
      stub_sphinx_conf(start_args: ["--cpustats"])
      expect(ssh).to receive(:execute).with("searchd", /--config/, "--cpustats")
      adapter.start
    end
  end

  describe "#suspend" do
    it do
      adapter.suspend
      server_status = Sphinx::Integration::ServerStatus.new(ThinkingSphinx::Configuration.instance.address)
      expect(server_status.available?).to be false
    end
  end

  describe "#resume" do
    it do
      adapter.resume
      server_status = Sphinx::Integration::ServerStatus.new(ThinkingSphinx::Configuration.instance.address)
      expect(server_status.available?).to be true
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

      context "when many hosts" do
        before do
          stub_sphinx_conf(config_file: "/path/sphinx.conf",
                           searchd_file_path: "/path/data",
                           address: %w(s1.dev s2.dev))
        end

        it do
          expect(ssh).to receive(:within).with("s1.dev").and_yield
          expect(ssh).to receive(:execute).
            with("indexer", "--config /path/sphinx.conf", "--rotate", "--nohup", 'index_name', exit_status: [0, 2])
          expect(ssh).to receive(:execute).
            with('for NAME in /path/data/*_core.tmp.*; do mv -f "${NAME}" "${NAME/\.tmp\./.new.}"; done')
          server = double("server", opts: {port: 22}, user: "sphinx", host: "s1.dev")
          expect(ssh).to receive(:without).with("s1.dev").and_yield(server)
          expect(ssh).to receive(:execute).with("rsync", "-ptzv", "--bwlimit=70M", "--compress-level=1", any_args)
          expect(ssh).to receive(:execute).with("kill", /SIGHUP/)

          adapter.index('index_name')
        end
      end

      context "when one host" do
        before do
          stub_sphinx_conf(config_file: "/path/sphinx.conf",
                           searchd_file_path: "/path/data",
                           address: "s1.dev")
        end

        it do
          expect(ssh).to receive(:within).with("s1.dev").and_yield
          expect(ssh).to receive(:execute).
            with("indexer", "--config /path/sphinx.conf", "--rotate", "--nohup", 'index_name', exit_status: [0, 2])
          expect(ssh).to receive(:execute).
            with('for NAME in /path/data/*_core.tmp.*; do mv -f "${NAME}" "${NAME/\.tmp\./.new.}"; done')
          expect(ssh).to_not receive(:without)
          expect(ssh).to_not receive(:execute).with("rsync", any_args)
          expect(ssh).to receive(:execute).with("kill", /SIGHUP/)

          adapter.index('index_name')
        end
      end
    end

    context "when is offline" do
      context "when many hosts" do
        before do
          stub_sphinx_conf(config_file: "/path/sphinx.conf",
                           searchd_file_path: "/path/data",
                           address: %w(s1.dev s2.dev))
        end

        it do
          expect(ssh).to receive(:within).with("s1.dev").and_yield
          expect(ssh).to receive(:execute).
            with("indexer", "--config /path/sphinx.conf", 'index_name', exit_status: [0, 2])
          expect(ssh).to_not receive(:execute).with(/for NAME/)
          server = double("server", opts: {port: 22}, user: "sphinx", host: "s1.dev")
          expect(ssh).to receive(:without).with("s1.dev").and_yield(server)
          expect(ssh).to receive(:execute).with("rsync", "-ptzv", "--bwlimit=70M", "--compress-level=1", any_args)
          expect(ssh).to_not receive(:execute).with("kill", /SIGHUP/)

          adapter.index('index_name')
        end
      end

      context "when one host" do
        before do
          stub_sphinx_conf(config_file: "/path/sphinx.conf",
                           searchd_file_path: "/path/data",
                           address: "s1.dev")
        end

        it do
          expect(ssh).to receive(:within).with("s1.dev").and_yield
          expect(ssh).to receive(:execute).
            with("indexer", "--config /path/sphinx.conf", 'index_name', exit_status: [0, 2])
          expect(ssh).to_not receive(:execute).with(/for NAME/)
          expect(ssh).to_not receive(:without)
          expect(ssh).to_not receive(:execute).with("rsync", any_args)
          expect(ssh).to_not receive(:execute).with("kill", /SIGHUP/)

          adapter.index('index_name')
        end
      end
    end
  end
end
