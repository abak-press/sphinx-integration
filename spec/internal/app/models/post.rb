# coding: utf-8
class Post < ActiveRecord::Base

  define_index('post') do
    indexes 'content', :as => :content
    has 'region_id', :type => :integer, :as => :region_id
  end

end