# coding: utf-8
require 'spec_helper'

describe ThinkingSphinx::Index do

  let(:index) do
    ThinkingSphinx::Index::Builder.generate(ModelWithDisk, nil) do
      indexes 'content', :as => :content
      has 'region_id', :type => :integer, :as => :region_id
      set_property :rt => true
    end
  end

  describe '#to_riddle_with_merged' do
    context 'when single or slave mode' do
      let(:result) { index.to_riddle(0, :single) }

      it 'generate core index' do
        result.
          select{ |x| x.is_a?(Riddle::Configuration::Index) }.
          should have(1).items
      end

      it 'generate rt index' do
        result.
          select{ |x| x.is_a?(Riddle::Configuration::RealtimeIndex) }.
          should have(2).items
      end

      it 'generate distributed index' do
        result.
          select{ |x| x.is_a?(Riddle::Configuration::DistributedIndex) }.
          should have(1).item
      end
    end

    context 'when master mode' do
      let(:result) { index.to_riddle(0, :master) }
      let(:agents) { {'slave' => {'address' => 'slave0', 'port' => 10, 'mysql41' => 100}} }

      before { index.send(:config).stub(:agents).and_return(agents) }

      it 'all distributed' do
        result.all? { |x| x.is_a?(Riddle::Configuration::DistributedIndex) }
      end
    end
  end

  describe '#all_indexes_names' do
    it 'returns valid names' do
      expect(index.all_index_names).to eq %w(model_with_disk model_with_disk_core model_with_disk_rt model_with_disk_delta_rt)
    end
  end

  describe '#to_riddle_for_rt' do
    subject { index.to_riddle_for_rt }
    its(:name){ should eql 'model_with_disk_rt' }
    its(:rt_field){ should have(1).item }
    its(:rt_attr_uint){ should eql [:sphinx_internal_id, :sphinx_deleted, :class_crc, :region_id] }
  end

  describe '#all_names' do
    it 'returns only distributed index name' do
      index.all_names.should == [index.name]
    end
  end

end