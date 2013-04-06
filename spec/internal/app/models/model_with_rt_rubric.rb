# coding: utf-8
class ModelWithRtRubric < ActiveRecord::Base
  belongs_to :model_with_rt
  belongs_to :rubrics
end