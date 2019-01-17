require 'sinatra/base'
require "active_support/core_ext/date_and_time/calculations"

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
        # Fetch base transactions. (Count: 100)
        transactions_arr = JSON.parse(fixture('transactions')).dig('transactions')

        # We need to update the dates on these transactions so they are
        # dynamic.
        #
        # Dates are set like this:
        # 1.year.ago > date >= Date.current
        #
        # Date format:
        # 'YYYY-MM-DD'
        #
        # Update all transactions except 5 with random date.
        # Update at least 5 with current date.
        #
        # Current date is needed to replicate 'new' fetched transactions.
        transactions_arr.drop(5).each_slice(5) do |txns|
          # Generate random date every 5 transactions
          date = rand_date

          txns.each do |txn|
            txn['date'] = date.strftime('%Y-%m-%d')
          end
        end

        # Update 5 transactions with current date.
        transactions_arr[0..4].each do |txn|
          txn['date'] = Date.current.strftime('%Y-%m-%d')
        end

        transactions = transactions_arr.select do |txn|
          txn.dig('date') > start_date && txn.dig('date') <= end_date
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

    def rand_date(from=1.year.ago.to_date, to=Date.current)
      rand(from..to)
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
