require 'spec_helper'

RSpec.describe SimpleRedisLock::RedisLock do
  let(:redis_double) { double('Redis') }
  let(:redis_lock) { described_class.new(retry_count: retry_count) }
  let(:retry_count) { 20 }
  before { allow_any_instance_of(described_class).to receive(:redis).and_return(redis_double) }

  describe '#lock_resource' do
    let(:key) { 'key' }
    let(:value) { 'value' }
    let(:ttl) { 2.seconds }
    subject(:locked) { redis_lock.lock_resource(key, value, ttl) }

    context 'when the lock is available' do
      before { allow(redis_double).to receive_messages(set: true) }

      it 'acquires the lock' do
        expect(locked).to be true
      end
    end

    context 'when the lock is unavailable' do
      it 'tries to acquire the lock based on the retry count' do
        expect(redis_double).to receive(:set).exactly(retry_count).times
        expect(locked).to be false
      end
    end

    context 'when the lock is available during retry' do
      it 'tries to acquire the lock and succeeds' do
        responses = [false] * 10 << true
        allow(redis_double).to receive(:set).and_return(*responses)
        expect(locked).to be true
      end
    end
  end

  describe '#with_lock' do
    let(:key) { 'key' }
    let(:model) { double('model', foo: 'some name') }

    subject(:with_lock) do
      redis_lock.with_lock(resource: key) do |locked|
        model.foo if locked
      end
    end

    context 'when the lock is available' do
      before { allow(redis_double).to receive_messages(set: true) }

      it 'yields the inner block' do
        allow(redis_double).to receive_messages(eval: 1)
        expect(model).to receive(:foo)
        with_lock
      end

      it 'unlocks the lock after completion' do
        expect(redis_double).to receive_messages(eval: 0)
        with_lock
      end

      it 'unlocks the lock even if the block errors' do
        expect(redis_double).to receive_messages(eval: 0)
        allow(model).to receive(:foo).and_throw(:explosions)

        catch :explosions do
          with_lock
        end
      end
    end

    context 'when the lock is unavailable' do
      before { allow(redis_double).to receive_messages(set: false) }

      it 'unlocks the lock' do
        expect(redis_double).to receive_messages(eval: 1)
        with_lock
      end

      it 'does not yield the inner block' do
        allow(redis_double).to receive_messages(eval: 1)
        expect(model).not_to receive(:foo)
        with_lock
      end
    end
  end

  describe '#with_lock!' do
    let(:key) { 'key' }
    let(:return_value) { 'some name' }
    let(:model) { double('model', foo: return_value) }

    subject(:with_lock!) do
      redis_lock.with_lock!(resource: key) do
        model.foo
      end
    end

    context 'when the lock is available' do
      before { allow(redis_double).to receive_messages(set: true, eval: 1) }

      it 'yields the inner block and returns its value' do
        allow(redis_double).to receive_messages(eval: 1)
        expect(with_lock!).to eq return_value
      end
    end

    context 'when the lock is unavailable' do
      before { allow(redis_double).to receive_messages(set: false, eval: 0) }

      it 'throws an exception' do
        allow(redis_double).to receive_messages(eval: 1)
        expect { with_lock! }.to raise_exception LockError
      end
    end
  end
end
