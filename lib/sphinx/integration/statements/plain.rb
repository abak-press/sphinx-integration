module Sphinx
  module Integration
    module Statements
      class Plain < Distributed
        delegate :update_log, :soft_delete_log, to: '::ThinkingSphinx::Configuration.instance'

        def update(*)
          super do |_index_name, sql|
            update_log.add(query: sql) if @index.indexing?
          end
        end

        def soft_delete(document_id)
          super do |index_name, _sql|
            soft_delete_log.add(index_name: index_name, document_id: document_id) if @index.indexing?
          end
        end

        private

        def index_names
          yield first_index_name
        end

        def first_index_name
          @index.core_name
        end
      end
    end
  end
end
