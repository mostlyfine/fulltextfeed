require 'bundler'
Bundler.require
require 'rss'

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

get '/' do
  rss = RSS::Parser.parse(params[:url]) rescue redirect(params[:url])
  rss.items.each do |entry|
    begin
      content = @redis.get(entry.link)
      content ||= ReadabilityParser.parse(entry.link).content
      entry.description = entry.content_encoded = "<![CDATA[ #{content} ]]>"
      @redis.setex(entry.link, 86400, content)
    rescue => ex
      logger.error entry.link
    end
  end

  content_type 'application/rss+xml'
  rss.to_s
end
