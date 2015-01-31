#!/usr/bin/env ruby
require 'nokogiri'
require 'open-uri'
require 'keen'

# Track public available information of a twitter user like follower, follower
# and tweet count by scraping the user profile page.

# Config
# ------
twitter_username = ENV['TWITTER_USERNAME'] || 'emccode'
Keen.project_id = '54cb20d459949a318f0dc355'
Keen.write_key = 'c268bcdf3ddab7ed848c39423841a31fa38f297dc68e8c784b874b097a40d8b8264e77446e9ff4c763f0ddb7986e5f2fa10f5827102f6881684d904b68469962e9f7780f00eab9b506f8920c213b5e4987fb125533eaaae556490aa5930dde3e73d0d8deb2ef15cfcc204b3a6abf71cc'

SCHEDULER.every '2m', :first_in => 0 do |job|
  doc = Nokogiri::HTML(open("https://twitter.com/#{twitter_username}"))
  tweets = doc.css('a[data-nav=tweets]').first.attributes['title'].value.split(' ').first
  followers = doc.css('a[data-nav=followers]').first.attributes['title'].value.split(' ').first
  following = doc.css('a[data-nav=following]').first.attributes['title'].value.split(' ').first

  send_event('twitter_user_tweets', current: tweets)
  send_event('twitter_user_followers', current: followers)
  send_event('twitter_user_following', current: following)
  Keen.publish(:twitter, { :handle => 'emccode', :tweets => tweets.to_i, :followers => followers.to_i })
end
