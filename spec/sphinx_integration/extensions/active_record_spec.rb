# coding: utf-8
require 'spec_helper'

describe 'ActiveRecord::Base extensions' do

  describe '.max_matches' do
    subject { Post.max_matches }
    it { should be_a(Integer) }
    it { should eq 5000 }
  end

  describe '.define_secondary_index' do
    
  end

end