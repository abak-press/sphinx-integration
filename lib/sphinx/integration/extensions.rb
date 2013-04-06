module Sphinx::Integration::Extensions
  autoload :ActiveRecord, 'sphinx/integration/extensions/active_record'
  autoload :Attribute, 'sphinx/integration/extensions/attribute'
  autoload :BundledSearch, 'sphinx/integration/extensions/bundled_search'
  autoload :FastFacet, 'sphinx/integration/extensions/fast_facet'
  autoload :Index, 'sphinx/integration/extensions/index'
  autoload :PostgreSQLAdapter, 'sphinx/integration/extensions/postgresql_adapter'
  autoload :Property, 'sphinx/integration/extensions/property'
  autoload :Search, 'sphinx/integration/extensions/search'
  autoload :Source, 'sphinx/integration/extensions/source'
  autoload :ThinkingSphinx, 'sphinx/integration/extensions/thinking_sphinx'
  autoload :Configuration, 'sphinx/integration/extensions/configuration'
end