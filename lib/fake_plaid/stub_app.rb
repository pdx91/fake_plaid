require 'sinatra/base'

module FakePlaid
  class StubApp < Sinatra::Base
    # Plaid::InvalidRequestError = Class.new(StandardError)

    # Create an Item
    post '/link/item/create' do
      if sandbox_credentials_valid?
        json_response 200, fixture('create_item')
      end
    end

    post '/item/public_token/exchange' do
      json_response 200, fixture('exchange_token_response')
    end

    post '/transactions/get' do
      transactions = derive_transactions_from_params

      json_response 200, transactions
    end

    private

    def sandbox_credentials_valid?
      params.dig('credentials', 'username') == 'user_good' &&
        params.dig('credentials', 'password') == 'pass_good'
    end

    def json_response(response_code, response_body)
      content_type :json
      status response_code
      response_body
    end

    def fixture(file_name)
      file_path = File.join(FakePlaid.fixture_path, "#{file_name}.json")
      File.open(file_path, 'rb').read
    end

    # Monkey-paching `params` method.
    #
    # Requests from Plaid come in but the `params` are not populated.
    def _params
      return params if params.present?

      @_params ||= JSON.parse(request.body.read)
    end

    def derive_transactions_from_params
      if valid_transaction_params?
        transactions_json = JSON.parse(fixture('transactions')).dig('transactions')

        transactions = transactions_json.select do |txn|
          txn.dig('date') > start_date && txn.dig('date') < end_date
        end

        JSON.generate(
          'transactions' =>
          if transaction_count && transaction_count > 0
            transactions[0..(transaction_count - 1)]
          else
            transactions
          end
        )
      end
    end

    def valid_transaction_params?
      _params.dig('access_token') &&
        _params.dig('secret') &&
        _params.dig('client_id') &&
        _params.dig('start_date') &&
        _params.dig('end_date')
    end

    def start_date
      _params.dig('start_date')
    end

    def end_date
      _params.dig('end_date')
    end

    def transaction_count
      _params.dig('options', 'count')
    end
  end
end
