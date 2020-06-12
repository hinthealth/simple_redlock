# frozen_string_literal: true

LockError = Class.new(StandardError)

require 'active_support/core_ext/numeric/time'
require_relative 'simple_redis_lock/locker'
require_relative 'simple_redis_lock/lockable'
require_relative 'memory_extension'

module SimpleRedisLock
end
