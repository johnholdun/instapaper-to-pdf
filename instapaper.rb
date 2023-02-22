require 'http'
require 'simple_oauth'

# I must have ripped this from some gem or something but I did it before
# realizing I might want to share this code.
# TODO: Credit the author of this and/or refactor it into oblivion
class Instapaper
  attr_reader \
    :consumer_key,
    :consumer_secret,
    :oauth_token_secret,
    :oauth_token

  def initialize(consumer_key, consumer_secret)
    @consumer_key = consumer_key
    @consumer_secret = consumer_secret
  end

  def set_oauth(oauth_token, oauth_token_secret)
    @oauth_token = oauth_token
    @oauth_token_secret = oauth_token_secret
  end

  def authorize(username, password)
    response =
      request \
        :post,
        '/api/1.1/oauth/access_token',
        parse_json: false,
        form: {
          x_auth_username: username,
          x_auth_password: password,
          x_auth_mode: 'client_auth'
        }

    unless response.include?('=')
      raise "Authorization failed: #{response}"
    end

    values = response.split('&').map { |part| part.split('=') }.to_h
    @oauth_token = values['oauth_token']
    @oauth_token_secret = values['oauth_token_secret']
  end

  def bookmarks(limit = 25)
    request(:get, "/api/1.1/bookmarks/list?limit=#{limit}")
  end

  def get_text(bookmark_id)
    request(:get, "/api/1.1/bookmarks/get_text?bookmark_id=#{bookmark_id}", parse_json: false)
  end

  def request(request_method, path, form: {}, parse_json: true)
    uri = "https://www.instapaper.com#{path}"
    authorization =
      SimpleOAuth::Header.new(
        request_method,
        uri,
        form,
        {
          consumer_key: @consumer_key,
          consumer_secret: @consumer_secret,
          token: @oauth_token,
          token_secret: @oauth_token_secret
        })

    response = HTTP.headers({ authorization: authorization }).public_send(request_method, uri, form: form)
    return response.body.to_s unless parse_json
    JSON.parse(response, symbolize_names: true)
  end
end
