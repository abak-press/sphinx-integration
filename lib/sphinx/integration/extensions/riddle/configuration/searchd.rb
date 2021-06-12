# frozen_string_literal: true
module Sphinx
  module Integration
    module Extensions
      module Riddle
        module Configuration
          module Searchd
            def self.included(base)
              # Специальный порт для служебных задач мониторинга
              #
              # Все запросы, отправленные через данный порт,
              # исполняются в обход очереди thread pool, и исполняются сразу (в случае если `workers=thread_pool`).
              # То есть они не учитываются в лимите назначенном через настройку `queue_max_length`
              #
              # Пруфы (на момент коммита у нас была версия 3.0.2):
              #   https://github.com/manticoresoftware/manticoresearch/blob/01dd0122f4c51a0a7e1056f5543106d8abd73c4f/src/searchd.cpp#L22757
              #   https://github.com/manticoresoftware/manticoresearch/blob/01dd0122f4c51a0a7e1056f5543106d8abd73c4f/src/searchd.cpp#L22764
              #
              # Документация: https://docs.manticoresearch.com/3.0.2/singlehtml/index.html#listen
              base.send(:attr_accessor, :mysql41_vip)

              # https://docs.manticoresearch.com/3.0.2/singlehtml/index.html#queue-max-length
              base.send(:attr_accessor, :queue_max_length)

              base.send(
                :attr_accessor,
                :access_plain_attrs, :access_blob_attrs, :access_doclists, :access_hitlists, :read_buffer_docs,
                :read_buffer_hits
              )

              orig_settings = base.method(:settings)
              base.define_singleton_method :settings do |*args|
                result_settings = orig_settings.call(*args)
                result_settings += [
                  :queue_max_length,
                  :access_plain_attrs,
                  :access_blob_attrs,
                  :access_doclists,
                  :access_hitlists,
                  :read_buffer_docs,
                  :read_buffer_hits
                ]

                result_settings
              end
            end
          end
        end
      end
    end
  end
end
