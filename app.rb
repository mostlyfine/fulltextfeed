require 'sinatra'
require 'rss'
require 'readability_parser'

configure do
  ReadabilityParser.api_token = ENV['API_TOKEN']
end

get '/' do
  rss = RSS::Parser.parse(params[:url])
  rss.items.each do |entry|
    begin
      article = ReadabilityParser.parse(entry.link)
      entry.description = "<![CDATA[ " + article.content + " ]]>"
      entry.content_encoded = "<![CDATA[ " + article.content + " ]]>"
    rescue
    end
  end

  content_type 'application/rss+xml'
  rss.to_s
end
