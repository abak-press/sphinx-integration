# coding: utf-8
require 'spec_helper'

describe ThinkingSphinx do
  let(:time) { Time.now.utc }

  before { ThinkingSphinx::LastIndexing.db.flushdb }
  before { ThinkingSphinx.stub(:db_current_time).and_return(time) }

  it do
    expect(ThinkingSphinx.last_indexing_finish_time).to be_nil
    expect(ThinkingSphinx.set_last_indexing_finish_time.to_i).to eq time.to_i
    expect(ThinkingSphinx.last_indexing_finish_time.to_i).to eq time.to_i
  end
end