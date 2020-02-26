require 'spec_helper'

describe Sphinx::Integration::Statements::Plain do
  subject(:statements) { index.plain }
  let(:index) { ModelWithRt.sphinx_indexes.first }
  let(:client) { ::ThinkingSphinx::Configuration.instance.mysql_client }

  describe "#update" do
    it do
      expect(client).to_not receive(:write)

      expect { statements.update({company_id: 1}, where: {id: 1}) }.
        to change { ::ThinkingSphinx::Configuration.instance.update_log.size(index.core_name) }.by(1)
    end
  end

  describe "#soft_delete" do
    it do
      expect(client).to_not receive(:write)

      expect { statements.soft_delete(1) }.
        to change { ::ThinkingSphinx::Configuration.instance.soft_delete_log.size(index.core_name) }.by(1)
    end
  end
end
