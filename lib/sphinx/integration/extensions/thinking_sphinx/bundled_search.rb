# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::BundledSearch
  extend ActiveSupport::Concern

  included do
    alias_method_chain :searches, :count_check
    alias_method_chain :populate, :integration
    alias_method_chain :search, :integration
    alias_method_chain :search_for_ids, :integration
  end

  def searches_with_count_check
    searches_without_count_check if @searches.present?
  end

  def search_with_integration(*args)
    ThinkingSphinx::Search.log args.inspect
    search_without_integration(*args)
  end

  def search_for_ids_with_integration(*args)
    ThinkingSphinx::Search.log args.inspect
    search_for_ids_without_integration(*args)
  end

  def populate_with_integration
    return if populated?

    @populated = true

    response = ThinkingSphinx::Search.log 'Bundled Query' do
      client.run
    end

    response.each_with_index do |results, index|
      searches[index].populate_from_queue results
    end
  end
end