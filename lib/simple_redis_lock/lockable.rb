module SimpleRedisLock
  module Lockable
    def exclusively(key, options = {}, &block)
      transaction do
        redis_lock.with_lock!(resource: exclusive_key(key), **options) do
          yield
        end
      end
    end

    def exclusive_key(key)
      "#{self.class.name}-#{id}-#{key}"
    end

    def redis_lock
      @redis_lock ||= SimpleRedisLock::Locker.new
    end
  end
end
