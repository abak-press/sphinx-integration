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

          def select(values, index_name, where)
            query = ::Riddle::Query::Select.
              new.
              reset_values.
              values(values).
              from(index_name).
              where(where).
              to_sql
            execute(query).to_a
          end

          def find_in_batches(index_name, where, options = {})
            bound = select("min(sphinx_internal_id) as min_id, max(sphinx_internal_id) as max_id",
                                  index_name,
                                  where).first
            return unless bound

            min = bound["min_id"].to_i
            max = bound["max_id"].to_i
            return if max.zero?
            batch_size = options.fetch(:batch_size, 1_000)

            while min <= max
              where[:sphinx_internal_id] = Range.new(min, min + batch_size - 1)
              ids = select("sphinx_internal_id", index_name, where).map { |row| row["sphinx_internal_id"].to_i }
              yield ids if ids.any?
              min += batch_size
            end
          end
        end
      end
    end
  end
end
