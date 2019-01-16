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
      json_response 200, OpenStruct.new(transactions: fixture('transactions'))
    end

    private

    # Monkey-paching `params` method.
    #
    # Requests from Plaid come in but the `params` are not populated.
    def _params
      return params if params.present?

      @_params ||= JSON.parse(request.body.read)
    end

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
  end
end
