# coding: utf-8
module Sphinx::Integration::Extensions::PostgreSQLAdapter
  extend ActiveSupport::Concern

  included do
    alias_method_chain :crc, :blank_to_null
    alias_method_chain :time_difference, :time_zone_utc
  end

  def crc_with_blank_to_null(clause, blank_to_null = false)
    crc_without_blank_to_null(clause, true)
  end

  def time_difference_with_time_zone_utc(diff)
    time_difference_without_time_zone_utc(diff).gsub("current_timestamp", "current_timestamp AT TIME ZONE 'UTC'")
  end

end