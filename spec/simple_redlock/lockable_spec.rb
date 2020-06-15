require 'spec_helper'

class LockableObject
  include SimpleRedlock::Lockable

  attr_accessor :id

  def initialize(id)
    self.id = id
  end
end

RSpec.describe 'Lockable' do
  describe '#exclusive_key' do
    let(:id) { 1001 }
    subject { LockableObject.new(id).exclusive_key(:take_your_turn) }

    it { is_expected.to eq "#{LockableObject}-#{id}-take_your_turn" }
  end
end
