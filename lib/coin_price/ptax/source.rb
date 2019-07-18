module CoinPrice
  module PTAX
    class Source < CoinPrice::Source
      def id
        @id ||= 'ptax'
      end

      def name
        @name ||= 'PTAX'
      end

      def website
        @website ||= 'https://dadosabertos.bcb.gov.br/dataset/taxas-de-cambio-todos-os-boletins-diarios'
      end

      def notes
        "Brazil's Central Bank exchange rate for USD/BRL"
      end

      def values(bases = ['USD'], quotes = ['BRL'])
        check_currency_codes(bases, quotes)

        response = API.request(API.url_cotacao_dolar_dia)
        incr_requests_count

        { 'USD' => { 'BRL' => find_value(response) } }
      end

      private

      def check_currency_codes(bases, quotes)
        raise CoinPrice::ValueNotFoundError, 'Only USD/BRL is supported' \
          unless bases.one? && quotes.one? && bases.first == 'USD' && quotes.first == 'BRL'
      end

      def find_value(data)
        data.dig('value')&.first&.dig('cotacaoVenda')&.to_d ||
          (raise CoinPrice::ValueNotFoundError, 'USD/BRL')
      end
    end
  end
end
