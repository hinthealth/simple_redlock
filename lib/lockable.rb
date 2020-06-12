module SimpleRedisLock
  module Lockable
    attr_accessor :redis_lock

    def exclusively(key, options = {}, &block)
      if defined?(transaction)
        transaction do
          exclusive_lock(key, options, &block)
        end
      else
        exclusive_lock(key, options = {}, &block)
      end
    end

    def exclusive_key(key)
      "#{self.class.name}-#{id}-#{key}"
    end

    def exclusive_lock(key, options = {})
      redis_lock.with_lock!(resource: exclusive_key(key), **options) do
        yield
      end
    end

    def redis_lock
      @redis_lock ||= SimpleRedisLock.new
    end
  end
end
