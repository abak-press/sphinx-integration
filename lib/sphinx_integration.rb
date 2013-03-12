module SphinxIntegration
  autoload :SphinxHelper, 'sphinx_integration/sphinx_helper'
  autoload :Mysql, 'sphinx_integration/mysql'
  autoload :Transmitter, 'sphinx_integration/transmitter'
end

require 'sphinx_integration/version'
require 'sphinx_integration/extensions'
require 'sphinx_integration/railtie'