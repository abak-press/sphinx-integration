# coding: utf-8
module ThinkingSphinx
  def self.indexing_mode=(mode)
    @indexing_mode = mode
  end

  def self.indexing?
    @indexing_mode
  end

  # sphinx.yml can define section with indexes which not needed
  #
  # Example:
  #   sphinx.yml:
  #     development:
  #       #...
  #       exclude: ['apress/product_denormalization/traits/extensions/models/product/sphinx_index']
  #
  #   module SphinxIndex
  #     def self.included(model)
  #       return if ThinkingSphinx.skip_index?(self)
  #
  #       #...
  #     end
  #   end
  #
  # Returns Boolean
  def self.skip_index?(klass)
    ThinkingSphinx::Configuration.instance.exclude.include?(klass.to_s.underscore)
  end
end

ThinkingSphinx.indexing_mode = false
