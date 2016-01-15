xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @rss.title
    xml.description @rss.description
    xml.link @rss.url

    @rss.entries.each do |entry|
      xml.item do
        xml.title entry.title
        xml.link entry.url
        xml.description do
          xml.cdata! entry.summary
        end
        xml.tag!('content:encoded') do
          xml.cdata! entry.content
        end
        xml.pubDate entry.published
        xml.guid entry.entry_id
      end
    end
  end
end
