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
end
