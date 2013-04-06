# coding: utf-8
module Sphinx::Integration::Extensions::Property
  extend ActiveSupport::Concern

  included do
    alias_method_chain :available?, :allways_true
    alias_method_chain :column_available?, :allways_true
  end

  def available_with_allways_true?
    true
  end

  def column_available_with_allways_true?(column)
    true
  end

end