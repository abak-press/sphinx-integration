require 'spec_helper'

describe Sphinx::Integration::Statements::Distributed do
  subject(:statements) { ModelWithRt.sphinx_indexes.first.distributed }
  let(:client) { ::ThinkingSphinx::Configuration.instance.mysql_client }

  describe "#update" do
    context 'with where, without matching' do
      it do
        expect(client).
          to receive(:write).with("UPDATE model_with_rt SET company_id = 1 WHERE `id` = 1 AND `sphinx_deleted` = 0")
        statements.update({company_id: 1}, where: {id: 1})
      end
    end

    context 'with where and matching' do
      it do
        expect(client).to receive(:write).
          with("UPDATE model_with_rt SET company_id = 1 WHERE MATCH('@id_idx 1') AND `id` = 1 AND `sphinx_deleted` = 0")
        statements.update({company_id: 1}, matching: "@id_idx 1", where: {id: 1})
      end
    end

    context 'without where, with matching' do
      it do
        expect(client).
          to receive(:write).with("UPDATE model_with_rt SET company_id = 1 " \
                                  "WHERE MATCH('@id_idx 1') AND `sphinx_deleted` = 0")
        statements.update({company_id: 1}, matching: "@id_idx 1")
      end
    end

    context 'when matching is a hash' do
      it do
        expect(client).
          to receive(:write).with("UPDATE model_with_rt SET company_id = 1 " \
                                  "WHERE MATCH('@id_idx 1') AND `sphinx_deleted` = 0")

        statements.update({company_id: 1}, matching: {id_idx: '1'})
      end
    end

    context 'when composite index' do
      it do
        expect(client).
          to receive(:write).with("UPDATE model_with_rt SET company_id = 1 " \
                                  "WHERE MATCH('@composite_idx b @id_idx 1 @composite_idx a') AND `sphinx_deleted` = 0")

        statements.update({company_id: 1}, matching: "@b_idx b @id_idx 1 @a_idx a")
      end

      context 'when matching is a hash' do
        it do
          expect(client).
            to receive(:write).with("UPDATE model_with_rt SET company_id = 1 " \
                                    "WHERE MATCH('@composite_idx b @id_idx 1 @composite_idx a') " \
                                    "AND `sphinx_deleted` = 0")

          statements.update({company_id: 1}, matching: {b_idx: 'b', id_idx: '1', a_idx: 'a'})
        end
      end
    end
  end

  describe "#soft_delete" do
    it do
      expect(client).
        to receive(:write).with("UPDATE model_with_rt SET sphinx_deleted = 1 WHERE `id` = 1 AND `sphinx_deleted` = 0")
      statements.soft_delete(1)
    end
  end

  describe "#select" do
    it do
      expect(client).to receive(:read).with(
        "SELECT company_id FROM model_with_rt WHERE MATCH('@company_id 123') AND `id` = 1 AND `sphinx_deleted` = 0" \
        " LIMIT 10 OPTION max_matches=#{ThinkingSphinx.max_matches}"
      )
      statements.select("company_id", limit: 10, matching: '@company_id 123', where: {id: 1})
    end
  end

  describe '#find_while_exists' do
    it do
      expect(client).to receive(:read).with(
        "SELECT sphinx_internal_id" \
        " FROM model_with_rt WHERE MATCH('@company_id 123') AND `company_id` = 123 AND `sphinx_deleted` = 0" \
        " LIMIT 5000 OPTION max_matches=#{ThinkingSphinx.max_matches}"
      ).and_return([{"sphinx_internal_id" => "1"}]).ordered

      expect(client).to receive(:read).with(
        "SELECT sphinx_internal_id" \
        " FROM model_with_rt WHERE MATCH('@company_id 123') AND `company_id` = 123 AND `sphinx_deleted` = 0" \
        " LIMIT 5000 OPTION max_matches=#{ThinkingSphinx.max_matches}"
      ).and_return([]).ordered

      company_ids = []
      statements.
        find_while_exists("sphinx_internal_id", matching: '@company_id 123', where: {company_id: 123}) do |rows|
          company_ids += rows.map { |row| row["sphinx_internal_id"].to_i }
        end

      expect(company_ids).to match_array([1])
    end
  end

  describe ".find_in_batches" do
    it do
      expect(client).to receive(:read).with(
        "SELECT sphinx_internal_id " \
        "FROM model_with_rt " \
        "WHERE MATCH('@company_id_idx 1') " \
        "AND `company_id` = 1 AND `sphinx_internal_id` > 0 AND `sphinx_deleted` = 0 " \
        "ORDER BY `sphinx_internal_id` ASC LIMIT 1 " \
        "OPTION max_matches=#{ThinkingSphinx.max_matches}"
      ).and_return([{"sphinx_internal_id" => "1"}])

      expect(client).to receive(:read).with(
        "SELECT sphinx_internal_id " \
        "FROM model_with_rt " \
        "WHERE MATCH('@company_id_idx 1') " \
        "AND `company_id` = 1 AND `sphinx_internal_id` > 1 AND `sphinx_deleted` = 0 " \
        "ORDER BY `sphinx_internal_id` ASC LIMIT 1 " \
        "OPTION max_matches=#{ThinkingSphinx.max_matches}"
      ).and_return([])

      result = []
      statements.find_in_batches(
        matching: "@company_id_idx 1",
        batch_size: 1,
        where: {company_id: 1}
      ) { |records| result += records.map { |record| record['sphinx_internal_id'].to_i } }
      expect(result).to eq [1]
    end
  end
end
