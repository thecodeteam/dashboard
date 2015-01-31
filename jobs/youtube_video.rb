#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'keen'

# This job can track some metrics of a single youtube video by accessing the
# public available api of youtube.

# Config
# ------
# The youtube video id. Get this from the `v` parameter of the video’s url
youtube_video_id = ENV['YOUTUBE_VIDEO_ID'] || '2fAkED310N0'
Keen.project_id = '54cb20d459949a318f0dc355'
Keen.write_key = 'c268bcdf3ddab7ed848c39423841a31fa38f297dc68e8c784b874b097a40d8b8264e77446e9ff4c763f0ddb7986e5f2fa10f5827102f6881684d904b68469962e9f7780f00eab9b506f8920c213b5e4987fb125533eaaae556490aa5930dde3e73d0d8deb2ef15cfcc204b3a6abf71cc'

SCHEDULER.every '1m', :first_in => 0 do |job|
  http = Net::HTTP.new("gdata.youtube.com")
  response = http.request(Net::HTTP::Get.new("/feeds/api/videos?q=#{youtube_video_id}&v=2&alt=jsonc"))

  if response.code != "200"
    puts "youtube api error (status-code: #{response.code})\n#{response.body}"
  else
    videos = JSON.parse(response.body)['data']['items']

    if defined?(send_event)
      send_event('youtube_video_rating', current: videos[0]['ratingCount'])
      send_event('youtube_video_views', current: videos[0]['viewCount'])
      send_event('youtube_video_likes', current: videos[0]['likeCount'])
      send_event('youtube_video_comments', current: videos[0]['commentCount'])
      send_event('youtube_video_favorites', current: videos[0]['favoriteCount'])
      Keen.publish(:youtube_video_views, { :youtube_video_title => videos[0]['title'], :views => videos[0]['viewCount'] })
    else
      print videos[0]
    end
  end
end
