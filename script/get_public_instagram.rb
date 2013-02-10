require 'httpparty'

Dir.glob('./lib/*.rb') do |model|
  require model
end

INSTAGRAM_API_BASE = "https://api.instagram.com/v1"

def instagram_url(tag)
  "#{SINGLY_API_BASE}/proxy/instagram/tags/#{tag}/media/recent"
end

if session[:access_token]
  params = {:query=> {:access_token=> session[:access_token]}}.inspect
  puts params.inspect
  @tag = "HearstFashionHack"
  # puts instagram_url(@tag)
  @grams = HTTParty.get(instagram_url(@tag), {:query=> {:access_token=> session[:access_token]}})
  puts @grams.inspect
else
  redirect "/singly"
end

tp = TrendProcessor.new(grams.data, :instagram)
tp.process