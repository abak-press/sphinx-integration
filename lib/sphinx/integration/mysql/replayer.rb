require 'set'

module Sphinx
  module Integration
    module Mysql
      class Replayer
        include ::Sphinx::Integration::AutoInject.hash[logger: "logger.stdout"]

        delegate :mysql_client, :update_log, :soft_delete_log, to: '::ThinkingSphinx::Configuration.instance'

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
          replay_update_log
          replay_soft_delete_log
          logger.info "Replaying was finished"
        end

        def reset
          logger.info "Reset query logs"
          update_log.reset
          soft_delete_log.reset
        end

        private

        def replay_update_log
          logger.info "Replay #{update_log.size} queries for update"

          count = 0
          update_log.each_batch(batch_size: 50) do |payloads|
            queries = payloads.map { |payload| payload.fetch(:query) }
            mysql_client.batch_write(queries)
            count += queries.size
          end

          logger.info "Replayed total #{count} queries for update"
        end

        def replay_soft_delete_log
          logger.info "Replay #{soft_delete_log.size} queries for soft delete"

          soft_delete_log.each_batch(batch_size: 1_000) do |payloads|
            ids_by_indexes = payloads.each_with_object({}) do |payload, memo|
              index_name = payload.fetch(:index_name)
              ids = (memo[index_name] ||= Set.new)

              if (document_id = payload.fetch(:document_id)).respond_to?(:each)
                ids.merge(document_id)
              else
                ids.add(document_id)
              end
            end

            ids_by_indexes.each do |index_name, ids|
              sql = ::Sphinx::Integration::Extensions::Riddle::Query::Update.
                new(index_name, {sphinx_deleted: 1}, {id: ids.to_a, sphinx_deleted: 0}, nil).
                to_sql

              mysql_client.write(sql)
            end
          end
        end
      end
    end
  end
end
