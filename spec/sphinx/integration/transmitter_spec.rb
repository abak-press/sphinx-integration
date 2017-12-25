require 'spec_helper'

describe Sphinx::Integration::Transmitter do
  let(:transmitter) { described_class.new(ModelWithRt) }
  let(:record) { mock_model ModelWithRt }
  let(:mysql_client) do
    client = double("mysql client")
    allow(ThinkingSphinx::Configuration.instance).to receive(:mysql_client).and_return(client)
    client
  end

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
      expect(mysql_client).to receive(:replace).with('model_with_rt_rt0', "region_id" => 123, rubrics: [])
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
      before do
        allow(transmitter).to receive(:full_reindex?).and_return(true)
        allow(transmitter).to receive(:online_indexing?).and_return(true)
      end

      context 'when strict' do
        it do
          expect(mysql_client).to receive(:update).with("model_with_rt_rt0", {field: 123}, matching: "@id_idx 1", id: 1)
          expect(mysql_client).to receive(:update).with("model_with_rt_rt1", {field: 123}, matching: "@id_idx 1", id: 1)
          expect(mysql_client).
            to receive(:find_while_exists).
            with("model_with_rt_core", "sphinx_internal_id", matching: "@id_idx 1", id: 1).
            and_yield([{"sphinx_internal_id" => 1}])

          transmitter.update_fields({field: 123}, id: 1, strict: true, matching: "@id_idx 1")
        end

        context 'when matching is a hash' do
          it do
            expect(mysql_client).to receive(:update).
              with("model_with_rt_rt0", {field: 123}, matching: "@id_idx 1", id: 1)
            expect(mysql_client).to receive(:update).
              with("model_with_rt_rt1", {field: 123}, matching: "@id_idx 1", id: 1)
            expect(mysql_client).
              to receive(:find_while_exists).
              with("model_with_rt_core", "sphinx_internal_id", matching: "@id_idx 1", id: 1).
              and_yield([{"sphinx_internal_id" => 1}])

            transmitter.update_fields({field: 123}, id: 1, strict: true, matching: {id_idx: '1'})
          end
        end

        context 'when composite index' do
          it do
            expect(mysql_client).to receive(:update)
              .with("model_with_rt_rt0", {field: 123}, matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1)
            expect(mysql_client).to receive(:update)
              .with("model_with_rt_rt1", {field: 123}, matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1)
            expect(mysql_client).
              to receive(:find_while_exists).
              with("model_with_rt_core", "sphinx_internal_id",
                   matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1).
              and_yield([{"sphinx_internal_id" => 1}])

            transmitter.update_fields({field: 123}, id: 1, strict: true, matching: "@b_idx b @id_idx 1 @a_idx a")
          end

          context 'when matching is a hash' do
            it do
              expect(mysql_client).to receive(:update)
                .with("model_with_rt_rt0", {field: 123}, matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1)
              expect(mysql_client).to receive(:update)
                .with("model_with_rt_rt1", {field: 123}, matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1)
              expect(mysql_client).
                to receive(:find_while_exists).
                with("model_with_rt_core", "sphinx_internal_id",
                     matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1).
                and_yield([{"sphinx_internal_id" => 1}])

              transmitter.update_fields({field: 123}, id: 1, strict: true, matching: {
                b_idx: 'b',
                id_idx: '1',
                a_idx: 'a'
              })
            end
          end
        end
      end

      context "when no strict" do
        it do
          expect(mysql_client).to receive(:update).with('model_with_rt_rt0', {field: 123}, matching: "@id_idx 1", id: 1)
          expect(mysql_client).to receive(:update).with('model_with_rt_rt1', {field: 123}, matching: "@id_idx 1", id: 1)
          expect(mysql_client).
            to receive(:update).with('model_with_rt_core', {field: 123}, matching: "@id_idx 1", id: 1)

          transmitter.update_fields({field: 123}, matching: "@id_idx 1", id: 1)
        end

        context 'when matching is a hash' do
          it do
            expect(mysql_client).to receive(:update).
              with('model_with_rt_rt0', {field: 123}, matching: "@id_idx 1", id: 1)
            expect(mysql_client).to receive(:update).
              with('model_with_rt_rt1', {field: 123}, matching: "@id_idx 1", id: 1)
            expect(mysql_client).
              to receive(:update).with('model_with_rt_core', {field: 123}, matching: "@id_idx 1", id: 1)

            transmitter.update_fields({field: 123}, matching: {id_idx: '1'}, id: 1)
          end
        end

        context 'when composite index' do
          it do
            expect(mysql_client).to receive(:update)
              .with("model_with_rt_rt0", {field: 123}, matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1)
            expect(mysql_client).to receive(:update)
              .with("model_with_rt_rt1", {field: 123}, matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1)
            expect(mysql_client).
              to receive(:find_while_exists).
              with("model_with_rt_core", "sphinx_internal_id",
                   matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1).
              and_yield([{"sphinx_internal_id" => 1}])

            transmitter.update_fields({field: 123}, id: 1, strict: true, matching: "@b_idx b @id_idx 1 @a_idx a")
          end

          context 'when matching is a hash' do
            it do
              expect(mysql_client).to receive(:update)
                .with("model_with_rt_rt0", {field: 123}, matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1)
              expect(mysql_client).to receive(:update)
                .with("model_with_rt_rt1", {field: 123}, matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1)
              expect(mysql_client).
                to receive(:find_while_exists).
                with("model_with_rt_core", "sphinx_internal_id",
                     matching: "@composite_idx b @id_idx 1 @composite_idx a", id: 1).
                and_yield([{"sphinx_internal_id" => 1}])

              transmitter.update_fields({field: 123}, id: 1, strict: true, matching: {
                b_idx: 'b',
                id_idx: '1',
                a_idx: 'a'
              })
            end
          end
        end
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
