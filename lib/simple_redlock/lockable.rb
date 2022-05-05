module SimpleRedlock
  module Lockable
    def exclusively(key, open_transaction: true, dont_reload: false, **options, &block)
      redis_lock.with_lock!(resource: exclusive_key(key), **options) do
        if open_transaction
          transaction do
            reload unless dont_reload
            yield
          end
        else
          reload unless dont_reload
          yield
        end
      end
    end

    def exclusive_key(key)
      "#{self.class.name}-#{id}-#{key}"
    end

    def redis_lock
      @redis_lock ||= SimpleRedlock::Locker.new
    end
  end
end
