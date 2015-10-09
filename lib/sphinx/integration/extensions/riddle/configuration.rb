# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    module Configuration
      extend ActiveSupport::Concern

      included do
        alias_method_chain :render, :integration
      end

      def render_with_integration
        searchd = @searchd

        listen_ip = "0.0.0.0"
        searchd.listen = [
          "#{listen_ip}:#{searchd.port}",
          "#{listen_ip}:#{searchd.mysql41.is_a?(TrueClass) ? '9306' :  searchd.mysql41}:mysql41",
        ]

        (
          [@indexer.render, searchd.render].compact +
          @sources.collect { |source| source.render } +
          @indices.collect { |index| index.render }
        ).join("\n")
      end
    end
  end
end