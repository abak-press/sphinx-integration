# coding: utf-8
require 'spec_helper'

describe Sphinx::Integration::RecentRt do
  let(:recent_rt) { described_class.new }

  describe '#switch' do
    it do
      expect(recent_rt.current).to eq 0
      recent_rt.switch
      expect(recent_rt.current).to eq 1
      recent_rt.switch
      expect(recent_rt.current).to eq 0
    end
  end
end
