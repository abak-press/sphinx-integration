module Sphinx::Integration::FastFacet
  extend ActiveSupport::Concern

  module ClassMethods
    def fast_facet_ts_args(facet, ts_args = {})
      ts_args[:page] = 1

      ts_args[:group] ||= facet
      ts_args[:limit] ||= max_matches
      ts_args[:rank_mode] ||= :none
      ts_args[:match_mode] ||= ThinkingSphinx::DEFAULT_MATCH

      ts_args
    end

    def fast_facet_compute_result(sph_data, ts_args = {})
      return nil if sph_data.nil? || sph_data.results.nil? || sph_data.results[:matches].nil?

      result = {}
      result_2 = {}
      is_used_distinct = ts_args[:group_distinct].present?
      counter_field = is_used_distinct ? "@distinct" : "@count"

      sph_data.results[:matches].each do |match|
        result[match[:attributes]["@groupby"]] = match[:attributes][counter_field]
        result_2[match[:attributes]["@groupby"]] = match[:attributes]["@count"] if is_used_distinct
      end

      if is_used_distinct
        return result, result_2
      else
        result
      end
    end

    def fast_facet(query, facet, ts_args = {})
      new_ts_args = fast_facet_ts_args(facet, ts_args)
      ts_result = self.search_for_ids(query, new_ts_args)
      fast_facet_compute_result(ts_result, new_ts_args)
    end
  end
end
