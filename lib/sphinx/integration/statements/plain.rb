module Sphinx
  module Integration
    module Statements
      class Plain < Core
        delegate :update_log, :soft_delete_log, to: '::ThinkingSphinx::Configuration.instance'

        def update(*)
          super do |index_name, sql|
            update_log.add(index_name, query: sql)
          end
        end

        def soft_delete(document_id)
          super do |index_name, _sql|
            soft_delete_log.add(index_name, document_id: document_id)
          end
        end

        private

        def write(sql) end
      end
    end
  end
end
