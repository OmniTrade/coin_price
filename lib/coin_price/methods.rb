module CoinPrice
  class << self
    # value is just a wrapper for values.
    def value(base = 'BTC', quote = 'USD', source_id = config.default_source, options = { from_cache: false })
      values([base], [quote], source_id, options)[base.to_s.upcase][quote.to_s.upcase]
    end

    # timestamp is just a wrapper for timestamps.
    def timestamp(base = 'BTC', quote = 'USD', source_id = config.default_source)
      timestamps([base], [quote], source_id)[base.to_s.upcase][quote.to_s.upcase]
    end

    def values(bases = ['BTC'], quotes = ['USD'], source_id = config.default_source, options = { from_cache: false })
      source = find_source_class(source_id)
      Fetch.new(bases, quotes, source, options).values
    end

    def timestamps(bases = ['BTC'], quotes = ['USD'], source_id = config.default_source)
      source = find_source_class(source_id)
      Fetch.new(bases, quotes, source).timestamps
    end

    def requests_count(source_id = config.default_source)
      source = find_source_class(source_id)
      source.new.requests_count
    end

    def find_source_class(id)
      sources.dig(id.to_s, 'class') || (raise UnknownSourceError, id)
    end

    def sources
      @sources ||= AVAILABLE_SOURCES.each_with_object({}) do |source_class, list|
        source = source_class.new
        list[source.id.to_s] = {
          'name' => source.name,
          'website' => source.website,
          'notes' => source.notes,
          'class' => source.class
        }
      end
    end

    def cache_key
      "#{config.cache_key_prefix}coin-price"
    end
  end
end
