require 'spec_helper'

describe Sphinx::Integration::Statements::Rt do
  subject(:statements) { index.rt }
  let(:index) { ModelWithRt.sphinx_indexes.first }
  let(:client) { ::ThinkingSphinx::Configuration.instance.mysql_client }

  describe "#replace" do
    it do
      expect(client).to receive(:write).with("REPLACE INTO model_with_rt_rt0 (`company_id`) VALUES (1)")
      statements.replace(company_id: 1)
    end
  end

  describe "#delete" do
    it do
      expect(client).to receive(:write).with("DELETE FROM model_with_rt_rt0 WHERE id = 1")
      statements.delete(1)
    end
  end

  describe "#truncate" do
    it do
      expect(client).to receive(:write).with("TRUNCATE RTINDEX model_with_rt_rt0")
      statements.truncate
    end
  end
end
