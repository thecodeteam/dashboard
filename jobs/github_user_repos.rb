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
github_username = ENV['GITHUB_USER_REPOS_USERNAME'] || 'orgs/emccode'
# number of repositories to display in the list
max_length = 7
# order the list by the numbers
ordered = true

SCHEDULER.every '1d', :first_in => 0 do |job|
  http = Net::HTTP.new("api.github.com", Net::HTTP.https_default_port())
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE # disable ssl certificate check
  response = http.request(Net::HTTP::Get.new("/#{github_username}/repos"))
  data = JSON.parse(response.body)

  if response.code != "200"
    puts "github api error (status-code: #{response.code})\n#{response.body}"
  else
    repos_forks = Array.new
    repos_watchers = Array.new
    repos_issues = Array.new
    data.each do |repo|
      repos_forks.push({
        label: repo['name'],
        value: repo['forks']
      })
      repos_watchers.push({
        label: repo['name'],
        value: repo['watchers']
      })
      repos_issues.push({
        label: repo['name'],
        value: repo['open_issues']
        })
    end

    if ordered
      repos_forks = repos_forks.sort_by { |obj| -obj[:value] }
      repos_watchers = repos_watchers.sort_by { |obj| -obj[:value] }
      repos_issues = repos_issues.sort_by { |obj| -obj[:value] }
    end

    send_event('github_user_repos_forks', { items: repos_forks.slice(0, max_length) })
    send_event('github_user_repos_watchers', { items: repos_watchers.slice(0, max_length) })
    send_event('github_user_repos_issues', { items: repos_issues.slice(0, max_length) })
    Keen.publish_batch(:github_forks => repos_forks.slice(0, max_length))
    Keen.publish_batch(:github_watchers => repos_watchers.slice(0, max_length))
    Keen.publish_batch(:github_issues => repos_issues.slice(0, max_length))
    #Keen.publish(:github_forks, { :repo => repos_forks[:label], :forks => repos_forks[:value].to_i })
  end # if

end # SCHEDULER
