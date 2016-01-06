require 'sinatra'
require 'rss'
require 'readability_parser'
require 'redis'

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
  rss = RSS::Parser.parse(params[:url])
  rss.items.each do |entry|
    begin
      content = @redis.get(entry.link)
      content ||= ReadabilityParser.parse(entry.link).content
      entry.description = "<![CDATA[ " + content + " ]]>"
      entry.content_encoded = "<![CDATA[ " + content + " ]]>"
      @redis.set(entry.link, content)
    rescue => ex
      logger.error entry.link
    rescue
    end
  end

  content_type 'application/rss+xml'
  rss.to_s
end
