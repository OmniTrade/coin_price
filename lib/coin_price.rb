require 'bigdecimal/util'
require 'httparty'
require 'redis'

require_relative 'coin_price/version'
require_relative 'coin_price/config'
require_relative 'coin_price/errors'

require_relative 'coin_price/cache'

require_relative 'coin_price/fetch'
require_relative 'coin_price/source'
require_relative 'coin_price/methods'

# Require price Source modules here.
require_relative 'coin_price/coin_market_cap'
require_relative 'coin_price/coinpaprika'
require_relative 'coin_price/ptax'
require_relative 'coin_price/omnitrade'

# Require AVAILABLE_SOURCES constant.
require_relative 'coin_price/available_sources'

require_relative 'coin_price/refresher'
