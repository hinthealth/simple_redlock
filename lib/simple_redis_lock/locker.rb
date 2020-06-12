# frozen_string_literal: true

LockError = Class.new(StandardError)

module SimpleRedisLock
  class Locker
    DEFAULT_RETRY_COUNT = 25
    DEFAULT_TTL = 5.seconds
    UNLOCK_SCRIPT = <<~LUA
      if redis.call("get",KEYS[1]) == ARGV[1] then
        return redis.call("del",KEYS[1])
      else
        return 0
      end
    LUA

    # Create a lock manager using Redis Set.
    # Params:
    # +options+:: Override the default value for `retry_count`
    #    * `retry_count`   how many times we try to lock a resource (default: 5)
    def initialize(options = {})
      @retry_count = options[:retry_count] || DEFAULT_RETRY_COUNT
      @redis = redis
    end

    # Locks a resource, and passes the locked status to the block.
    # The lock is unlocked after execution
    # Params:
    # +resource+:: the resource (or key) string to be locked.
    # +ttl+:: the time-to-live in duration for the lock.
    # +block+:: block to be executed after successful lock acquisition.
    def with_lock(resource:, value: SecureRandom.hex, ttl: DEFAULT_TTL)
      locked = lock_resource(resource, value, ttl.to_i * 1000)

      yield locked
      locked
    ensure
      unlock(resource, value)
    end

    # Locks a resource, executes the block only if the lock is acquired successfully.
    # The lock is unlocked after execution
    # Params:
    # +resource+:: the resource (or key) string to be locked.
    # +ttl+:: the time-to-live in duration for the lock.
    # +block+:: block to be executed after successful lock acquisition.
    def with_lock!(resource:, value: SecureRandom.hex, ttl: DEFAULT_TTL)
      with_lock(resource: resource, value: value, ttl: ttl) do |locked|
        fail LockError, "Could not acquire lock for #{resource}" unless locked

        return yield
      end
    ensure
      unlock(resource, value)
    end

    # Locks a resource for a given time. Retries the lock @retry_count number of times.
    # Params:
    # +resource+:: the key string to be locked.
    # +value+:: a unique string that checks lock ownership
    # +ttl+:: The time-to-live in duration for the lock.
    def lock_resource(resource, value, ttl)
      @retry_count.times do
        locked = lock(resource, value, ttl)
        return locked if locked

        # Random delay before retrying
        sleep(rand(ttl / @retry_count).to_f / 1000)
      end

      false
    end

    def redis
      Thread.current[:redis] ||= Redis.new(url: 'redis://localhost:6379')
    end

    def lock(key, value, ttl)
      @redis.set(key, value, nx: true, px: ttl) == true
    end

    def unlock(key, value)
      @redis.eval(UNLOCK_SCRIPT, keys: [key], argv: [value])
    rescue StandardError
    end
  end
end
