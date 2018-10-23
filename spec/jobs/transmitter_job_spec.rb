require 'spec_helper'

RSpec.describe Sphinx::Integration::TransmitterJob do
  let(:model) { ModelWithRt.create! }

  describe '.perform' do
    it do
      expect_any_instance_of(Sphinx::Integration::Transmitter).to receive(:replace).with([model.id])

      described_class.execute(ModelWithRt.to_s, 'transmitter_update', [model.id])
    end
  end
end
