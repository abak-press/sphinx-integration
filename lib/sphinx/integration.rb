module Sphinx
  module Integration
    autoload :SphinxHelper, 'sphinx/integration/sphinx_helper'
    autoload :Mysql, 'sphinx/integration/mysql'
    autoload :Transmitter, 'sphinx/integration/transmitter'
  end
end

require 'sphinx/integration/version'
require 'sphinx/integration/extensions'
require 'sphinx/integration/railtie'