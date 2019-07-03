require 'bigdecimal/util'
require 'httparty'
require 'redis'

require_relative 'coin_price/version'
require_relative 'coin_price/config'
require_relative 'coin_price/errors'

require_relative 'coin_price/redis'

require_relative 'coin_price/fetch'
require_relative 'coin_price/source'
require_relative 'coin_price/methods'

# Require price Sources modules.
require_relative 'coin_price/coin_market_cap'

# Require AVAILABLE_SOURCES constant.
require_relative 'coin_price/available_sources'

require_relative 'coin_price/refresher'
