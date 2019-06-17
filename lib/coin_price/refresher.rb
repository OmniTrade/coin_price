module CoinPrice
  class Refresher
    attr_accessor :bases,
                  :quotes,
                  :source,
                  :wait, # seconds
                  :wait_weekday_multiplier,
                  :wait_weekend_multiplier

    def initialize(bases = ['BTC'], quotes = ['USD'], source = 'coinmarketcap')
      @bases = bases.map { |base|  base.to_s.upcase }
      @quotes = quotes.map { |quote| quote.to_s.upcase }
      @source = source.to_s.downcase

      @wait = CoinPrice.config.refresher_wait
      @wait_weekday_multiplier = CoinPrice.config.refresher_wait_weekday_multiplier
      @wait_weekend_multiplier = CoinPrice.config.refresher_wait_weekend_multiplier
    end

    def self.call(bases = ['BTC'], quotes = ['USD'], source = 'coinmarketcap')
      Refresher.new(bases, quotes, source).run
    end

    def run
      loop do
        begin
          puts 'Awake! Refreshing prices...'
          CoinPrice.listings(bases, quotes, source, from_cache: false)

          puts 'Done refreshing prices! Sleeping...'
          sleep wait_seconds
        rescue Interrupt => e
          puts "Stop refreshing prices."
          puts "#{e.class}: #{e.message}"
          break
        end
      end
    rescue StandardError => e
      puts "#{e.class}: #{e.message}"
      puts e.backtrace
    end

    def wait_seconds(date = Time.now)
      if date.saturday? || date.sunday?
        (wait * wait_weekend_multiplier).to_i
      else
        (wait * wait_weekday_multiplier).to_i
      end
    end
  end
end
