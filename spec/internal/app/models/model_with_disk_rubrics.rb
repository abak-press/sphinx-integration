# coding: utf-8
class ModelWithDiskRubrics < ActiveRecord::Base
  belongs_to :model_with_disk
  belongs_to :rubrics
end