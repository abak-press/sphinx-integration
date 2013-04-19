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
    it { puts index.local_options[:source_cte][:_rubrics].should == "select id from rubrics {{where}}" }
  end

end