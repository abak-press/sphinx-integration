require "spec_helper"

describe Sphinx::Integration::Mysql::Client do
  let(:client) { described_class.new(%w(s1.dev s2.dev), 9300) }
  let(:connection) { instance_double(Sphinx::Integration::Mysql::Connection) }

  before do
    class_double(Sphinx::Integration::Mysql::Connection, new: connection).as_stubbed_const
  end

  describe "#read" do
    it do
      expect(connection).to receive(:execute).with("select 1").once
      client.read("select 1")
    end
  end

  describe "#write" do
    it do
      expect(connection).to receive(:execute).with("update index set v = 1").twice
      client.write("update index set v = 1")
    end
  end
end
