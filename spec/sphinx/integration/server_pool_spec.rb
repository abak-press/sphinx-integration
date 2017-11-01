require "spec_helper"

describe Sphinx::Integration::ServerPool do
  let(:pool) { described_class.new(%w(s1 s2), 9306) }

  describe "#take" do
    it "take one random server from list" do
      expect { |b| pool.take(&b) }.to yield_control.once
    end

    it "call second server if first server dies" do
      calls_count = 0

      pool.take do |_|
        calls_count += 1
        raise if calls_count == 1
      end

      expect(calls_count).to eq 2
    end

    it "fails if all servers dies" do
      expect { pool.take { |_| raise } }.to raise_error(RuntimeError)
    end
  end

  describe "#take_all" do
    it "iterates by all servers" do
      expect { |b| pool.take_all(&b) }.to yield_control.twice
    end

    it "doesnt fail if only one server die" do
      calls_count = 0

      expect do
        pool.take_all do |_|
          calls_count += 1
          raise if calls_count == 1
        end
      end.to_not raise_error

      expect(calls_count).to eq 2
    end

    it "fails if all servers dies" do
      expect { pool.take_all { |_| raise } }.to raise_error(RuntimeError)
    end
  end
end
