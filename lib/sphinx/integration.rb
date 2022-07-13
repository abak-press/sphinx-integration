# frozen_string_literal: true

require 'active_support/all'
require 'redis'
require 'redis-mutex'
require 'resque-integration'
require 'string_tools'

module Sphinx
  RT_INDEXES_PROCESS_MUTEX_KEY = 'process_rt_indexes'
  RT_INDEXES_PROCESS_MUTEX_TTL = 3.hours
  module Integration
    extend SingleForwardable

    def_delegators 'Rails.application.config.sphinx_integration', :[], :[]=, :fetch

    autoload :Helper, 'sphinx/integration/helper'
    autoload :Mysql, 'sphinx/integration/mysql'
    autoload :Searchd, 'sphinx/integration/searchd'
    autoload :Decaying, 'sphinx/integration/decaying'
    autoload :Transmitter, 'sphinx/integration/transmitter'
    autoload :BufferedTransmitter, 'sphinx/integration/buffered_transmitter'
    autoload :FastFacet, 'sphinx/integration/fast_facet'
    autoload :RecentRt, 'sphinx/integration/recent_rt'
    autoload :LastIndexingTime, 'sphinx/integration/last_indexing_time'
    autoload :Statements, 'sphinx/integration/statements'
    autoload :ServerPool, 'sphinx/integration/server_pool'
    autoload :Server, 'sphinx/integration/server'
    autoload :ServerStatus, 'sphinx/integration/server_status'
    autoload :TransmitterJob, 'sphinx/integration/transmitter_job'
    autoload :ReplayerJob, 'sphinx/integration/replayer_job'
    autoload :OptimizeRtIndexJob, 'sphinx/integration/optimize_rt_index_job'
  end
end

require 'sphinx/integration/version'
require 'sphinx/integration/constants'
require 'sphinx/integration/extensions'
require 'sphinx/integration/errors'
require 'sphinx/integration/railtie'
