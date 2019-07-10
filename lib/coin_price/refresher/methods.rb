module CoinPrice
  module Refresher
    def self.call(bases = ['BTC'], quotes = ['USD'], source_id = CoinPrice.config.default_source, options = {})
      Runner.new(bases, quotes, source_id, options).run
    rescue StandardError => e
      puts "#{e.class}: #{e.message}"
      puts e.backtrace
    end
  end
end
