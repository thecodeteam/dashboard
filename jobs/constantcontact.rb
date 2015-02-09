#!/usr/bin/env ruby
require 'net/http'
require 'openssl'
require 'json'

# Created by Jonas Rosland, https://github.com/virtualswede, https://twitter.com/virtualswede
# Template used from https://github.com/foobugs/foobugs-dashboard/blob/master/jobs/github_user_repos.rb

# This job can track metrics of a ConstantContact email distribution list
# by using the public api of ConstantContact.
#
# This job should use the `List` widget

# Config
# ------
# If you only want to track a single distribution list, make sure you have added
# the CONSTANT_CONTACT_EMAIL_LIST variable to .env and look below for the config
# line you need to to change
cc_api_key = ENV['CONSTANT_CONTACT_API_KEY']
cc_email_list = ENV['CONSTANT_CONTACT_EMAIL_LIST']
cc_access_token = ENV['CONSTANT_CONTACT_ACCESS_TOKEN']
cc_host = ENV['CONSTANT_CONTACT_HOST'] || 'api.constantcontact.com'
# number of distribution lists to display in the list
max_length = 7
# order the list by the numbers
ordered = true

SCHEDULER.every '60m', :first_in => 0 do |job|
  http = Net::HTTP.new(cc_host, 443)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE # disable ssl certificate check
  # If you only want to track one distribution list uncomment the line below
  req = Net::HTTP::Get.new("https://#{cc_host}/v2/lists/#{cc_email_list}?api_key=#{cc_api_key}", initheader = {'Content-Type' =>'application/json', 'Authorization' => "Bearer #{cc_access_token}"})
  # If you want to track all your distribution lists uncomment the line below
  #req = Net::HTTP::Get.new("https://#{cc_host}/v2/lists?api_key=#{cc_api_key}", initheader = {'Content-Type' =>'application/json', 'Authorization' => "Bearer #{cc_access_token}"})
  response = http.start {|http| http.request(req) }
  data = JSON.parse(response.body, :symbolize_names => true)
  if response.code != "200"
    puts "ConstantContact api error (status-code: #{response.code})\n#{response.body}"
  else
    constant_contact_lists = Array.new
    # Added the classes below to be able to handle single or multiple results
    class Object; def ensure_array; [self] end end
    class Array; def ensure_array; to_a end end
    class NilClass; def ensure_array; to_a end end
    data.ensure_array.each do |items|
      constant_contact_lists.push({
        label: items[:name],
        value: items[:contact_count]
      })
    end

    if ordered
      constant_contact_lists = constant_contact_lists.sort_by { |obj| -obj[:value] }
    end

    send_event('constant_contact_lists', { items: constant_contact_lists.slice(0, max_length) })
    Keen.publish_batch(:constantcontact => constant_contact_lists.slice(0, max_length))
  end # if

end # SCHEDULER
