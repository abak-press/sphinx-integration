module Sphinx
  module Integration
    module Statements
      class Distributed
        MATCHING_STMT_RE = /\@([^ ]+) ([^@]+)/.freeze
        private_constant :MATCHING_STMT_RE

        delegate :read, :write, to: '::ThinkingSphinx::Configuration.instance.mysql_client'

        def initialize(index)
          @index = index
        end

        def update(data, matching: nil, where: {})
          sql = ::Sphinx::Integration::Extensions::Riddle::Query::Update.
            new(index_name, data, where.merge!(sphinx_deleted: 0), prepare_matching(matching)).
            to_sql

          write(sql)

          yield(sql) if block_given?
        end

        def soft_delete(document_id)
          sql = ::Sphinx::Integration::Extensions::Riddle::Query::Update.
            new(index_name, {sphinx_deleted: 1}, {id: document_id, sphinx_deleted: 0}, nil).
            to_sql

          write(sql)

          yield(sql) if block_given?
        end

        def select(values, matching: nil, where: {}, where_not: {}, order_by: nil, limit: nil)
          limit ||= ::ThinkingSphinx.max_matches
          where[:sphinx_deleted] = 0

          query = ::Riddle::Query::Select.new.reset_values.
            values(values).
            from(index_name).
            matching(prepare_matching(matching)).
            where(where).
            where_not(where_not).
            order_by(order_by).
            limit(limit).
            with_options(max_matches: ::ThinkingSphinx.max_matches)

          read(query.to_sql).to_a
        end

        def find_while_exists(values, matching: nil, where: {}, where_not: {})
          100_000_000.times do
            records = select(values, matching: matching, where: where, where_not: where_not)
            return if records.empty?
            yield records
          end

          raise "Infinite loop detected"
        end

        def find_in_batches(primary_key: 'sphinx_internal_id', batch_size: 1_000, matching: nil,
                            where: {}, where_not: {})
          batch_order = "#{primary_key} ASC"
          where[primary_key.to_sym] = -> { "> 0" }
          where[:sphinx_deleted] = 0

          loop do
            records = select(primary_key, matching: matching, where: where, where_not: where_not,
                                          order_by: batch_order, limit: batch_size)
            break if records.empty?

            yield records

            break if records.size < batch_size

            primary_key_offset = records.last[primary_key].to_i
            where[primary_key.to_sym] = -> { "> #{primary_key_offset}" }
          end
        end

        # Public: отправит запрос в привилегированный порт
        def write_to_vip_port(query, host = nil)
          config.with_custom_read_timeout(Rails.application.config.sphinx_integration[:vip_client_read_timeout]) do
            config.mysql_vip_client(host).write(query)
          end
        end

        private

        def config
          ::ThinkingSphinx::Configuration.instance
        end

        def index_name
          @index.name
        end

        # Переписывает matching, подменяя поля композитного индекса на композитный индекс
        #
        # matching - String or Hash of [Symbol, String]
        #
        # Returns String
        def prepare_matching(matching)
          return nil unless matching

          matching =
            case matching
            when Hash
              matching.map { |field, match| [composite_indexes_map[field] || field, match] }
            when String
              matching.scan(MATCHING_STMT_RE).map do |field, match|
                field = field.to_sym
                [composite_indexes_map[field] || field, match.strip]
              end
            else
              raise "unreachable #{matching.class}"
            end

          matching.map { |field, match| "@#{field} #{match}" }.join(' '.freeze)
        end

        # Карта перезаписи полей копозитных индексов
        #
        # Returns Hash
        def composite_indexes_map
          return @composite_indexes_map if defined?(@composite_indexes_map)

          composite_indexes = @index.local_options.fetch(:composite_indexes, {})

          @composite_indexes_map = composite_indexes.each_with_object({}) do |(name, fields), memo|
            fields.each_key do |field_name|
              memo[field_name] ||= name
            end
          end
        end
      end
    end
  end
end
