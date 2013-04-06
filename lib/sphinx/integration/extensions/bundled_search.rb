# coding: utf-8
module Sphinx::Integration::Extensions::BundledSearch
  extend ActiveSupport::Concern

  included do
    alias_method_chain :searches, :count_check
  end

  def searches_with_count_check
    searches_without_count_check if @searches.present?
  end
end