class Redis
  module Connection
    class Memory
      def eval(*args)
        case args[0]
        when SimpleRedisLock::RedisLock::UNLOCK_SCRIPT
          return 0 unless get(args[2]) == args[3]

          del(args[2])
        else
          fail Redis::CommandError, 'ERR unknown command "eval"'
        end
      end
    end
  end
end
