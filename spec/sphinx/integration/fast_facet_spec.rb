require 'spec_helper'

RSpec.describe Sphinx::Integration::FastFacet do
  describe '.fast_facet_ts_args' do
    it 'not overrides if defined key' do
      expect(ModelWithDisk.fast_facet_ts_args(:group_key, rank_mode: :sph04)).to include(
        rank_mode: :sph04,
        group: :group_key
      )

      expect(ModelWithDisk.fast_facet_ts_args(:group_key, group: :foo)).to include(
        rank_mode: :none,
        group: :foo
      )
    end
  end
end
