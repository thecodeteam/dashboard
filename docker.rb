#!/usr/bin/env ruby
require 'net/http'
require 'openssl'
require 'json'

# Created by Jonas Rosland, https://github.com/virtualswede, https://twitter.com/virtualswede
# and Kendrick Coleman, https://github.com/kacole2, https://twitter.com/kendrickcoleman
# Template used from https://github.com/foobugs/foobugs-dashboard/blob/master/jobs/twitter_user.rb

# This job can track metrics of Docker Hub downloads and stars
# by scraping their public website since only stars and not downloads are
# available through the API
#
# This job should use the `List` widget

# Config
# ------
# Add the repository that you want to track here
docker_username = ENV['DOCKER_USER_REPOS_USERNAME'] || 'emccode'
# number of repositories to display in the list
max_length = 7
# order the list by the numbers
ordered = true

SCHEDULER.every '3m', :first_in => 0 do |job|
  http = Net::HTTP.new("registry.hub.docker.com", Net::HTTP.https_default_port())
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE # disable ssl certificate check
  response = http.request(Net::HTTP::Get.new("/v1/search?q=#{docker_username}"))
  data = JSON.parse(response.body, :symbolize_names => true)
  if response.code != "200"
    puts "docker api error (status-code: #{response.code})\n#{response.body}"
  else
    repos_stars = Array.new
    data[:results].each do |repo|
  #    puts repo[:name]
  #    puts repo[:star_count]
      repos_stars.push({
        label: repo[:name],
        value: repo[:star_count]
        })
      end
  #    puts repos_stars
      if ordered
        repos_stars = repos_stars.sort_by { |obj| -obj[:value] }
      end

      send_event('docker_user_repos_stars', { items: repos_stars.slice(0, max_length) })

    end # if

  end # SCHEDULER
