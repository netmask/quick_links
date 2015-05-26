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

    if self.redis.exists(url)
      key = self.redis.get url
    else
      key = next_value
      sanitized_url = sanitize(url)

      self.redis.set sanitized_url, key # Key pair ;)
      self.redis.set key, sanitized_url
    end

    key
  end

  def sanitize(url) #need a more elegant way to do this
    url['http'] ? url : "http://#{url}"
  end

  def restore(key)
    self.redis.get key
  end

  def next_value
    (@redis.incr(COUNTER_KEY)).to_s(ENCODING_BASE)
  end
end


class ShortenerApplication < Sinatra::Application

  set :public_folder, 'public'

  get '/:id' do
    @shortener = Shortener.new($redis)

    cache_control :public
    redirect_url = @shortener.restore(params['id'])
    redirect (redirect_url ? redirect_url : 'https://ql.lc/' ), 301
  end

  post '/short' do
    @shortener = Shortener.new($redis)

    if params['url'].strip.empty?
      error 400 do
        { error: "the url can't be blank" }
      end
    end

    content_type :json
    JSON.generate({short_code: @shortener.create(params['url'])})
  end
end
