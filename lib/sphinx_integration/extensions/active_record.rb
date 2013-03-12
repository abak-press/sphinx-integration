# coding: utf-8
module SphinxIntegration::Extensions::ActiveRecord
  extend ActiveSupport::Concern

  included do
    include SphinxIntegration::Extensions::FastFacet

    delegate :create, :destroy, :update, :to => :transmitter, :prefix => true

    after_commit :transmitter_create, :on => :create
    after_commit :transmitter_update, :on => :update
    after_commit :transmitter_destroy, :on => :destroy
  end

  module InstanceMethods

    def transmitter
      @transmitter ||= SphinxIntegration::Transmitter.new(self)
    end

  end

  module ClassMethods

    def max_matches
      @ts_max_matches ||= ThinkingSphinx::Configuration.instance.configuration.searchd.max_matches || 5000
    end

    def define_secondary_index(args = {}, &block)
      args ||= {}
      define_index(args[:name], &block)

      self.sphinx_index_blocks << lambda {
        self.sphinx_indexes.last.merged_with_core = true
      }
    end

    def rt_index_names
      define_indexes
      sphinx_indexes.collect(&:rt_name)
    end

    def rt_indexed_by_sphinx?
      sphinx_indexes && sphinx_indexes.any? { |index| index.rt? }
    end

    def methods_for_mva_attributes
      @methods_for_mva_attributes ||= instance_methods.select{ |m| m.to_s =~ /^mva_sphinx_attributes_for_/ }
    end

    def add_sphinx_callbacks_and_extend(*args)
    end

  end
end