# coding: utf-8
module ThinkingSphinx
  def self.indexing_mode=(mode)
    @indexing_mode = mode
  end

  def self.indexing?
    @indexing_mode
  end
end

ThinkingSphinx.indexing_mode = false