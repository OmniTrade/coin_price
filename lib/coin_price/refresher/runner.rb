module CoinPrice
  module Refresher
    class Runner
      def initialize(bases, quotes, source_id, options = {})
        @options = options

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
        (wait * multiplier).to_i
      end

      def multiplier(date = Time.now)
        if date.saturday? || date.sunday?
          wait_weekend_multiplier
        else
          wait_weekday_multiplier
        end
      end

      def wait
        return @options[:wait].to_i if @options[:wait]

        Refresher.config.wait
      end

      def wait_weekday_multiplier
        return @options[:wait_weekday_multiplier].to_f if @options[:wait_weekday_multiplier]

        Refresher.config.wait_weekday_multiplier
      end

      def wait_weekend_multiplier
        return @options[:wait_weekend_multiplier].to_f if @options[:wait_weekend_multiplier]

        Refresher.config.wait_weekend_multiplier
      end
    end
  end
end
