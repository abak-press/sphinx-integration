# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    module Configuration
      autoload :Searchd, 'sphinx/integration/extensions/riddle/configuration/searchd'
      autoload :DistributedIndex, 'sphinx/integration/extensions/riddle/configuration/distributed_index'

      extend ActiveSupport::Concern

      included do
        alias_method_chain :render, :integration
      end

      def render_with_integration(config_type, agent)
        if config_type == :slave
          searchd = @searchd.dup
          searchd.address = agent[:address]
          searchd.port = agent[:port]
          searchd.mysql41 = agent[:mysql41]
          searchd.listen_all_interfaces = agent.fetch(:listen_all_interfaces, true)
          searchd.remote_path = Pathname.new(agent[:remote_path]) if agent.key?(:remote_path)
        else
          searchd = @searchd
        end

        listen_ip = searchd.listen_all_interfaces ? '0.0.0.0' : searchd.address
        searchd.listen = [
          "#{listen_ip}:#{searchd.port}",
          "#{listen_ip}:#{searchd.mysql41.is_a?(TrueClass) ? '9306' :  searchd.mysql41}:mysql41",
        ]

        (
          [config_type == :master ? nil : @indexer.render, searchd.render].compact +
          @sources.collect { |source| source.render } +
          @indices.collect { |index| index.render }
        ).join("\n")
      end
    end
  end
end