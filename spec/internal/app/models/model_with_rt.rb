# coding: utf-8
class ModelWithRt < ActiveRecord::Base
  has_many :model_with_rt_rubrics
  has_many :rubrics, :through => :model_with_rt_rubrics

  define_index('model_with_rt') do
    indexes 'name', :as => :name
    has 'region_id', :type => :integer, :as => :region_id
    has :rubrics, :type => :multi, :source => :ranged_query, :query => "SELECT {{model_with_rt_id}} AS id, rubric_id AS rubrics FROM model_with_rt_rubrics WHERE id>=$start AND id<=$end; SELECT MIN(id), MAX(id) FROM model_with_rt_rubrics"
    set_property :rt => true
  end

  def mva_sphinx_attributes_for_rubrics
    model_with_rt_rubrics.map(&:rubric_id)
  end

end