require 'bundler'
Bundler.require

before do
  @redis = if ENV['REDISTOGO_URL']
    uri = URI.parse(ENV['REDISTOGO_URL'])
    Redis.new(host: uri.host, port: uri.port, password: uri.password)
  else
    Redis.new(host: '127.0.0.1', port: 6379)
  end
end

configure do
  ReadabilityParser.api_token = ENV['API_TOKEN']
end

error do
  redirect(params[:url])
end

get '/' do
  feed_urls = Feedbag.find(params[:url])
  @rss = Feedjira::Feed.fetch_and_parse(feed_urls.first)

  @rss.entries.each do |entry|
    begin
      content = @redis.get(entry.url)
      content ||= ReadabilityParser.parse(entry.url).content
      entry.summary = entry.content = content
      @redis.setex(entry.url, 86400, content)
    rescue => ex
      logger.error entry.url
    end
  end

  builder :feed
end
