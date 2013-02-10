require 'httparty'

Dir.glob('./lib/*.rb') do |model|
  require model
end

SINGLY_API_BASE = "https://api.singly.com"

 def instagram_url(tag)
    "#{SINGLY_API_BASE}/proxy/instagram/tags/#{tag}/media/recent"
  end

tag = "HearstFashionHack"
grams = HTTParty.get(instagram_url(@tag), {:query=> {:access_token=> "4e2686cf5540451fb872f80be1579647"}})

tp = TrendProcessor.new(grams.data, :instagram)
tp.process