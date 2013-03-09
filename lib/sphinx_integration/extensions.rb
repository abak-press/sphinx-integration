module SphinxIntegration::Extensions
  autoload :ActiveRecord, 'sphinx_integration/extensions/active_record'
  autoload :Attribute, 'sphinx_integration/extensions/attribute'
  autoload :BundledSearch, 'sphinx_integration/extensions/bundled_search'
  autoload :FastFacet, 'sphinx_integration/extensions/fast_facet'
  autoload :Index, 'sphinx_integration/extensions/index'
  autoload :PostgreSQLAdapter, 'sphinx_integration/extensions/postgresql_adapter'
  autoload :Property, 'sphinx_integration/extensions/property'
  autoload :Search, 'sphinx_integration/extensions/search'
  autoload :Source, 'sphinx_integration/extensions/source'
  autoload :ThinkingSphinx, 'sphinx_integration/extensions/thinking_sphinx'
  autoload :Configuration, 'sphinx_integration/extensions/configuration'
end