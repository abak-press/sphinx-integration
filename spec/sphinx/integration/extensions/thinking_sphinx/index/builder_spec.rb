require 'spec_helper'

describe ThinkingSphinx::Index::Builder do

  describe 'left_join' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        left_join(:rubrics).on('rubrics.id = model.rubric_id').as(:rubs)
      end
    end

    it { expect(index.local_options[:source_joins].size).to eq 1 }
    it { expect(index.local_options[:source_joins][:rubrics]).to be_present }
    it do
      join = index.local_options[:source_joins][:rubrics]
      expect(join).to include(type: :left, on: "rubrics.id = model.rubric_id", as: :rubs)
    end

    context 'when joins the same table twice' do
      let(:index) do
        ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
          left_join(:rubrics).on('rubrics.id = model.rubric_id')
          left_join(:rubrics => :rubrics_alias).on('rubrics_alias.id = model.rubric_id')
        end
      end
      let(:join) { index.local_options[:source_joins] }

      it do
        expect(join).to eq(
          :rubrics => {
            :table_name => :rubrics,
            :as => :rubrics,
            :type => :left,
            :on => 'rubrics.id = model.rubric_id'
          },
          :rubrics_alias => {
            :table_name => :rubrics,
            :as => :rubrics_alias,
            :type => :left,
            :on => 'rubrics_alias.id = model.rubric_id'
          }
        )
      end
    end
  end

  describe 'inner_join' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        inner_join(:rubrics).on('rubrics.id = model.rubric_id').as(:rubs)
      end
    end

    it { expect(index.local_options[:source_joins].size).to eq 1 }
    it { expect(index.local_options[:source_joins][:rubrics]).to be_present }
    it do
      index.local_options[:source_joins][:rubrics]
      join = index.local_options[:source_joins][:rubrics]
      expect(join).to include(type: :inner, on: "rubrics.id = model.rubric_id", as: :rubs)
    end
  end

  describe 'delete_joins' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        left_join(:rubrics).on('rubrics.id = model.rubric_id').as(:rubs)
        left_join(:foo).on('rubrics.id = model.rubric_id').as(:rubs)
        left_join(:bar).on('rubrics.id = model.rubric_id').as(:rubs)
        left_join(rubrics: :baz).on('rubrics.id = model.rubric_id').as(:rubs)
        left_join(rubrics: :qux).on('rubrics.id = model.rubric_id').as(:rubs)

        delete_joins(:rubrics, :bar, :qux)
      end
    end

    it do
      expect(index.local_options[:source_joins].size).to eq 2
      expect(index.local_options[:source_joins][:foo]).to be_present
      expect(index.local_options[:source_joins][:baz]).to be_present
    end
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
    it { expect(index.attributes.size).to eq 5 }
    it { expect(index.attributes.select { |attr| attr.alias == :foo }).to be_present }
  end

  describe 'delete_fields' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        indexes 'content1', :as => :content1
        indexes 'content2', :as => :content2

        delete_fields(:content, :content1)
      end
    end

    it { expect(index.fields.size).to eq 1 }
    it { expect(index.fields.select { |attr| attr.alias == :content2 }).to be_present }
  end

  describe 'limit' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        limit(10)
      end
    end

    it { expect(index.local_options[:sql_query_limit]).to eq 10 }
  end

  describe 'with' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        with(:_rubrics) { "select id from rubrics {{where}}" }
      end
    end

    it { expect(index.local_options[:source_cte].size).to eq 1 }
    it { expect(index.local_options[:source_cte][:_rubrics]).to eq "select id from rubrics {{where}}" }
  end

  describe 'delete with' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk) do
        with(:_rubrics1) { "select id from rubrics1" }
        with(:_rubrics2) { "select id from rubrics2" }

        delete_withs(:_rubrics1)
      end
    end

    it { expect(index.local_options[:source_cte].size).to eq 1 }
    it { expect(index.local_options[:source_cte][:_rubrics2]).to eq "select id from rubrics2" }
  end

  describe 'composite_index' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk, nil) do
        composite_index :numbers, z: '1', a: '2'
      end
    end

    it { expect(index.local_options[:composite_indexes].size).to eq 1 }
    it { expect(index.local_options[:composite_indexes][:numbers].keys).to eq [:a, :z] }
    it { expect(index.fields.find { |attr| attr.alias == :numbers }).to be_present }
    it { expect(index.sources.first.to_sql).to include "concat_ws(' ', 2, 1) AS \"numbers\"" }
  end

  describe 'replace_composite_index_fields' do
    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk, nil) do
        composite_index :numbers, z: '1', a: '2'

        replace_composite_index_fields :numbers, z: '3'
      end
    end

    it { expect(index.local_options[:composite_indexes].size).to eq 1 }
    it { expect(index.local_options[:composite_indexes][:numbers].keys).to eq [:a, :z] }
    it { expect(index.fields.find { |attr| attr.alias == :numbers }).to be_present }
    it { expect(index.sources.first.to_sql).to include "concat_ws(' ', 2, 3) AS \"numbers\"" }

    context 'called on not exist index' do
      let(:index) do
        ThinkingSphinx::Index::Builder.generate(ModelWithDisk, nil) do
          composite_index :numbers, z: '1', a: '2'

          replace_composite_index_fields :numbers2, z: '3'
        end
      end

      it { expect { index }.to raise_error(KeyError, 'key not found: :numbers2') }
    end
  end
end
