# coding: utf-8
require 'spec_helper'

describe ActiveRecord::Base do

  before(:all){ ThinkingSphinx.context.define_indexes }

  describe '.max_matches' do
    subject { ActiveRecord::Base.max_matches }
    it { should be_a(Integer) }
    it { should eq 5000 }
  end

  describe '.define_secondary_index' do
    subject { ModelWithSecondDisk.sphinx_indexes.detect{ |x| x.name == 'model_with_second_disk_delta' } }
    it { should_not be_nil }
    its(:merged_with_core) { should be_true }
  end

  describe '.reset_indexes' do
    before { ModelWithDisk.reset_indexes }
    after { ModelWithDisk.define_indexes }

    subject { ModelWithDisk }
    its(:sphinx_index_blocks) { should be_empty }
    its(:sphinx_indexes) { should be_empty }
    its(:sphinx_facets) { should be_empty }
    its(:defined_indexes?) { should be_false }
  end

  describe '.rt_indexed_by_sphinx?' do
    it { ModelWithRt.rt_indexed_by_sphinx?.should be_true }
  end

  describe '.methods_for_mva_attributes' do
    it { ModelWithRt.methods_for_mva_attributes.should eq [:mva_sphinx_attributes_for_rubrics] }
  end

end