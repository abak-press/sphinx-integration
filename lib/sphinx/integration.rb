module Sphinx
  module Integration
    autoload :Helper, 'sphinx/integration/helper'
    autoload :Mysql, 'sphinx/integration/mysql'
    autoload :Transmitter, 'sphinx/integration/transmitter'
    autoload :FastFacet, 'sphinx/integration/fast_facet'
  end
end

require 'sphinx/integration/version'
require 'sphinx/integration/extensions'
require 'sphinx/integration/railtie'