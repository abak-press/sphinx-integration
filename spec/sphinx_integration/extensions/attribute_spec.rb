# coding: utf-8
require 'spec_helper'

describe 'specifying SQL for attribute definition' do

  describe '#source_value' do
    it 'generate custom sql' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        has :regions, :type => :multi, :source => :ranged_query, :query => "SELECT {{post_id}} AS id, region_id AS regions FROM post_regions WHERE id>=$start AND id<=$end; SELECT MIN(id), MAX(id) FROM post_regions", :as => :regions
      end
      exptected_sql = 'query; SELECT post_id * 1::INT8 + 0 AS id, region_id AS regions FROM post_regions WHERE id>=$start AND id<=$end; SELECT MIN(id), MAX(id) FROM post_regions'
      index.sources.first.attributes.detect{ |x| x.unique_name == :regions }.send(:source_value, 0, false).should eql exptected_sql
    end
  end

end