module CoinPrice
  module Refresher
    def self.call(bases = ['BTC'], quotes = ['USD'], source_id = CoinPrice.config.default_source)
      Runner.new(bases, quotes, source_id).run
    rescue StandardError => e
      puts "#{e.class}: #{e.message}"
      puts e.backtrace
    end

    class Runner
      def initialize(bases, quotes, source_id)
        source = CoinPrice.find_source_klass(source_id)
        @fetch = Fetch.new(bases, quotes, source, from_cache: false)
      end

      def run
        loop do
          puts 'Awake! Refreshing prices...'
          @fetch.values
          puts 'Done refreshing prices! Sleeping...'
          sleep wait_seconds
        rescue Interrupt => e
          puts 'Stop refreshing prices.'
          puts "#{e.class}: #{e.message}"
          break
        end
      end

      def wait_seconds(date = Time.now)
        if date.saturday? || date.sunday?
          (Refresher.config.wait * Refresher.config.wait_weekend_multiplier).to_i
        else
          (Refresher.config.wait * Refresher.config.wait_weekday_multiplier).to_i
        end
      end
    end
  end
end
