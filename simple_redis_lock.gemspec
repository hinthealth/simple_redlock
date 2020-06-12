lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple_redis_lock/version'

Gem::Specification.new do |spec|
  spec.name          = 'simple-redis-lock'
  spec.version       = SimpleRedisLock::VERSION
  spec.authors       = ['Hint']
  spec.email         = ['maicol.bentancor@gmail.com']

  spec.summary               = 'Simple redis lock'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 2.4'

  spec.files         = Dir['lib/**/*.rb']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
