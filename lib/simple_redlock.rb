require 'active_support/core_ext/numeric/time'
require_relative 'simple_redlock/locker'
require_relative 'simple_redlock/lockable'

module SimpleRedlock
  mattr_accessor :redis_url

  def self.configure(&block)
    yield self
  end
end
