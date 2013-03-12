# coding: utf-8
module SphinxIntegration::Extensions::Search
  extend ActiveSupport::Concern

  included do
    alias_method_chain :populate, :logging
  end

  def populate_with_logging
    unless @populated
      log "#{query}, #{options.dup.tap{|o| o[:classes] = o[:classes].map(&:name) if o[:classes] }.inspect}"
    end
    populate_without_logging
  end

end