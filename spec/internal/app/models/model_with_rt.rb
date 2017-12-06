# coding: utf-8
class ModelWithRt < ActiveRecord::Base
  has_many :model_with_rt_rubrics
  has_many :rubrics, :through => :model_with_rt_rubrics

  define_index('model_with_rt') do
    indexes 'content', :as => :content
    has 'region_id', :type => :integer, :as => :region_id
    has :rubrics, :type => :multi, :source => :ranged_query, :query => "SELECT {{model_with_rt_id}} AS id, rubric_id AS rubrics FROM model_with_rt_rubrics WHERE id>=$start AND id<=$end; SELECT MIN(id), MAX(id) FROM model_with_rt_rubrics"
    composite_index :composite_idx, a_idx: "'a'", b_idx: "'b'"

    set_property :rt => true
    set_property :source_no_grouping => true

    mva_attribute :rubrics do |record|
      record.model_with_rt_rubrics.map(&:rubric_id)
    end
  end

end
