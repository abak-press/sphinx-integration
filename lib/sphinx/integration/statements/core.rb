module Sphinx
  module Integration
    module Statements
      class Core < Distributed
        private

        def index_name
          @index.core_name
        end
      end
    end
  end
end
