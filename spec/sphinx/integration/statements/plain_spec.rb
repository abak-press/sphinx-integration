require 'spec_helper'

describe Sphinx::Integration::Statements::Plain do
  subject(:statements) { index.plain }
  let(:index) { ModelWithRt.sphinx_indexes.first }
  let(:client) { ::ThinkingSphinx::Configuration.instance.mysql_client }

  describe "#update" do
    context 'when indexing' do
      it do
        expect(client).to receive(:write).
          with("UPDATE model_with_rt_core SET company_id = 1 WHERE `id` = 1 AND `sphinx_deleted` = 0")

        index.indexing do
          statements.update({company_id: 1}, where: {id: 1})
        end

        expect(::ThinkingSphinx::Configuration.instance.update_log.size(index.core_name)).to eq 1
      end
    end

    context 'when not indexing' do
      it do
        expect(client).to receive(:write).
          with("UPDATE model_with_rt_core SET company_id = 1 WHERE `id` = 1 AND `sphinx_deleted` = 0")

        statements.update({company_id: 1}, where: {id: 1})

        expect(::ThinkingSphinx::Configuration.instance.update_log.size(index.core_name)).to eq 0
      end
    end
  end

  describe "#soft_delete" do
    context 'when indexing' do
      it do
        expect(client).to receive(:write).
          with("UPDATE model_with_rt_core SET sphinx_deleted = 1 WHERE `id` = 1 AND `sphinx_deleted` = 0")

        index.indexing do
          statements.soft_delete(1)
        end

        expect(::ThinkingSphinx::Configuration.instance.soft_delete_log.size(index.core_name)).to eq 1
      end
    end

    context 'when not indexing' do
      it do
        expect(client).to receive(:write).
          with("UPDATE model_with_rt_core SET sphinx_deleted = 1 WHERE `id` = 1 AND `sphinx_deleted` = 0")

        statements.soft_delete(1)

        expect(::ThinkingSphinx::Configuration.instance.soft_delete_log.size(index.core_name)).to eq 0
      end
    end
  end
end
