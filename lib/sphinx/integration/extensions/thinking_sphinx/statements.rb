module Sphinx
  module Integration
    module Extensions
      module ThinkingSphinx
        module Statements
          def replace(index_name, data)
            query = ::Riddle::Query::Insert.new(index_name, data.keys, data.values).replace!.to_sql
            execute(query, on_slaves: replication?)
          end

          def update(index_name, data, where)
            query = ::Sphinx::Integration::Extensions::Riddle::Query::Update.new(index_name, data, where).to_sql
            execute(query)
          end

          def delete(index_name, document_id)
            query = ::Riddle::Query::Delete.new(index_name, document_id).to_sql
            execute(query)
          end

          def soft_delete(index_name, document_id)
            update(index_name, {sphinx_deleted: 1}, {id: document_id})
          end

          def select(values, index_name, where, limit = nil)
            query = ::Riddle::Query::Select.
              new.
              reset_values.
              values(values).
              from(index_name).
              where(where).
              limit(limit).
              to_sql
            execute(query).to_a
          end

          def find_in_batches(index_name, options = {})
            primary_key = options.fetch(:primary_key, "sphinx_internal_id").to_s.freeze
            batch_size = options.fetch(:batch_size, 1_000)
            batch_order = "#{primary_key} ASC"
            where = options.fetch(:where, {})
            where[primary_key.to_sym] = -> { "> 0" }

            query = ::Riddle::Query::Select.new.reset_values.
              values(primary_key).
              from(index_name).
              where(where).
              order_by(batch_order).
              limit(batch_size).
              matching(options[:matching])

            records = execute(query.to_sql).to_a
            while records.any?
              primary_key_offset = records.last[primary_key].to_i

              records.map! { |record| record[primary_key].to_i }
              yield records

              break if records.size < batch_size

              where[primary_key.to_sym] = -> { "> #{primary_key_offset}" }
              query.where(where)
              records = execute(query.to_sql).to_a
            end
          end
        end
      end
    end
  end
end
