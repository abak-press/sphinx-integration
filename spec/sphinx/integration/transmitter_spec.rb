require 'spec_helper'

describe Sphinx::Integration::Transmitter do
  let(:transmitter) { described_class.new(ModelWithRt) }
  let(:record) { mock_model ModelWithRt }
  let(:client) { ::ThinkingSphinx::Configuration.instance.mysql_client }

  before(:all) { ThinkingSphinx.context.define_indexes }

  before do
    allow(transmitter).to receive(:write_disabled?).and_return(false)

    allow(record).to receive_messages(
      sphinx_document_id: 1,
      exists_in_sphinx?: true,
      model_with_rt_rubrics: []
    )
  end

  describe '#replace' do
    it "send valid quries to sphinx" do
      expect(record.class.connection).to receive(:execute).with(/^SELECT/).and_return([{"region_id" => "123"}])
      expect(client).to receive(:write).with('REPLACE INTO model_with_rt_rt0 (`region_id`, `rubrics`) VALUES (123, ())')
      expect(client).to receive(:write).
        with('UPDATE model_with_rt_core SET sphinx_deleted = 1 WHERE `id` = 1 AND `sphinx_deleted` = 0')

      transmitter.replace(record)
    end
  end

  describe '#delete' do
    it "send valid quries to sphinx" do
      expect(client).to receive(:write).with('DELETE FROM model_with_rt_rt0 WHERE id = 1')
      expect(client).to receive(:write).
        with('UPDATE model_with_rt_core SET sphinx_deleted = 1 WHERE `id` = 1 AND `sphinx_deleted` = 0')

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
