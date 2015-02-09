#!/usr/bin/env ruby
require 'net/http'
require 'openssl'
require 'json'

# Created by Jonas Rosland, https://github.com/virtualswede, https://twitter.com/virtualswede
# Template used from https://github.com/foobugs/foobugs-dashboard/blob/master/jobs/github_user_repos.rb

# This job tracks questions with a specific tag on StackOverflow and
# the answer count on them by using the public StackOverflow API
#
# This job should use the `List` widget

# Config
# ------
so_host = ENV['STACKOVERFLOW_HOST'] || 'api.stackexchange.com'
so_tag = ENV['STACKOVERFLOW_TAG'] || 'emc'
# number of questions to display in the list
max_length = 20
# order the list by the numbers
ordered = true

SCHEDULER.every '60m', :first_in => 0 do |job|
  uri = URI("https://api.stackexchange.com/2.2/questions?order=desc&sort=activity&tagged=#{so_tag}&site=stackoverflow")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE # disable ssl certificate check
  response = http.get(uri.request_uri)

  data = JSON.parse(response.body, :symbolize_names => true)

  if response.code != "200"
    puts "stackoverflow api error (status-code: #{response.code})\n#{response.body}"
  else
    so_questions = Array.new

    data[:items].each do |question|
      so_questions.push({
        label: question[:title],
        value: question[:answer_count]
      })
    end

    if ordered
      so_questions = so_questions.sort_by { |obj| -obj[:value] }
    end

    send_event('so_questions', { items: so_questions.slice(0, max_length) })

  end # if

end # SCHEDULER
