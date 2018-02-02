require 'spec_helper'

describe Sphinx::Integration::LastIndexingTime do
  subject(:last_indexing_time) { described_class.new('index_name') }

  context 'when has no written time' do
    it { expect(last_indexing_time.read).to eq nil }
  end

  context 'when write without value given' do
    it 'writes current time from db' do
      current_db_time = ::ActiveRecord::Base.connection.select_value('select NOW()').to_time
      last_indexing_time.write
      expect(last_indexing_time.read.to_i).to eq current_db_time.to_i
    end
  end

  context 'when write with value given' do
    it 'writes value time' do
      last_indexing_time.write('2018-01-01')
      expect(last_indexing_time.read.to_i).to eq '2018-01-01'.to_time.to_i
    end
  end
end
