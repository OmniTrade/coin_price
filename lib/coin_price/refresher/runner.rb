module CoinPrice
  module Refresher
    class Runner
      def initialize(bases, quotes, source_id)
        source = CoinPrice.find_source_class(source_id)
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

      def wait_seconds
        (Refresher.config.wait * multiplier).to_i
      end

      def multiplier(date = Time.now)
        if date.saturday? || date.sunday?
          Refresher.config.wait_weekend_multiplier
        else
          Refresher.config.wait_weekday_multiplier
        end
      end
    end
  end
end
