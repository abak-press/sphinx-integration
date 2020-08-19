# coding: utf-8
require 'spec_helper'

describe ActiveRecord::Base do
  describe '.max_matches' do
    context "when defined in config" do
      before { stub_sphinx_conf(max_matches: 3_000) }

      it { expect(ActiveRecord::Base.max_matches).to eq 3_000 }
    end

    context "when defined in config" do
      it { expect(ActiveRecord::Base.max_matches).to eq 5_000 }
    end
  end

  describe '.define_secondary_index' do
    let(:index) { ModelWithSecondDisk.sphinx_indexes.detect { |x| x.name == 'model_with_second_disk_delta' } }

    it do
      expect(index.merged_with_core).to be true
    end
  end

  describe '.reset_indexes' do
    it do
      ModelWithDisk.reset_indexes
      expect(ModelWithDisk.sphinx_index_blocks).to be_empty
      expect(ModelWithDisk.sphinx_indexes).to be_empty
      expect(ModelWithDisk.sphinx_facets).to be_empty
    end
  end

  describe '.rt_indexed_by_sphinx?' do
    it { expect(ModelWithRt.rt_indexed_by_sphinx?).to be true }
  end

  describe '.need_transmitter_update' do
    context 'when true' do
      it do
        expect_any_instance_of(Sphinx::Integration::Transmitter).to receive(:replace)

        ModelWithRt.create!
      end
    end

    context 'when false' do
      it do
        expect_any_instance_of(Sphinx::Integration::Transmitter).not_to receive(:replace)

        ModelWithRt.need_transmitter_update = false
        ModelWithRt.create!
        ModelWithRt.need_transmitter_update = true
      end
    end

    context 'when model has been changed' do
      let!(:model) { ModelWithRt.create! }

      it do
        expect_any_instance_of(Sphinx::Integration::Transmitter).to receive(:replace)

        model.update_attributes!(content: "foo#{rand(100)}")
      end
    end

    context 'when destroy' do
      let!(:model) { ModelWithRt.create! }

      it do
        expect_any_instance_of(Sphinx::Integration::Transmitter).to receive(:delete)
        expect_any_instance_of(Sphinx::Integration::Transmitter).not_to receive(:replace)

        model.destroy
      end

      context 'when disabled' do
        it do
          expect_any_instance_of(Sphinx::Integration::Transmitter).not_to receive(:delete)

          model
          ModelWithRt.need_transmitter_update = false
          model.destroy
          ModelWithRt.need_transmitter_update = true
        end
      end
    end
  end

  describe '.transmitter_update' do
    let!(:model1) { ModelWithRt.create! }
    let!(:model2) { ModelWithRt.create! }

    it do
      expect_any_instance_of(Sphinx::Integration::Transmitter).to receive(:replace).with([model1, model2])

      ModelWithRt.transmitter_update([model1, model2])
    end
  end

  describe '.transmitter_update_all' do
    it do
      expect_any_instance_of(Sphinx::Integration::Transmitter).
        to receive(:replace_all).with(matching: '@id_idx 1', where: {id: 1})

      ModelWithRt.transmitter_update_all(matching: '@id_idx 1', where: {id: 1})
    end
  end
end
