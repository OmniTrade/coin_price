CoinPrice
=========

CoinPrice fetch cryptocurrency latest prices from a Source API and cache results
into an in-memory hash or Redis. Price values are returned as BigDecimal and
timestamps as Integer Unix time.

__NOTE__: Coinpaprika is currently set as the default price Source, but there
are more sources available and CoinPrice is extensible by adding more Sources.

Install
-------

Build and install the gem locally:

```sh
gem build coin_price.gemspec
gem install coin_price-2.1.6.gem
```

Or install it from `rubygems.org` in your terminal:

```sh
gem install coin_price
```

Or via `Gemfile` in your project:

```Gemfile
source 'https://rubygems.org'

ruby '~> 2.5'

gem 'coin_price', '~> 2.1'
```

Require it in your Ruby code and `CoinPrice` module will be available:

```ruby
require 'coin_price'
```

Configure
---------

`CoinPrice` supports configuration with the `.configure` method.

```ruby
# For example, setting up to use Redis instead of local in-memory hash
CoinPrice.configure do |config|
  config.redis_enabled = true
  config.redis_url = 'redis://localhost:6379/0'
end
```

List of configuration values:

- `redis_enabled`: whether or not to use Redis to cache values (defaults to `false`)
- `redis_url`: Redis URL to cache values if enabled (defaults to `'redis://localhost:6379/0'`)
- `cache_key_prefix`: custom prefix to be used in hash or Redis keys (defaults to an empty string)
- `default_source`: default Source to fetch prices from when none is specified (defaults to `'coinpaprika'`)

(See `Config` class at `lib/coin_price/config.rb` for the up-to-date list of
configuration values)

__NOTE__: each Source may have its own configuration.

Usage
-----

### Get latest price

```ruby
# Latest BTC price quoted in USD from Coinpaprika
CoinPrice.value('BTC', 'USD', 'coinpaprika')
# => 0.1122965353095e5

# Coinpaprika is currently set as the default source

CoinPrice.value('BTC', 'USD')
# => 0.1122965353095e5

CoinPrice.value('LTC', 'BTC')
# => 0.1056364e-1
```

### Get many latest prices

```ruby
# List many latest prices at once
CoinPrice.values(['BTC', 'ETH' , 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'])
# => {
#   "BTC" => {
#     "USD" => 0.1122965353095e5,
#     "BTC" => 0.1e1,
#     "ETH" => 0.3849240929e2
#   },
#   "ETH" => {
#     "USD" => 0.29173683167e3,
#     "BTC" => 0.2600259e-1,
#     "ETH" => 0.1e1
#   },
#   "LTC" => {
#     "USD" => 0.11851911903e3,
#     "BTC" => 0.1056364e-1,
#     "ETH" => 0.40625353e0
#   },
#   "XRP" => {
#     "USD" => 0.3834478e0,
#     "BTC" => 0.3418e-4,
#     "ETH" => 0.131436e-2
#   }
# }
```

### Cache

All fetched prices are stored into an in-memory hash or Redis and can be used
instead of sending another request to the API:

```ruby
CoinPrice.value('BTC', 'USD', 'coinpaprika', from_cache: true)
# => 0.1122965353095e5

CoinPrice.timestamp('BTC', 'USD', 'coinpaprika')
# => 1562352560

CoinPrice.values(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'], 'coinpaprika', from_cache: true)
# Yields the same previous result for many latest prices

CoinPrice.timestamps(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'], 'coinpaprika')
# Yields the same hash structure as the previous result for many latest prices,
# but with the timestamps instead of price values

# Number of requests performed today
CoinPrice.requests_count('coinpaprika')
# => 4
```

### Keys and data

Cache keys of the in-memory hash or Redis follow the pattern:
- `coin-price:{source}:value:{base}:{quote}`
- `coin-price:{source}:timestamp:{base}:{quote}`

Example:

```ruby
CoinPrice.cache.get('coin-price:coinpaprika:value:BTC:USD')
# => "0.1122965353095e5"
CoinPrice.cache.get('coin-price:coinpaprika:timestamp:BTC:USD')
# => "1562352560"
```

Or in Redis:

```sh
$ redis-cli
> get coin-price:coinpaprika:value:BTC:USD
> "0.1122965353095e5"
> get coin-price:coinpaprika:timestamp:BTC:USD
> "1562352560"
```

There is also a requests count at:
- `coin-price:{source}:requests-count:{date}`

Example:

```ruby
CoinPrice.cache.get('coin-price:coinpaprika:requests-count:2019-07-05')
# => "4"
```

Or in Redis:

```sh
$ redis-cli
> get coin-price:coinpaprika:requests-count:2019-07-05
> "4"
```

Sources
-------

You can get the up-to-date list of sources with:

