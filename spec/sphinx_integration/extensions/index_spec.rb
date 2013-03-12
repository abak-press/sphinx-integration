# coding: utf-8
require 'spec_helper'

describe 'ThinkingSphinx Index extension' do

  let(:index) do
    index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
      indexes 'content', :as => :content
      has 'region_id', :type => :integer, :as => :region_id
      set_property :rt => true
    end
  end

  describe '#to_riddle_with_merged' do
    subject { index.to_riddle_with_merged(0) }

    it 'generate rt index' do
      subject.
        select{ |x| x.is_a?(Riddle::Configuration::RealtimeIndex) }.
        should have(2).items
    end

    it 'generate core index' do
      subject.
        select{ |x| x.is_a?(Riddle::Configuration::Index) }.
        should have(1).items
    end

    it 'generate distributed index' do
      subject.
        select{ |x| x.is_a?(Riddle::Configuration::DistributedIndex) }.
        should have(1).item
    end
  end

  describe '#to_riddle_for_rt' do
    subject { index.to_riddle_for_rt }
    its(:name){ should eql 'post_rt' }
    its(:rt_field){ should have(1).item }
    its(:rt_attr_uint){ should eql [:sphinx_internal_id, :sphinx_deleted, :class_crc, :region_id] }
  end

end