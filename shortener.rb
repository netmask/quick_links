require 'sinatra'
require 'json'
require 'redis'
require 'awesome_print'

$redis = Redis.new(:path => "/tmp/redis.sock")

class Shortener

  ENCODING_BASE = 36
  COUNTER_KEY = 'counter'

  attr_accessor :redis

  def initialize(redis)
    self.redis = redis
  end

  def create(url)
    key = nil
    if valid_url? url
      if self.redis.exists(url)
        key = self.redis.get url
      else
        key = next_value
        self.redis.set url, key # Key pair ;)
        self.redis.set key, url
      end
    end
    key
  end

  def restore(key)
    self.redis.get key
  end

  def next_value
    (@redis.incr(COUNTER_KEY)).to_s(ENCODING_BASE)
  end

  def valid_url?(url)
    url =~ /\A#{URI::regexp(%w(http https))}\z/
  end
end


class ShortenerApplication < Sinatra::Application

  set :public_folder, 'public'

  get '/short/:id' do
    @shortener = Shortener.new($redis)

    cache_control :public
    redirect_url = @shortener.restore(params['id'])
    redirect (redirect_url ? redirect_url : 'https://ql.lc/' ), 301
  end

  post '/short' do
    content_type :json
    @shortener = Shortener.new($redis)

    request_body = JSON.parse(request.body.read)
    JSON.generate(short_code: @shortener.create(request_body['url']))
  end
end
