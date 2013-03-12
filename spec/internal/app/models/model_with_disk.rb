# coding: utf-8
class ModelWithDisk < ActiveRecord::Base

  define_index('model_with_disk') do
    indexes 'content', :as => :content
    has 'region_id', :type => :integer, :as => :region_id
  end

end