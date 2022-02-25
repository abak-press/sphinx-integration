require 'spec_helper'

describe ThinkingSphinx::Index do
  let(:index) do
    ThinkingSphinx::Index::Builder.generate(ModelWithDisk, nil) do
      indexes 'content', :as => :content
      has 'region_id', :type => :integer, :as => :region_id
      set_property :rt => true
    end
  end

  describe '#to_riddle_with_merged' do
    let(:result) { index.to_riddle(0) }

    it 'generate core index' do
      expect(result.select { |x| x.is_a?(Riddle::Configuration::Index) }.size).to eq 1
    end

    it 'generate rt index' do
      expect(result.select { |x| x.is_a?(Riddle::Configuration::RealtimeIndex) }.size).to eq 2
    end

    it 'generate distributed index' do
      expect(result.select { |x| x.is_a?(Riddle::Configuration::DistributedIndex) }.size).to eq 1
    end
  end

  describe '#all_indexes_names' do
    it 'returns valid names' do
      expect(index.all_index_names).to(
        eq %w(model_with_disk model_with_disk_core model_with_disk_rt0 model_with_disk_rt1)
      )
    end
  end

  describe '#to_riddle_for_rt' do
    subject(:rt) { index.to_riddle_for_rt(0) }

    it do
      expect(rt.name).to eq 'model_with_disk_rt0'
      expect(rt.rt_field.size).to eq 1
      expect(rt.rt_attr_uint).to match_array([:sphinx_internal_id, :sphinx_deleted, :class_crc, :region_id])
    end
  end

  describe '#to_riddle_for_core' do
    let(:core_index) { index.send(:to_riddle_for_core, 1) }

    before { index.local_options[:index_sp] = 1 }

    it { expect(core_index.index_sp).to eq 1 }
  end

  describe '#all_names' do
    it 'returns only distributed index name' do
      expect(index.all_names).to match_array([index.name])
    end
  end

  describe '#rt_name' do
    context 'when partition is nil' do
      it 'returns current name' do
        expect(index.recent_rt).to receive(:current).and_return(0)
        expect(index.rt_name).to eq 'model_with_disk_rt0'
      end
    end

    context 'when partition is not nil' do
      it 'returns needed name' do
        expect(index.rt_name(1)).to eq 'model_with_disk_rt1'
      end
    end
  end

  describe '#switch_rt' do
    it 'flips current partition' do
      expect(index.rt_name).to eq 'model_with_disk_rt0'

      index.switch_rt

      expect(index.rt_name).to eq 'model_with_disk_rt1'
    end
  end

  describe '#truncate_prev_rt' do
    it do
      expect(index.rt_name).to eq 'model_with_disk_rt0'
      expect(::ThinkingSphinx::Configuration.instance.mysql_client).
        not_to receive(:write).with('TRUNCATE RTINDEX model_with_disk_rt1')

      expect(::ThinkingSphinx::Configuration.instance.mysql_vip_client).
        to receive(:write).with('TRUNCATE RTINDEX model_with_disk_rt1')

      index.truncate_prev_rt
    end
  end
end
