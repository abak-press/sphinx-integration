# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::ActiveRecord
  extend ActiveSupport::Concern

  included do
    include Sphinx::Integration::FastFacet
  end

  module TransmitterCallbacks
    extend ActiveSupport::Concern

    included do
      delegate :replace, :delete, :to => :transmitter, :prefix => true
      after_commit :transmitter_replace, :on => :create
      after_commit :transmitter_replace, :on => :update
      after_commit :transmitter_delete, :on => :destroy
    end

    def transmitter
      @transmitter ||= Sphinx::Integration::Transmitter.new(self)
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

      self.sphinx_index_blocks << lambda {
        self.sphinx_indexes.last.merged_with_core = true
      }
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

    def methods_for_mva_attributes
      @methods_for_mva_attributes ||= instance_methods.select{ |m| m.to_s =~ /^mva_sphinx_attributes_for_/ }
    end

    def add_sphinx_callbacks_and_extend(*args)
      include Sphinx::Integration::Extensions::ThinkingSphinx::ActiveRecord::TransmitterCallbacks
    end

  end
end