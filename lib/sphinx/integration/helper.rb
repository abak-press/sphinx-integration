# coding: utf-8
module Sphinx::Integration
  class Helper
    module ClassMethods

      def config
        ThinkingSphinx::Configuration.instance
      end

      def sphinx_running?
        if config.remote?
          `#{Rails.root}/script/sphinx --status`.present?
        else
          ThinkingSphinx.sphinx_running?
        end
      end

      def run_command(command)
        puts "System: #{command}"
        system command
      end

      def stop
        if config.remote?
          run_command("#{Rails.root}/script/sphinx --stop")
        else
          run_command "searchd --config #{config.config_file} --stop"
        end
      end

      def start
        if config.remote?
          run_command("#{Rails.root}/script/sphinx --start")
        else
          run_command "searchd --config #{config.config_file}"
        end
      end

      def running_start
        stop if sphinx_running?
        start
      end

      def index(online = true)
        Redis::Mutex.with_lock(:full_reindex, :expire => 3.hours) do
          if config.remote?
            run_command("#{Rails.root}/script/sphinx --reindex-offline") unless online
            run_command("#{Rails.root}/script/sphinx --reindex-online")  if  online
          else
            run_command "indexer --config #{config.config_file} --all" unless online
            run_command "indexer --config #{config.config_file} --rotate --all" if online
          end
        end

        prepare_rt if online
      end
      alias_method :reindex, :index

      # Очистить и Заполнить rt индексы
      def prepare_rt(only_index = nil)
        ThinkingSphinx.context.indexed_models.each do |model_name|
          model = model_name.constantize
          next unless model.rt_indexed_by_sphinx?

          model.sphinx_indexes.each do |index|
            next if only_index && only_index != index.name
            # очистим rt индексы
            ThinkingSphinx.take_connection do |c|
              c.execute("TRUNCATE RTINDEX #{index.rt_name}")
            end

            # после этого нужно накатить дельту на основной rt индекс
            # просто за атачить её нельзя, смёрджить тоже нельзя, поэтому будем апдейтить по одной
            until model.search_count(:index => index.delta_rt_name).zero? do
              model.search(:index => index.delta_rt_name, :per_page => 500).each do |record|
                record.transmitter_replace
                query = Riddle::Query::Delete.new(index.delta_rt_name, record.sphinx_document_id)
                ThinkingSphinx.take_connection{ |c| c.execute(query.to_sql) }
              end
            end
          end
        end
      end

      def configure
        puts "Generating Configuration to #{config.config_file}"
        config.build
      end

      def rebuild
        configure

        if config.remote?
          run_command("#{Rails.root}/script/sphinx --copy-config #{config.config_file}")
        end

        stop if sphinx_running?
        index(false)
        start
        prepare_rt
      end

      def full_reindex?
        Redis::Mutex.new(:full_reindex).locked?
      end

    end

    extend ClassMethods
  end
end