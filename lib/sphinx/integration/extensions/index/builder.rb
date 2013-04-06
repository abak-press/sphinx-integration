# coding: utf-8
module Sphinx::Integration::Extensions::Index::Builder

  def group_by!(*args)
    source.groupings = args
    set_property :force_group_by => true
  end

  def limit(value)
    set_property :sql_query_limit => value
  end

end