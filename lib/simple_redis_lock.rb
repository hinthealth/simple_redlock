# frozen_string_literal: true

LockError = Class.new(StandardError)

require 'active_support/core_ext/numeric/time'
require_relative 'memory_extension'
require_relative 'simple_redis_lock/locker'
require_relative 'simple_redis_lock/lockable'

module SimpleRedisLock
end
