module Sphinx
  module Integration
    module Mysql
      autoload :Client, 'sphinx/integration/mysql/client'
      autoload :ConnectionPool, 'sphinx/integration/mysql/connection_pool'
      autoload :Connection, 'sphinx/integration/mysql/connection'
    end
  end
end
