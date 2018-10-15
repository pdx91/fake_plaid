require 'sinatra/base'

module FakePlaid
  class StubApp < Sinatra::Base
    # Create an Item
    post '/link/item/create' do
      if sandbox_credentials_valid?(params)
        json_response 200, fixture('create_item')
      end
    end

    private

    def sandbox_credentials_valid?(params)
      params.dig('credentials', 'username') == 'user_good' &&
        params.dig('credentials', 'password') == 'pass_good'
    end

    def fixture(file_name)
      file_path = File.join(FakePlaid.fixture_path, "#{file_name}.json")
      File.open(file_path, 'rb').read
    end
  end
end
