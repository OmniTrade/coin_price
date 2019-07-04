module CoinPrice
  module Refresher
    def self.call(bases = ['BTC'], quotes = ['USD'], source_id = CoinPrice.config.default_source)
      Runner.new(bases, quotes, source_id).run
    rescue StandardError => e
      puts "#{e.class}: #{e.message}"
      puts e.backtrace
    end
  end
end
