# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::ActiveRecord
  extend ActiveSupport::Concern

  included do
    include Sphinx::Integration::FastFacet
  end

  module TransmitterCallbacks
    extend ActiveSupport::Concern

    included do
      delegate :create, :update, :delete, :to => :transmitter, :prefix => true
      after_commit :transmitter_create, :on => :create
      after_commit :transmitter_update, :on => :update
      after_commit :transmitter_delete, :on => :destroy
    end

    def transmitter
      Sphinx::Integration::Transmitter.new(self)
    end

    module ClassMethods

      # Обновить атрибуты в сфинксе по условию
      #
      # fields - Hash
      # where  - String
      def update_sphinx_fields(fields, where)
        Sphinx::Integration::Transmitter.update_all_fields(self, fields, where)
      end

    end
  end

  module ClassMethods

    def max_matches
      @ts_max_matches ||= ThinkingSphinx::Configuration.instance.configuration.searchd.max_matches || 5000
    end

    def define_secondary_index(*args, &block)
      options = args.extract_options!
      name = args.first || options[:name]
      raise ArgumentError unless name
      define_index(name, &block)

      self.sphinx_index_blocks << -> { self.sphinx_indexes.last.merged_with_core = true }
    end

    def reset_indexes
      self.sphinx_index_blocks = []
      self.sphinx_indexes = []
      self.sphinx_facets = []
      self.defined_indexes = false
    end

    def rt_indexed_by_sphinx?
      sphinx_indexes && sphinx_indexes.any? { |index| index.rt? }
    end

    def add_sphinx_callbacks_and_extend(*args)
      include Sphinx::Integration::Extensions::ThinkingSphinx::ActiveRecord::TransmitterCallbacks
    end

  end
end