```ruby
CoinPrice.sources
# => {
#   "coinpaprika" => {
#     "name" => "Coinpaprika",
#     "website" => "https://coinpaprika.com/",
#     "notes" => "",
#     "class" => CoinPrice::Coinpaprika::Source
#   },
#   "coinmarketcap" => {
#     "name" => "CoinMarketCap",
#     "website" => "https://coinmarketcap.com/",
#     "notes" => "API Key is required",
#     "class" => CoinPrice::CoinMarketCap::Source
#   },
#   "ptax" => {
#     "name" => "PTAX",
#     "website" => "https://dadosabertos.bcb.gov.br/dataset/taxas-de-cambio-todos-os-boletins-diarios",
#     "notes" => "Brazil's Central Bank exchange rate for USD/BRL",
#     "class" => CoinPrice::PTAX::Source
#   }
# }
```

### Coinpaprika

- ID: `'coinpaprika'`
- Name: Coinpaprika
- Website: https://coinpaprika.com

`CoinPrice::Coinpaprika` supports configuration with the `.configure` method.

List of configuration values:

- `wait_between_requests`: delay in seconds between retrying a request (defaults to `1`)
- `max_request_retries`: number of retries before considering a request failed (defaults to `3`)

(See `Config` class at `lib/coin_price/coinpaprika/config.rb` for Coinpaprika configuration values)

### CoinMarketCap

- ID: `'coinmarketcap'`
- Name: CoinMarketCap
- Website: https://coinmarketcap.com
- Notes: API Key is required

`CoinPrice::CoinMarketCap` supports configuration with the `.configure` method.

Set your CoinMarketCap API Key:

```ruby
CoinPrice::CoinMarketCap.configure do |config|
  config.api_key = 'Your-CoinMarketCap-API-Key'
end
```

List of configuration values:

- `api_key`: your CoinMarketCap API Key (required; defaults to `nil`)
- `listings_limit`: number of results to return in the listings endpoint
  (defaults to `200` so it consumes only 1 call credit; max limit is `5000`;
  see https://coinmarketcap.com/api/documentation/v1/#operation/getV1CryptocurrencyListingsLatest)
- `wait_between_requests`: delay in seconds between calls to the listings endpoint (defaults to `1`)
- `max_request_retries`: number of retries before considering a request failed (defaults to `3`)

(See `Config` class at `lib/coin_price/coin_market_cap/config.rb` for CoinMarketCap configuration values)

### PTAX

- ID: `'ptax'`
- Name: PTAX
- Website: https://dadosabertos.bcb.gov.br/dataset/taxas-de-cambio-todos-os-boletins-diarios
- Notes: Brazil's Central Bank exchange rate for USD/BRL

`CoinPrice::PTAX` supports configuration with the `.configure` method.

List of configuration values:

- `wait_between_requests`: delay in seconds between retrying a request (defaults to `1`)
- `max_request_retries`: number of retries before considering a request failed (defaults to `3`)

(See `Config` class at `lib/coin_price/ptax/config.rb` for PTAX configuration values)

Refresher
---------

Refresher loops indefinitely and executes `CoinPrice.values` to populate the
in-memory hash or Redis with the specified coin prices and source.

```ruby
CoinPrice::Refresher.configure do |config|
  config.wait = 60 # seconds
end

CoinPrice::Refresher.call(['BTC', 'ETH', 'LTC', 'XRP'], ['USD', 'BTC', 'ETH'], 'coinpaprika')
# Awake! Refreshing prices...
# Done refreshing prices! Sleeping...
```

List of configuration values:

- `wait`: delay in seconds to wait until the next refresh (defaults to `120`)
- `wait_weekday_multiplier`: multiplier to apply to `wait` on weekdays (Monday to Friday) (defaults to `1`)
- `wait_weekend_multiplier`: multiplier to apply to `wait` on weekends (Saturday and Sunday) (defaults to `1`)

How to add a new Source
-----------------------

* Create a new module at `lib/coin_price/your_new_source` and implement a
`Source < CoinPrice::Source` class with the methods `id` and `values`:
  - `id` must return a unique string that identifies your Source in the code
  - `values` must receive the params `bases, quotes` which are arrays of
    currency symbols and return a hash with the price values for each base and
    quote pair
* Provide a test suite
* Add a group in the `SimpleCov` at `spec/spec_helper.rb`
* Register your new source class at `lib/coin_price/available_sources.rb` in the
  `AVAILABLE_SOURCES` constant
* Require it in `lib/coin_price.rb`

Optionally implement a `Config` class for you module and whichever class is
needed for it to work.

(See `CoinPrice::Coinpaprika` module for an example)

Tests
-----

Run tests with:

```
bundle exec rspec
```

Linter
------

Check your code style with:

```sh
gem install rubocop

rubocop
```
