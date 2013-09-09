# coding: utf-8
require 'spec_helper'

describe Sphinx::Integration::ConditionBuilder do
  it { described_class.build(company_id: 1).should eq "'company_id = 1'" }
  it { described_class.build(id: [1, 2, 3]).should eq "'id in (1, 2, 3)'" }
  it { described_class.build(photo_class: 'Photo').should eq "photo_class = 'Photo'" }
  it { described_class.build(photo_class: 'Photo', id: Set.new([1, 2, 3, 4, 'Bye Bye Bitch Bye Bye'])).should eq "photo_class = 'Photo' AND id in (1, 2, 3, 4, 'Bye Bye Bitch Bye Bye')" }
  it { described_class.build(a: [124, 12, 151], b: 'lskdjfsd', c: :c, d: 61, e: Set.new(['1', '2', '3', '4', '5', '6'])).should eq "a in (124, 12, 151) AND b = 'lskdjfsd' AND c = 'c' AND d = 61 AND e in ('1', '2', '3', '4', '5', '6')" }
end
