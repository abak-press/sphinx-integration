# coding: utf-8
require 'spec_helper'

describe ThinkingSphinx::Index::Builder do

  describe 'left_join' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        left_join(:rubrics).on('rubrics.id = model.rubric_id').as(:rubs)
      end
    end

    it { index.local_options[:source_joins].should have(1).item }
    it { index.local_options[:source_joins][:rubrics].should be_present }

    subject { index.local_options[:source_joins][:rubrics] }
    its([:type]) { should eq :left }
    its([:on]) { should eq 'rubrics.id = model.rubric_id' }
    its([:as]) { should eq :rubs }
  end

  describe 'inner_join' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        inner_join(:rubrics).on('rubrics.id = model.rubric_id').as(:rubs)
      end
    end

    it { index.local_options[:source_joins].should have(1).item }
    it { index.local_options[:source_joins][:rubrics].should be_present }

    subject { index.local_options[:source_joins][:rubrics] }
    its([:type]) { should eq :inner }
    its([:on]) { should eq 'rubrics.id = model.rubric_id' }
    its([:as]) { should eq :rubs }
  end

  describe 'delete_joins' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        left_join(:rubrics).on('rubrics.id = model.rubric_id').as(:rubs)
        left_join(:foo).on('rubrics.id = model.rubric_id').as(:rubs)
        left_join(:bar).on('rubrics.id = model.rubric_id').as(:rubs)

        delete_joins(:rubrics, :bar)
      end
    end

    it { index.local_options[:source_joins].should have(1).item }
    it { index.local_options[:source_joins][:foo].should be_present }
  end

  describe 'delete_attributes' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        has 'foo', :type => :integer, :as => 'foo'
        has 'bar', :type => :integer, :as => 'bar'

        delete_attributes(:region_id, :bar)
      end
    end

    # 4 internal (:sphinx_internal_id, :sphinx_deleted, :class_crc, :sphinx_internal_class) + 1 user
    it { index.attributes.should have(5).item }
    it { index.attributes.select { |attr| attr.alias == :foo }.should be_present }
  end

  describe 'delete_fields' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        indexes 'content1', :as => :content1
        indexes 'content2', :as => :content2

        delete_fields(:content, :content1)
      end
    end

    it { index.fields.should have(1).item }
    it { index.fields.select { |attr| attr.alias == :content2 }.should be_present }
  end

  describe 'limit' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        limit(10)
      end
    end

    it { index.local_options[:sql_query_limit].should eq 10 }
  end

  describe 'with' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        with(:_rubrics) { "select id from rubrics {{where}}" }
      end
    end

    it { index.local_options[:source_cte].should have(1).item }
    it { index.local_options[:source_cte][:_rubrics].should == "select id from rubrics {{where}}" }
  end

  describe 'delete with' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        with(:_rubrics1) { "select id from rubrics1" }
        with(:_rubrics2) { "select id from rubrics2" }

        delete_withs(:_rubrics1)
      end
    end

    it { index.local_options[:source_cte].should have(1).item }
    it { index.local_options[:source_cte][:_rubrics2].should == "select id from rubrics2" }
  end
end