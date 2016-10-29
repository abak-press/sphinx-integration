# coding: utf-8
require 'spec_helper'

describe Sphinx::Integration::Transmitter do
  let(:transmitter) { described_class.new(ModelWithRt) }
  let(:record) { mock_model ModelWithRt }
  let(:mysql_client) do
    client = double("mysql client")
    allow(ThinkingSphinx::Configuration.instance).to receive(:mysql_client).and_return(client)
    client
  end

  before(:all){ ThinkingSphinx.context.define_indexes }

  before do
    allow(transmitter).to receive(:write_disabled?).and_return(false)

    record.stub(
      sphinx_document_id: 1,
      exists_in_sphinx?: true
    )
  end

  describe '#replace' do
    it "send valid quries to sphinx" do
      expect(transmitter).to receive(:transmitted_data).and_return(field: 123)
      expect(mysql_client).to receive(:replace).with('model_with_rt_rt0', field: 123)
      expect(mysql_client).to receive(:soft_delete)

      transmitter.replace(record)
    end
  end

  describe '#delete' do
    it "send valid quries to sphinx" do
      expect(mysql_client).to receive(:delete).with('model_with_rt_rt0', 1)
      expect(mysql_client).to receive(:soft_delete)
      transmitter.delete(record)
    end
  end

  describe '#update' do
    it "send valid quries to sphinx" do
      expect(transmitter).to receive(:update_fields)
      transmitter.update(record, field: 123)
    end
  end

  describe '#update_fields' do
    context 'when full reindex' do
      before { transmitter.stub(:full_reindex? => true) }

      it do
        expect(mysql_client).to receive(:update).with("model_with_rt_rt0", {field: 123}, {id: 1}, "@id_idx 1")
        expect(mysql_client).to receive(:update).with("model_with_rt_rt1", {field: 123}, {id: 1}, "@id_idx 1")
        expect(mysql_client).
          to receive(:find_in_batches).
            with("model_with_rt_core", where: {id: 1}, matching: "@id_idx 1").
            and_yield([1])

        transmitter.update_fields({field: 123}, id: 1, matching: "@id_idx 1")
      end
    end

    context 'when no full reindex' do
      it do
        expect(mysql_client).to receive(:update)
        transmitter.update_fields({field: 123}, id: 1)
      end
    end
  end
end
