require 'set'

module Sphinx
  module Integration
    module Mysql
      class Replayer
        TIMEOUT = 60.seconds
        UPDATE_BATCH_SIZE = 50
        SOFT_DELETE_BATCH_SIZE = 500

        delegate :mysql_client, :update_log, :soft_delete_log, to: :sphinx_config
        attr_reader :logger

        def initialize(index_name, options = {})
          @index_name = index_name
          @logger = options[:logger] || ::Sphinx::Integration.fetch(:di)[:loggers][:indexer_file].call
        end

        # Проигрывание запросов из QueryLog
        #
        # Общая схема работы такая:
        #
        # 1) Запустили индексацию и запись лога
        # 2) Будем, например, рассматривать какою-то строку с каком-то то полем, до запуска там было значение А
        # 3) Индексатор уже пробежал ее и в новый core положил то же значение А
        # 4) Прилетел запрос на обновление этой строки значением Б, в старый (пока активный) core записали Б
        #    и записали Б в лог
        # 5) Закончилась индексация, ротировался core, пока видно только значение А, начинаем проигрывать лог
        # 6) Опять прилетел запрос на обновление этой строки значением В, в core записали В и записали В в лог
        # 7) Проигрывать лога дошел до этой строки и записал в core значение Б
        # 8) Проигрыватель лога опять дошел до этой строки и записал в core значение В
        # 9) У проигрывателя закончились записи, но он еще не успел выключить запись лог,
        #    но это не страшно, так как это уже не имеет никакого значения.
        def replay
          replay_soft_delete_log
          replay_soft_delete_from_rt
          replay_update_log
          logger.info "Replaying of #{@index_name} was finished"
        end

        def reset
          logger.info "Reset #{@index_name} query logs"
          update_log.reset(@index_name)
          soft_delete_log.reset(@index_name)
        end

        private

        def replay_update_log
          logger.info "Replay #{update_log.size(@index_name)} #{@index_name} queries for update"

          count = 0

          update_log.each_batch(@index_name, batch_size: UPDATE_BATCH_SIZE) do |payloads|
            queries = payloads.map { |payload| payload.fetch(:query) }
            mysql_client.batch_write(queries)

            count += queries.size
          end

          logger.info "Replayed total #{count} #{@index_name} queries for update"
        end

        def replay_soft_delete_log
          logger.info "Replay #{soft_delete_log.size(@index_name)} #{@index_name} queries for soft delete"

          count = 0

          soft_delete_log.each_batch(@index_name, batch_size: SOFT_DELETE_BATCH_SIZE) do |payloads|
            ids = Set.new

            payloads.each do |payload|
              if (document_id = payload.fetch(:document_id)).respond_to?(:each)
                ids.merge(document_id)
              else
                ids.add(document_id)
              end
            end

            ids.each_slice(SOFT_DELETE_BATCH_SIZE) { |batch| soft_delete(batch) }

            count += ids.size
          end

          logger.info "Replayed total #{count} #{@index_name} queries for soft delete"
        end

        def replay_soft_delete_from_rt
          rt_index = ThinkingSphinx.indexes.find { |index| index.core_name == @index_name }.rt

          logger.info "Replay #{@index_name} soft delete from rt"

          count = 0

          rt_index.find_in_batches(primary_key: 'id', batch_size: SOFT_DELETE_BATCH_SIZE) do |ids|
            soft_delete(ids.map { |id| id['id'] })

            count += ids.size
          end

          logger.info "Replayed total #{count} #{@index_name} soft delete from rt"
        end

        def soft_delete(ids)
          sql = ::Sphinx::Integration::Extensions::Riddle::Query::Update.
            new(@index_name, {sphinx_deleted: 1}, {id: ids, sphinx_deleted: 0}, nil).
            to_sql

          mysql_client.write(sql)
        end

        def sphinx_config
          @sphinx_config ||= ThinkingSphinx::Configuration.instance.tap { |config| config.mysql_read_timeout = TIMEOUT }
        end
      end
    end
  end
end
