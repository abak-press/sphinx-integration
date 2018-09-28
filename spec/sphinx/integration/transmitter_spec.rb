require 'spec_helper'

describe Sphinx::Integration::Transmitter do
  let(:transmitter) { described_class.new(ModelWithRt) }
  let(:record) { mock_model ModelWithRt }
  let(:client) { ::ThinkingSphinx::Configuration.instance.mysql_client }

  before(:all) { ThinkingSphinx.context.define_indexes }

  before do
    allow(transmitter).to receive(:write_disabled?).and_return(false)

    allow(record).to receive_messages(
      id: 1,
      sphinx_document_id: 10,
      exists_in_sphinx?: true,
      model_with_rt_rubrics: []
    )
  end

  describe '#replace' do
    context 'when single result from db' do
      it "send valid quries to sphinx", focus: true do
        expect(record.class.connection).to receive(:select_all).with(/^SELECT/).and_return([
          {"sphinx_internal_id" => 1, "region_id" => "123"}
        ])
        expect(client).to receive(:write).with(
          'REPLACE INTO model_with_rt_rt0 (`sphinx_internal_id`, `region_id`, `rubrics`) VALUES (1, 123, ())'
        )
        expect(client).to receive(:write).
          with('UPDATE model_with_rt_core SET sphinx_deleted = 1 WHERE `id` IN (10) AND `sphinx_deleted` = 0')

        transmitter.replace(record)
      end
    end

    context 'when multi result from db' do
      let(:record1) { mock_model ModelWithRt }
      let(:record2) { mock_model ModelWithRt }

      before do
        allow(record1).to receive_messages(
          id: 1,
          sphinx_document_id: 10,
          exists_in_sphinx?: true,
          model_with_rt_rubrics: []
        )

        allow(record2).to receive_messages(
          id: 2,
          sphinx_document_id: 20,
          exists_in_sphinx?: true,
          model_with_rt_rubrics: []
        )
      end

      it "send valid quries to sphinx" do
        expect(record.class.connection).to receive(:select_all).with(/^SELECT/).and_return([
          {"sphinx_internal_id" => 1, "region_id" => "123"},
          {"sphinx_internal_id" => 2, "region_id" => "123"}
        ])

        expect(client).to receive(:write).with(
          'REPLACE INTO model_with_rt_rt0 (`sphinx_internal_id`, `region_id`, `rubrics`) VALUES (1, 123, ()), (2, 123, ())'
        )

        expect(client).to receive(:write).
          with('UPDATE model_with_rt_core SET sphinx_deleted = 1 WHERE `id` IN (10, 20) AND `sphinx_deleted` = 0')

        transmitter.replace([record1, record2])
      end
    end
  end

  describe '#delete' do
    it "send valid quries to sphinx" do
      expect(client).to receive(:write).with('DELETE FROM model_with_rt_rt0 WHERE id = 10')
      expect(client).to receive(:write).
        with('UPDATE model_with_rt_core SET sphinx_deleted = 1 WHERE `id` = 10 AND `sphinx_deleted` = 0')

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
    context 'when indexing' do
      it do
        expect(client).to receive(:write).
          with("UPDATE model_with_rt_rt0 SET field = 2 WHERE MATCH('@id_idx 1') AND `id` = 1 AND `sphinx_deleted` = 0")
        expect(client).to receive(:write).
          with("UPDATE model_with_rt_rt1 SET field = 2 WHERE MATCH('@id_idx 1') AND `id` = 1 AND `sphinx_deleted` = 0")
        expect(client).to receive(:write).
          with("UPDATE model_with_rt_core SET field = 2 WHERE MATCH('@id_idx 1') AND `id` = 1 AND `sphinx_deleted` = 0")

        ModelWithRt.sphinx_indexes.first.indexing do
          transmitter.update_fields({field: 2}, matching: "@id_idx 1", id: 1)
        end
      end
    end

    context 'when not indexing' do
      it do
        expect(client).to receive(:write).
          with("UPDATE model_with_rt SET field = 2 WHERE MATCH('@id_idx 1') AND `id` = 1 AND `sphinx_deleted` = 0")

        transmitter.update_fields({field: 2}, matching: "@id_idx 1", id: 1)
      end
    end
  end
end
