# coding: utf-8

require 'redis'
require 'redis-namespace'

module Sphinx::Integration::Extensions::ThinkingSphinx::LastIndexingTime
  extend ActiveSupport::Concern

  included do
    class ThinkingSphinx::LastIndexing
      def self.set(key, value)
        redis.set(key, value)
      end

      def self.get(key)
        redis.get(key)
      end

      def self.redis
        @redis ||= Redis::Namespace.new(name, :redis => Redis.current)
      end
    end

    # Public: Устанавливает время окончания последней успешной индексации.
    #
    # time - Time - время окончания последней успешной индексации.
    #        По умолчанию: NOW() из основной БД приложения.
    #
    # Returns Time.
    def self.set_last_indexing_finish_time(time = nil)
      time = db_current_time unless time.present?
      ThinkingSphinx::LastIndexing.set(:finish_time, time)
      time
    end

    # Public: Возвращает время окончания последней успешной индексации.
    #
    # Если успешной идексации не было, то возвращает nil.
    #
    # Returns Time or Nil.
    def self.last_indexing_finish_time
      value = ThinkingSphinx::LastIndexing.get(:finish_time)
      value.to_time if value.present?
    end

    def self.db_current_time
      ::ActiveRecord::Base.connection.select_value('select NOW()').to_time
    end
  end
end