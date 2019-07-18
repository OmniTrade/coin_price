module CoinPrice
  module PTAX
    class API
      ENDPOINT = 'https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1'
      ENDPOINT_COTACAO_DOLAR_DIA = "#{ENDPOINT}/odata/CotacaoDolarDia(dataCotacao=@dataCotacao)"

      class << self
        # Docs: https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/documentacao#CotacaoDolarDia
        def url_cotacao_dolar_dia
          date   = "@dataCotacao='#{Time.now.strftime('%m-%d-%Y')}'"
          top    = '$top=100'
          format = '$format=json'
          select = '$select=cotacaoVenda'

          "#{ENDPOINT_COTACAO_DOLAR_DIA}?#{date}&#{top}&#{format}&#{select}"
        end

        def request(url, options = {})
          retries = 0
          begin
            response = send_request(url, options)
            check_response(response)

            response[:body]
          rescue CoinPrice::RequestError
            raise
          rescue StandardError => e
            if (retries += 1) < PTAX.config.max_request_retries
              sleep PTAX.config.wait_between_requests
              retry
            end
            raise CoinPrice::RequestError, e.message
          end
        end

        private

        def send_request(url, options = {})
          response = HTTParty.get(url, options)
          {
            code: response.code,
            body: JSON.parse(response.body)
          }
        end

        def check_response(response)
          code = response[:code]

          raise CoinPrice::RequestError, code.to_s unless code == 200
        end
      end
    end
  end
end
