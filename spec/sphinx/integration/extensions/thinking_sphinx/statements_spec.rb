require "spec_helper"

describe ThinkingSphinx do
  describe ".replace" do
    it do
      expect(ThinkingSphinx).
        to receive(:execute).with("REPLACE INTO product (`company_id`) VALUES (1)", on_slaves: false)
      ThinkingSphinx.replace("product", company_id: 1)
    end
  end

  describe ".update" do
    it do
      expect(ThinkingSphinx).
        to receive(:execute).with("UPDATE product SET company_id = 1 WHERE `id` = 1")

      ThinkingSphinx.update("product", {company_id: 1}, id: 1)
    end
  end

  describe ".delete" do
    it do
      expect(ThinkingSphinx).
        to receive(:execute).with("DELETE FROM product WHERE id = 1")

      ThinkingSphinx.delete("product", 1)
    end
  end

  describe ".soft_delete" do
    it do
      expect(ThinkingSphinx).
        to receive(:execute).with("UPDATE product SET sphinx_deleted = 1 WHERE `id` = 1")

      ThinkingSphinx.soft_delete("product", 1)
    end
  end

  describe ".select" do
    it do
      expect(ThinkingSphinx).
        to receive(:execute).with("SELECT company_id FROM product WHERE `id` = 1")

      ThinkingSphinx.select("company_id", "product", id: 1)
    end
  end

  describe ".find_in_batches" do
    it do
      expect(ThinkingSphinx).to(
        receive(:execute).
          with("SELECT min(sphinx_internal_id) as min_id, max(sphinx_internal_id) as max_id " +
               "FROM product WHERE `company_id` = 1").
          and_return([{"min_id" => "1", "max_id" => "2"}])
      )

      expect(ThinkingSphinx).to(
        receive(:execute).
          with("SELECT sphinx_internal_id " +
               "FROM product WHERE `company_id` = 1 AND `sphinx_internal_id` BETWEEN 1 AND 1000").
          and_return([{"sphinx_internal_id" => "1"}, {"sphinx_internal_id" => "2"}])
      )

      result = []
      ThinkingSphinx.find_in_batches("product", company_id: 1) { |ids| result += ids }
      expect(result).to eq [1, 2]
    end
  end
end
