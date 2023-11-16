require 'connection_pool'
require 'redis'

require_relative 'simple_redlock/locker'
require_relative 'simple_redlock/lockable'

module SimpleRedlock
  def self.configure(&block)
    yield self
  end

  def self.redis_url=(redis_url)
    @redis_url = redis_url
  end

  def self.redis_url
    @redis_url
  end

  def self.redis_pool_timeout=(redis_pool_timeout)
    @redis_pool_timeout = redis_pool_timeout
  end

  def self.redis_pool_timeout
    @redis_pool_timeout ||= 1
  end

  def self.redis_pool_size=(redis_pool_size)
    @redis_pool_size = redis_pool_size
  end

  def self.redis_pool_size
    @redis_pool_size ||= 5
  end

  def self.redis_pool=(redis_pool)
    @redis_pool = redis_pool
  end

  def self.redis_pool
    @redis_pool ||= ConnectionPool.new(timeout: redis_pool_timeout, size: redis_pool_size) do
      Redis.new(url: redis_url)
    end
  end

  def self.testing!
    SimpleRedlock::Locker.class_eval do
      def lock(*args)
        true
      end

      def unlock(*args)
      end
    end
  end
end
