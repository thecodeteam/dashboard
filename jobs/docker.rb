#!/usr/bin/env ruby
require 'net/http'
require 'openssl'
require 'json'

# This job can track metrics of a public visible user or organisation’s repos
# by using the public api of github.
#
# Note that this API only allows 60 requests per hour.
#
# This Job should use the `List` widget

# Config
# ------
# example for tracking single user repositories
# github_username = 'users/ephigenia'
# example for tracking an organisations repositories
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
  #puts data[:results]
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
