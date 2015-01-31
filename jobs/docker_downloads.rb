#!/usr/bin/env ruby
require 'nokogiri'
require 'open-uri'
require 'keen'
require 'mechanize'
mechanize = Mechanize.new
docker_username = ENV['DOCKER_USERNAME'] || 'emccode'
page = mechanize.get('https://registry.hub.docker.com/repos/' + docker_username)
desc = []
downloads = []
max_length = 20
# Track public available information of a twitter user like follower, follower
# and tweet count by scraping the user profile page.

# Config
# ------
#docker_username = ENV['DOCKER_USERNAME'] || 'emccode'
Keen.project_id = '54cb20d459949a318f0dc355'
Keen.write_key = 'c268bcdf3ddab7ed848c39423841a31fa38f297dc68e8c784b874b097a40d8b8264e77446e9ff4c763f0ddb7986e5f2fa10f5827102f6881684d904b68469962e9f7780f00eab9b506f8920c213b5e4987fb125533eaaae556490aa5930dde3e73d0d8deb2ef15cfcc204b3a6abf71cc'

SCHEDULER.every '2m', :first_in => 0 do |job|
  page = mechanize.get('https://registry.hub.docker.com/repos/' + docker_username)
  repoArray = []
  page.search('.repo-list-item').each do |repo|
    repoTitle = repo.at('.repo-list-item-description h2').text.strip.gsub(/\s.+/, '')
    repoStars = repo.at('.repo-list-item-stats-left div').text.strip
    repoPulls = repo.at('.repo-list-item-stats-right div').text.strip
    repoArray.push({title: repoTitle, stars: repoStars.to_i, pulls: repoPulls.to_i})
  end
#  puts repoArray.slice(0, max_length)
#  puts repoArray[title]
#  puts repoArray

#  doc = Nokogiri::HTML(open("https://registry.hub.docker.com/repos/#{docker_username}"))
#  repo = doc.css('div.repo-list-item-description h2').each do |repos|
#    a =  repos.content.gsub(/\n/,',').gsub(/\s+/, '').split(',')
#    puts a
    #puts data
#    puts repos.content.gsub!(/\//, "")
#    pull = doc.css('div.repo-list-item-stats-right div').each do |pulls|
#    puts pulls.content
#  end
  #send_event('twitter_user_tweets', current: tweets)
  Keen.publish_batch(:docker => repoArray.slice(0, max_length))
end
