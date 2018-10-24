require 'spec_helper'

RSpec.describe Sphinx::Integration::TransmitterJob do
  let(:model) { ModelWithRt.create! }

  describe '.perform' do
    it do
      expect_any_instance_of(Sphinx::Integration::Transmitter).to receive(:replace).with([model.id])

      described_class.execute(ModelWithRt.to_s, 'replace', [model.id])
    end
  end

  describe '.enqueue' do
    let(:record1) { mock_model ModelWithRt, id: 1 }
    let(:record2) { mock_model ModelWithRt, id: 2 }

    subject { described_class.enqueue('ModelWithRt', action, [record1.id, record2.id]) }

    shared_examples 'queuing action' do
      before { subject }

      it { expect(described_class).to be_enqueued('ModelWithRt', action, [record1.id, record2.id]) }
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
      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end
end
