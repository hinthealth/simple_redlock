# frozen_string_literal: true

require 'securerandom'

LockError = Class.new(StandardError)

module SimpleRedlock
  class Locker
    DEFAULT_RETRY_COUNT = 25
    DEFAULT_TTL = 5 # in seconds
    UNLOCK_SCRIPT = <<~LUA
      if redis.call("get",KEYS[1]) == ARGV[1] then
        return redis.call("del",KEYS[1])
      else
        return 0
      end
    LUA

    # Locks a resource, and passes the locked status to the block.
    # The lock is unlocked after execution
    # Params:
    # +resource+:: the resource (or key) string to be locked.
    # +ttl+:: the time-to-live in seconds duration for the lock.
    # +block+:: block to be executed after successful lock acquisition.
    def with_lock(resource:, value: SecureRandom.hex, ttl: DEFAULT_TTL, retry_count: DEFAULT_RETRY_COUNT)
      locked = lock_resource(resource, value, ttl.to_i * 1000, retry_count)

      yield locked
      locked
    ensure
      unlock(resource, value)
    end

    # Locks a resource, executes the block only if the lock is acquired successfully.
    # The lock is unlocked after execution
    # Params:
    # +resource+:: the resource (or key) string to be locked.
    # +ttl+:: the time-to-live in seconds duration for the lock.
    # +block+:: block to be executed after successful lock acquisition.
    def with_lock!(resource:, value: SecureRandom.hex, ttl: DEFAULT_TTL, retry_count: DEFAULT_RETRY_COUNT)
      with_lock(resource: resource, value: value, ttl: ttl, retry_count: retry_count) do |locked|
        fail LockError, "Could not acquire lock for #{resource}" unless locked

        return yield
      end
    ensure
      unlock(resource, value)
    end

    # Locks a resource for a given time. Retries the lock retry_count number of times.
    # Params:
    # +resource+:: the key string to be locked.
    # +value+:: a unique string that checks lock ownership
    # +ttl+:: The time-to-live in miliseconds duration for the lock.
    def lock_resource(resource, value, ttl, retry_count)
      retry_count.times do |i|
        locked = lock(resource, value, ttl)
        return locked if locked

        # Random delay before retrying
        sleep(rand(ttl / retry_count).to_f / 1000)
      end

      false
    end

    def lock(key, value, ttl)
      redis_pool.with do |redis|
        redis.set(key, value, nx: true, px: ttl) == true
      end
    end

    def unlock(key, value)
      redis_pool.with do |redis|
        redis.eval(UNLOCK_SCRIPT, keys: [key], argv: [value])
      end
    rescue StandardError
    end

    def redis_pool
      SimpleRedlock.redis_pool
    end
  end
end
