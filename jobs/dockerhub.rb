#!/usr/bin/env ruby
require 'nokogiri'
require 'open-uri'
require 'keen'
require 'mechanize'

# Created by Jonas Rosland, https://github.com/virtualswede, https://twitter.com/virtualswede
# and Kendrick Coleman, https://github.com/kacole2, https://twitter.com/kendrickcoleman
# Template used from https://github.com/foobugs/foobugs-dashboard/blob/master/jobs/twitter_user.rb

# This job tracks metrics of Docker Hub downloads and stars by scraping
# the public website since only stars and not downloads are
# available through the API
#
# This job should use the `List` widget

# Config
# ------
docker_username = ENV['DOCKER_USERNAME'] || 'emccode'

mechanize = Mechanize.new
max_length = 7
ordered = true

SCHEDULER.every '60m', :first_in => 0 do |job|
  page = mechanize.get('https://registry.hub.docker.com/repos/' + docker_username)
  repoArray = []
  page.search('.repo-list-item').each do |repo|
    repoTitle = repo.at('.repo-list-item-description h2').text.strip.gsub(/\s.+/, '')
    repoStars = repo.at('.repo-list-item-stats-left div').text.strip
    repoPulls = repo.at('.repo-list-item-stats-right div').text.strip
    repoArray.push({title: repoTitle, stars: repoStars.to_i, pulls: repoPulls.to_i})
  end
  repos_stars = Array.new
  repos_pulls = Array.new
  repoArray.each do |repo|
    repos_stars.push({
      label: repo[:title],
      value: repo[:stars]
      })
    repos_pulls.push({
      label: repo[:title],
      value: repo[:pulls]
      })
    end
    if ordered
      repos_stars = repos_stars.sort_by { |obj| -obj[:value] }
      repos_pulls = repos_pulls.sort_by { |obj| -obj[:value] }
    end
  send_event('docker_hub_stars', { items: repos_stars.slice(0, max_length) })
  send_event('docker_hub_pulls', { items: repos_pulls.slice(0, max_length) })
  Keen.publish_batch(:docker => repoArray.slice(0, max_length))
end
