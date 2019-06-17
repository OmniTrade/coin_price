module CoinPrice
  class Error < RuntimeError; end

  class UnknownSourceError < Error; end
  class RequestError < Error; end
  class CacheError < Error; end
  class ValueNotFoundError < Error; end
end
