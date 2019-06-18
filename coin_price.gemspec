require File.join(__dir__, 'lib', 'coin_price', 'version')

Gem::Specification.new do |spec|
  spec.name     = 'coin_price'
  spec.version  = CoinPrice::VERSION
  spec.license  = 'MIT'
  spec.summary  = 'Fetch and cache cryptocurrency prices'
  spec.authors  = ['Elias Rodrigues']
  spec.homepage = 'https://github.com/elias19r/coin_price'
  spec.files    = Dir['README*', 'LICENSE*', '*.gemspec', 'lib/**/*']

  spec.required_ruby_version = '~> 2.0'

  spec.add_runtime_dependency 'bigdecimal', '~> 1.4'
  spec.add_runtime_dependency 'httparty', '~> 0.16'
  spec.add_runtime_dependency 'redis', '~> 4.1'

  spec.add_development_dependency 'fakeredis', '~> 0.7'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry', '~> 0.12'
end
