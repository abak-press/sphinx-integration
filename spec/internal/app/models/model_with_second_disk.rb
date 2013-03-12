# coding: utf-8
class ModelWithSecondDisk < ActiveRecord::Base

  define_index('model_with_second_disk') do
    indexes 'content', :as => :content
    has 'region_id', :type => :integer, :as => :region_id
  end

  define_secondary_index('model_with_second_disk_delta') do
    indexes 'content', :as => :content
    has 'region_id', :type => :integer, :as => :region_id
  end

end