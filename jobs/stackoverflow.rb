#!/usr/bin/env ruby
require 'net/http'
require 'openssl'
require 'json'
#require 'response'

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
cc_api_key = ENV['CONSTANT_CONTACT_API_KEY'] || '3tdrwcvw85xdjwqd7hh2kppd'
cc_email_list = ENV['CONSTANT_CONTACT_EMAIL_LIST'] || '2134166034'
cc_access_token = ENV['CONSTANT_CONTACT_ACCESS_TOKEN'] || 'ced2cce3-288b-4568-bcf1-f82a58c98ec5'
so_host = ENV['CONSTANT_CONTACT_HOST'] || 'api.stackexchange.com'
# number of repositories to display in the list
max_length = 20
# order the list by the numbers
ordered = true

SCHEDULER.every '60m', :first_in => 0 do |job|
  uri = URI("https://api.stackexchange.com/2.2/questions?order=desc&sort=activity&tagged=emc&site=stackoverflow")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE # disable ssl certificate check

  #http.set_debug_output $stderr
  response = http.get(uri.request_uri)

  data = JSON.parse(response.body, :symbolize_names => true)
  #puts data
  if response.code != "200"
    puts "docker api error (status-code: #{response.code})\n#{response.body}"
  else
    so_questions = Array.new
    #puts data
    data[:items].each do |repo|
      #p repo[:question_id]
      #puts repo[:tags].to_s
      so_questions.push({
        label: repo[:title],
        value: repo[:answer_count]
        })
      end
      #puts so_questions
      if ordered
        so_questions = so_questions.sort_by { |obj| -obj[:value] }
      end

      send_event('so_questions', { items: so_questions.slice(0, max_length) })

    end # if

  end # SCHEDULER
