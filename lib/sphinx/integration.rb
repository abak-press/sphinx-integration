require 'active_support/all'
require "dry/container"
require "dry/auto_inject"
require 'redis'
require 'redis-mutex'

module Sphinx
  module Integration
    extend SingleForwardable

    def_delegators 'Rails.application.config.sphinx_integration', :[], :[]=, :fetch

    autoload :Helper, 'sphinx/integration/helper'
    autoload :Mysql, 'sphinx/integration/mysql'
    autoload :Searchd, 'sphinx/integration/searchd'
    autoload :Decaying, 'sphinx/integration/decaying'
    autoload :Transmitter, 'sphinx/integration/transmitter'
    autoload :FastFacet, 'sphinx/integration/fast_facet'
    autoload :RecentRt, 'sphinx/integration/recent_rt'
    autoload :LastIndexingTime, 'sphinx/integration/last_indexing_time'
    autoload :Statements, 'sphinx/integration/statements'
    autoload :ServerPool, 'sphinx/integration/server_pool'
    autoload :Server, 'sphinx/integration/server'
    autoload :ServerStatus, 'sphinx/integration/server_status'

    Container = ::Dry::Container.new
    AutoInject = ::Dry::AutoInject(Container)
  end
end

require 'sphinx/integration/version'
require 'sphinx/integration/extensions'
require 'sphinx/integration/errors'
require 'sphinx/integration/railtie'
