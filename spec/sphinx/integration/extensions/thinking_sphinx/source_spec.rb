# coding: utf-8
require 'spec_helper'

describe ThinkingSphinx::Source do
  let(:index_source) { index.sources.first }

  describe '#set_source_database_settings' do
    let(:db_config) do
      {
        :test_first_slave => {
          :host => 'first-slave',
          :username => 'first-slave-root',
          :database => 'first-slave-db'
        },
        :test_slave => {
          :host => 'default-slave',
          :username => 'default-slave-root',
          :database => 'default-slave-db'
        },
        :test => {
          :host => 'test',
          :username => 'test-root',
          :database => 'test-db'
        }
      }.with_indifferent_access
    end

    before do
      allow(index_source).to receive(:db_config).and_return(db_config)
      index_source.instance_variable_set(:@database_configuration, db_config[:test])
    end

    subject { index_source.to_riddle_for_core(0, 0) }

    context 'when slave' do
      context 'when slave property is string' do
        let(:index) do
          ThinkingSphinx::Index::Builder.generate(ModelWithDisk, nil) do
            indexes 'content', :as => :content
            set_property :use_slave_db => 'first_slave'
          end
        end

        its(:sql_host){ should eq db_config[:test_first_slave][:host] }
        its(:sql_user){ should eq db_config[:test_first_slave][:username] }
        its(:sql_db){ should eq db_config[:test_first_slave][:database] }
      end

      context 'when slave property is true' do
        let(:index) do
          ThinkingSphinx::Index::Builder.generate(ModelWithDisk, nil) do
            indexes 'content', :as => :content
            set_property :use_slave_db => true
          end
        end

        its(:sql_host){ should eq db_config[:test_slave][:host] }
        its(:sql_user){ should eq db_config[:test_slave][:username] }
        its(:sql_db){ should eq db_config[:test_slave][:database] }
      end

      context 'when without slave property' do
        let(:index) do
          ThinkingSphinx::Index::Builder.generate(ModelWithDisk, nil) do
            indexes 'content', :as => :content
          end
        end

        its(:sql_host){ should eq db_config[:test][:host] }
        its(:sql_user){ should eq db_config[:test][:username] }
        its(:sql_db){ should eq db_config[:test][:database] }
      end
    end
  end

  describe '#db_config' do
    let(:database_config) do
      YAML.load(ERB.new(File.read(Rails.root.join("config", "database.yml"))).result)
    end

    let(:index) do
      ThinkingSphinx::Index::Builder.generate(ModelWithDisk, nil) do
        indexes 'content', :as => :content
        set_property :use_slave_db => 'test'
      end
    end

    it do
      expect(index_source.db_config).to eq database_config
    end
  end
end
