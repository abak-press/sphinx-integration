# coding: utf-8
require 'spec_helper'

describe 'specifying SQL for index definition' do

  describe '#sql_query_info' do
    it 'generate default table name' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
      end
      index.sources.first.to_sql_query_info(0).should include('"posts"')
    end

    it 'generate custom table name' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        set_property :source_table => 'custom_posts'
      end
      index.sources.first.to_sql_query_info(0).should include('"custom_posts"')
    end
  end

  describe '#to_sql' do
    it 'generate cte' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        set_property :source_cte => {
          :post_cte => 'select id from temp_table where {{where}}'
        }
      end
      expected_sql = 'WITH post_cte AS (select id from temp_table where "posts"."id" >= $start AND "posts"."id" <= $end)'
      index.sources.first.to_sql(:offset => 0).should include(expected_sql)
    end

    it 'generate joins' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        set_property :source_joins => {
          :rubrics => {:type => :left, :on => 'posts.rubric_id = rubrics.id'},
        }
      end
      expected_sql = 'LEFT JOIN rubrics AS rubrics ON posts.rubric_id = rubrics.id'
      index.sources.first.to_sql(:offset => 0).should include(expected_sql)
    end

    it 'generate no groupping' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        set_property :source_no_grouping => true
      end
      index.sources.first.to_sql(:offset => 0).should_not include('GROUP BY')
    end

    it 'generate limit' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        set_property :sql_query_limit => 1000
      end
      index.sources.first.to_sql(:offset => 0).should include('LIMIT 100')
    end
  end

  describe '#to_sql_query_range' do
    it 'generate custom query range' do
      expected_sql = 'SELECT 1::int, COALESCE(MAX(id), 1::int) FROM products'
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        set_property :sql_query_range => expected_sql
      end
      index.sources.first.to_sql_query_range({}).should include(expected_sql)
    end

    it 'no generate query range' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        set_property :disable_range => true
      end
      index.sources.first.to_sql_query_range({}).should be_blank
    end
  end

  describe '#to_sql_query_info' do
    it 'generate default table name' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
      end
      index.sources.first.to_sql_query_info(0).should include('"posts"')
    end

    it 'generate custom table name' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        set_property :source_table => 'custom_posts'
      end
      index.sources.first.to_sql_query_info(0).should include('"custom_posts"')
    end
  end

  describe '#sql_select_clause' do
    it 'generate default table name' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
      end
      index.sources.first.sql_select_clause(0).should include('"posts"."id"')
    end

    it 'generate custom table name' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        set_property :source_table => 'custom_posts'
      end
      index.sources.first.sql_select_clause(0).should include('"custom_posts"."id"')
    end
  end

  describe '#sql_where_clause' do
    it 'generate without range' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        set_property :use_own_sql_query_range => true
      end
      index.sources.first.sql_select_clause(0).should_not include('$start', '$end')
    end
  end

  describe '#sql_group_clause' do
    it 'generate custom groupings' do
      index = ThinkingSphinx::Index::Builder.generate(Post, nil) do
        indexes 'content', :as => :content
        group_by! :id, :region_id
      end
      index.sources.first.sql_group_clause.should eql 'id, region_id'
    end
  end

end