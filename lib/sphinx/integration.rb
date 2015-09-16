module Sphinx
  module Integration
    autoload :Helper, 'sphinx/integration/helper'
    autoload :Mysql, 'sphinx/integration/mysql'
    autoload :Searchd, 'sphinx/integration/searchd'
    autoload :Transmitter, 'sphinx/integration/transmitter'
    autoload :FastFacet, 'sphinx/integration/fast_facet'
    autoload :RecentRt, 'sphinx/integration/recent_rt'
    autoload :WasteRecords, 'sphinx/integration/waste_records'
  end
end

require 'sphinx/integration/version'
require 'sphinx/integration/extensions'
require 'sphinx/integration/errors'
require 'sphinx/integration/railtie'
