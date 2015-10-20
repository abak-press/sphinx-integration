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

  describe "#replace" do
    it do
      expect(connection).to receive(:execute).with("REPLACE INTO product (`company_id`) VALUES (1)").twice
      client.replace("product", company_id: 1)
    end
  end

  describe "#update" do
    it do
      expect(connection).to receive(:execute).with("UPDATE product SET company_id = 1 WHERE `id` = 1").twice
      client.update("product", {company_id: 1}, id: 1)
    end
  end

  describe "#delete" do
    it do
      expect(connection).to receive(:execute).with("DELETE FROM product WHERE id = 1").twice
      client.delete("product", 1)
    end
  end

  describe "#soft_delete" do
    it do
      expect(connection).to receive(:execute).with("UPDATE product SET sphinx_deleted = 1 WHERE `id` = 1").twice
      client.soft_delete("product", 1)
    end
  end

  describe "#select" do
    it do
      expect(connection).to receive(:execute).with("SELECT company_id FROM product WHERE `id` = 1").once
      client.select("company_id", "product", id: 1)
    end
  end

  describe ".find_in_batches" do
    it do
      expect(connection).to receive(:execute).with(
        "SELECT sphinx_internal_id " +
        "FROM product " +
        "WHERE MATCH('@company_id_idx 1') " +
        "AND `company_id` = 1 AND `sphinx_internal_id` > 0 " +
        "ORDER BY `sphinx_internal_id` ASC LIMIT 1"
      ).and_return([{"sphinx_internal_id" => "1"}])

      expect(connection).to receive(:execute).with(
        "SELECT sphinx_internal_id " +
        "FROM product " +
        "WHERE MATCH('@company_id_idx 1') " +
        "AND `company_id` = 1 AND `sphinx_internal_id` > 1 " +
        "ORDER BY `sphinx_internal_id` ASC LIMIT 1"
      ).and_return([])

      result = []
      client.find_in_batches(
        "product",
        where: {company_id: 1}, matching: "@company_id_idx 1", batch_size: 1) { |ids| result += ids }
      expect(result).to eq [1]
    end
  end
end
