#!/usr/bin/env ruby
require 'net/http'
require 'openssl'
require 'json'
require 'keen'

# This job can track some metrics of a single youtube video by accessing the
# public available api of youtube.

# Config
# ------
# The youtube video id. Get this from the `v` parameter of the video’s url
youtube_api_key =  ENV['YOUTUBE_API_KEY'] || 'AIzaSyC71wORUPewT2nSY3f8fJhG4pXSg8T4QMA'
youtube_playlist_id = ENV['YOUTUBE_PLAYLIST_ID'] || 'PLbssOJyyvHuWiBQAg9EFWH570timj2fxt'
#Keen.project_id = '54cb20d459949a318f0dc355'
#Keen.write_key = 'c268bcdf3ddab7ed848c39423841a31fa38f297dc68e8c784b874b097a40d8b8264e77446e9ff4c763f0ddb7986e5f2fa10f5827102f6881684d904b68469962e9f7780f00eab9b506f8920c213b5e4987fb125533eaaae556490aa5930dde3e73d0d8deb2ef15cfcc204b3a6abf71cc'
max_results = 50
# order the list by the numbers
ordered = true
max_length = 8

SCHEDULER.every '1m', :first_in => 0 do |job|
  http = Net::HTTP.new("www.googleapis.com", Net::HTTP.https_default_port())
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE # disable ssl certificate check
  response = http.request(Net::HTTP::Get.new("/youtube/v3/playlistItems?part=snippet&playlistId=#{youtube_playlist_id}&maxResults=#{max_results}&key=#{youtube_api_key}"))

  if response.code != "200"
    puts "youtube api error (status-code: #{response.code})\n#{response.body}"
  else
    data = JSON.parse(response.body, :symbolize_names => true)

    youtube_videos = Array.new

    data[:items].each do |video|
      youtube_videos.push({
        label: video[:snippet][:title],
        value: video[:snippet][:resourceId][:videoId]
      })
    end

    youtube_stats = Array.new

    for each in youtube_videos do
      http = Net::HTTP.new("www.googleapis.com", Net::HTTP.https_default_port())
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # disable ssl certificate check
      response = http.request(Net::HTTP::Get.new("/youtube/v3/videos?part=statistics&id=#{each[:value]}&key=#{youtube_api_key}"))
      data = JSON.parse(response.body, :symbolize_names => true)

      data[:items].each do |video|
        youtube_stats.push({
          label: each[:label],
          value: video[:statistics][:viewCount].to_i
        })
      end
    end

    if ordered
      youtube_stats = youtube_stats.sort_by { |obj| -obj[:value] }
    end

    if defined?(send_event)
      #send_event('youtube_video_rating', current: videos[0]['ratingCount'])
      send_event('youtube_video_views', { items: youtube_stats.slice(0, max_length) })
      #send_event('youtube_video_likes', current: videos[0]['likeCount'])
      #send_event('youtube_video_comments', current: videos[0]['commentCount'])
      #send_event('youtube_video_favorites', current: videos[0]['favoriteCount'])
      #Keen.publish(:youtube_video_views, { :youtube_video_title => videos[0]['title'], :views => videos[0]['viewCount'] })
    else
      puts youtube_stats
    end
  end
end
