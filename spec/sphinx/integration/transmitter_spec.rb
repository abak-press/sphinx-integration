# coding: utf-8
require 'spec_helper'

describe Sphinx::Integration::Transmitter do
  let(:transmitter) { described_class.new(ModelWithRt) }
  let(:record) { mock_model ModelWithRt }

  before(:all){ ThinkingSphinx.context.define_indexes }

  before do
    record.stub(
      :sphinx_document_id => 1,
      :exists_in_sphinx? => true
    )
  end

  describe '#replace' do
    it do
      expect(transmitter).to receive(:transmitted_data).and_return(:field => 123)
      expect(transmitter).to receive(:sphinx_replace)
      expect(transmitter).to receive(:sphinx_soft_delete)
    end
    after { transmitter.replace(record) }
  end

  describe '#delete' do
    it do
      expect(transmitter).to receive(:sphinx_delete)
      expect(transmitter).to receive(:sphinx_soft_delete)
    end
    after { transmitter.delete(record) }
  end

  describe '#update' do
    it { expect(transmitter).to receive(:update_fields) }
    after { transmitter.update(record, :field => 123) }
  end

  describe '#update_fields' do
    context 'when writes delta' do
      before { transmitter.stub(:write_delta? => true) }
      it do
        expect(transmitter).to receive(:sphinx_select).and_return([{'sphinx_internal_id' => 123}])
        expect(ModelWithRt).to receive(:where).with(:id => [123]).and_return([record])
        expect(transmitter).to receive(:replace).with(record)
      end
      after { transmitter.update_fields({:field => 123}, {:id => 1}) }
    end

    context 'when no writes delta' do
      it do
        expect(transmitter).to receive(:sphinx_update)
      end
      after { transmitter.update_fields({:field => 123}, {:id => 1}) }
    end
  end
end