require 'spec_helper'

describe Sphinx::Integration::Transmitter do
  let(:model) { ModelWithRt }
  let(:record) { mock_model model }
  let(:records) { [record] }
  let(:transmitter) { described_class.new(record.class) }
  let(:client) { ::ThinkingSphinx::Configuration.instance.mysql_client }
  let(:plain_index) { record.class.sphinx_indexes.find(&:rt?).plain }
  let(:model_with_rt_index) { model.sphinx_indexes.first }

  before(:all) { ThinkingSphinx.context.define_indexes }

  before do
    allow(transmitter).to receive(:write_disabled).and_return(true)

    allow(record).to receive_messages(
      id: 1,
      sphinx_document_id: (1 * ::ThinkingSphinx.context.indexed_models.size + model.sphinx_offset),
      exists_in_sphinx?: true,
      model_with_rt_rubrics: []
    )
  end

  describe '#replace' do
    context 'when single result from db' do
      it "send valid quries to sphinx" do
        expect(record.class.connection).to_not receive(:select_all)
        expect(client).to_not receive(:write)
        transmitter.replace(records)
        expect(records.first).to eq record
      end

      context 'when indexing' do
        it do
          expect(record.class.connection).to_not receive(:select_all)
          expect(client).to_not receive(:write)

          model_with_rt_index.indexing do
            transmitter.replace(record)
          end
        end
      end

      context 'when product' do
        let(:model) { Product }

        it do
          expect(record.class.connection).to_not receive(:select_all)
          expect(client).to_not receive(:write)

          transmitter.replace(records)
          expect(records.first).to eq record
        end

        context 'when indexing' do
          it do
            expect(record.class.connection).to_not receive(:select_all)
            expect(client).to_not receive(:write)

            model_with_rt_index.indexing do
              transmitter.replace(record)
            end
          end
        end
      end

      it 'rasises error if need instances' do
        expect { transmitter.replace(record.id) }.to_not raise_error(/instance of ModelWithRt needed/)
      end
    end

    context 'when multi result from db' do
      let(:record1) { mock_model model }
      let(:record2) { mock_model model }

      before do
        allow(record1).to receive_messages(
          id: 1,
          sphinx_document_id: (1 * ::ThinkingSphinx.context.indexed_models.size + ModelWithRt.sphinx_offset),
          exists_in_sphinx?: true,
          model_with_rt_rubrics: []
        )

        allow(record2).to receive_messages(
          id: 2,
          sphinx_document_id: (2 * ::ThinkingSphinx.context.indexed_models.size + ModelWithRt.sphinx_offset),
          exists_in_sphinx?: true,
          model_with_rt_rubrics: []
        )
      end

      it "send valid quries to sphinx" do
        expect(record.class.connection).to_not receive(:select_all)
        expect(client).to_not receive(:write)

        transmitter.replace([record1, record2])
      end

      context 'when product' do
        let(:model) { Product }

        it do
          expect(record.class.connection).to_not receive(:select_all)
          expect(client).to_not receive(:write)

          transmitter.replace([record1, record2])
        end
      end
    end
  end

  describe '#delete' do
    it "send valid quries to sphinx" do
      expect(client).to_not receive(:write)

      transmitter.delete(record)
    end

    context 'when indexing' do
      it do
        expect(client).to_not receive(:write)
        expect(plain_index).to_not receive(:soft_delete).ordered

        model_with_rt_index.indexing do
          transmitter.delete(record)
        end
      end
    end

    context 'when product' do
      let(:model) { Product }

      it do
        expect(client).to_not receive(:write)

        transmitter.delete(record)
      end

      context 'when indexing' do
        it do
          expect(client).to_not receive(:write)
          expect(plain_index).to_not receive(:soft_delete)

          model_with_rt_index.indexing do
            transmitter.delete(record)
          end
        end
      end
    end
  end

  describe '#update' do
    it "send valid quries to sphinx" do
      expect(transmitter).to_not receive(:update_fields)
      ActiveSupport::Deprecation.silence do
        transmitter.update(record, field: 123)
      end
    end
  end

  describe '#update_fields' do
    it do
      expect(client).to_not receive(:read)

      expect(transmitter).to_not receive(:transmit)

      ActiveSupport::Deprecation.silence do
        transmitter.update_fields({field: 2}, matching: "@id_idx 1", id: 1)
      end
    end

    context 'when primary key conditions' do
      it do
        expect(client).to_not receive(:read)

        expect(transmitter).to_not receive(:transmit)

        ActiveSupport::Deprecation.silence do
          transmitter.update_fields({field: 2}, matching: "@id_idx 1", sphinx_internal_id: 11)
        end
      end
    end

    context 'when product' do
      let(:model) { Product }

      it do
        expect(client).to_not receive(:read)
        expect(transmitter).to_not receive(:transmit)

        ActiveSupport::Deprecation.silence do
          transmitter.update_fields({field: 2}, matching: "@id_idx 1", id: 1)
        end
      end

      context 'when primary key conditions' do
        it do
          expect(client).to_not receive(:read)
          expect(transmitter).to_not receive(:transmit)

          ActiveSupport::Deprecation.silence do
            transmitter.update_fields({field: 2}, matching: "@id_idx 1", sphinx_internal_id: 11)
          end
        end
      end
    end
  end

  describe '#replace_all' do
    it do
      expect(client).to_not receive(:read)
      expect(transmitter).to_not receive(:transmit)

      transmitter.replace_all(matching: "@id_idx 1", where: {id: 1})
    end

    context 'when primary key conditions' do
      it do
        expect { transmitter.replace_all(matching: "@id_idx 1", where: {sphinx_internal_id: 11}) }.
          to_not raise_error(ArgumentError)
      end
    end

    context 'when product' do
      let(:model) { Product }

      it do
        expect(client).to_not receive(:read)
        expect(transmitter).to_not receive(:transmit).with(model_with_rt_index, [11, 12])

        transmitter.replace_all(matching: "@id_idx 1", where: {id: 1})
      end

      context 'when primary key conditions' do
        it do
          expect { transmitter.replace_all(matching: "@id_idx 1", where: {sphinx_internal_id: 11}) }.
            to_not raise_error
        end
      end
    end
  end

  describe '#enqueue_action' do
    let(:record1) { mock_model ModelWithRt, id: 1 }
    let(:record2) { mock_model ModelWithRt, id: 2 }

    subject { transmitter.enqueue_action(action, [record1, record2]) }

    shared_examples 'queuing action' do
      before { subject }

      it do
        expect(Sphinx::Integration::TransmitterJob).to be_enqueued('ModelWithRt', action, [1, 2])
      end
    end

    context 'when action is replace' do
      let(:action) { :replace }
      it_behaves_like 'queuing action'
    end

    context 'when action is delete' do
      let(:action) { :delete }
      it_behaves_like 'queuing action'
    end

    context 'when action is unknown' do
      let(:action) { :unknown }
      it { expect { subject }.to raise_error(ArgumentError, "Unknown action 'unknown'") }
    end
  end
end
