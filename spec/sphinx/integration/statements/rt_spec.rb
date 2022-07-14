# frozen_string_literal: true

require 'spec_helper'

describe Sphinx::Integration::Statements::Rt do
  subject(:statements) { index.rt }
  let(:index) { ModelWithRt.sphinx_indexes.first }
  let(:client) { ::Sphinx::Integration::Mysql::Client.new('127.0.0.1', 9306) }
  let(:vip_client) { ::Sphinx::Integration::Mysql::Client.new('127.0.0.1', 9111) }

  before do
    allow_any_instance_of(::Sphinx::Integration::Mysql::Client).to receive_messages(
      write: true,
      read: []
    )

    allow(::ThinkingSphinx::Configuration.instance).to receive(:mysql_vip_client).and_return vip_client
    allow(::ThinkingSphinx::Configuration.instance).to receive(:mysql_client).and_return client
  end

  describe "#replace" do
    context 'when single data' do
      it do
        expect(client).to receive(:write).with("REPLACE INTO model_with_rt_rt0 (`company_id`) VALUES (1)")
        statements.replace(company_id: 1)
      end
    end

    context 'when complex data' do
      it do
        expect(client).to receive(:write).with(
          "REPLACE INTO model_with_rt_rt0 (`company_id`) VALUES (1), (2), (3)"
        )

        statements.replace([{company_id: 1}, {company_id: 2}, {company_id: 3}])
      end

      context 'when heterogeneous data' do
        it do
          expect do
            statements.replace([{company_id: 1}, {offer_id: 2}, {product_id: 3}])
          end.to raise_error(/invalid schema of data/)
        end
      end
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
      expect(client).not_to receive(:write).with("TRUNCATE RTINDEX model_with_rt_rt0")
      expect(vip_client).to receive(:write).with("TRUNCATE RTINDEX model_with_rt_rt0")

      statements.truncate
    end
  end
end
