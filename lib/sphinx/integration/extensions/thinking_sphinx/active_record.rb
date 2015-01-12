# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::ActiveRecord
  extend ActiveSupport::Concern

  included do
    include Sphinx::Integration::FastFacet
  end

  module TransmitterCallbacks
    extend ActiveSupport::Concern

    included do
      after_commit :transmitter_create, :on => :create
      after_commit :transmitter_update, :on => :update
      after_commit :transmitter_destroy, :on => :destroy

      class << self
        def transmitter
          @transmitter ||= Sphinx::Integration::Transmitter.new(self)
        end
      end
    end

    def transmitter_create
      self.class.transmitter.replace(self)
    end
    alias_method :transmitter_update, :transmitter_create

    def transmitter_destroy
      self.class.transmitter.delete(self)
    end

    module ClassMethods

      # Обновить атрибуты в сфинксе по условию
      #
      # fields - Hash
      # where  - Hash
      def update_sphinx_fields(fields, where)
        transmitter.update_fields(fields, where)
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

    # Индексы для конфига
    #
    # config_type - Symbol
    #
    # Returns Array
    def to_riddle(config_type)
      define_indexes
      sphinx_database_adapter.setup

      local_sphinx_indexes.collect { |index|
        index.to_riddle(sphinx_offset, config_type)
      }.flatten
    end

  end

  # Находится ли запись в сфинксе
  #
  # index_name - String (default: nil)
  #
  # Returns boolean
  def exists_in_sphinx?(index_name = nil)
    return false if new_record?
    !self.class.search_count(:index => index_name, :cut_off => 1, :with => {'@id' => sphinx_document_id}).zero?
  end
end
