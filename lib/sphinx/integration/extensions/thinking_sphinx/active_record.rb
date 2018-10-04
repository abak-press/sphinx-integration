module Sphinx::Integration::Extensions::ThinkingSphinx::ActiveRecord
  extend ActiveSupport::Concern

  included do
    include Sphinx::Integration::FastFacet
  end

  module ClassMethods
    def transmitter
      @transmitter ||= Sphinx::Integration::Transmitter.new(self)
    end

    # Обновление отдельных атрибутов индекса по условию
    #
    # @see Sphinx::Integration::Transmitter#update_fields
    def update_sphinx_fields(*args, **options)
      define_indexes
      transmitter.update_fields(*args, **options)
    end

    def transmitter_update(batch)
      define_indexes

      transmitter.replace(batch)
    end
  end

  module TransmitterCallbacks
    extend ActiveSupport::Concern

    included do
      class_attribute :need_transmitter_update
      self.need_transmitter_update = true

      %i[create update].each do |action|
        after_commit(on: action, if: :need_transmitter_update) { transmitter_update }
      end

      after_commit(on: :destroy, if: :need_transmitter_update) { transmitter_destroy }
    end

    # обновление данных в сфинксе
    def transmitter_update
      self.class.transmitter.replace(self)
    end

    # удаление данных в сфинксе
    def transmitter_destroy
      self.class.transmitter.delete(self)
    end
  end

  module ClassMethods
    def max_matches
      ThinkingSphinx::Configuration.instance.configuration.searchd.max_matches || 5000
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
