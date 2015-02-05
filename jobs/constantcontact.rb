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
cc_api_key = ENV['CONSTANT_CONTACT_API_KEY']
#cc_email_list = ENV['CONSTANT_CONTACT_EMAIL_LIST'] || '2134166034'
cc_access_token = ENV['CONSTANT_CONTACT_ACCESS_TOKEN']
cc_host = ENV['CONSTANT_CONTACT_HOST'] || 'api.constantcontact.com'
# number of repositories to display in the list
max_length = 7
# order the list by the numbers
ordered = true

SCHEDULER.every '60m', :first_in => 0 do |job|
  #http = Net::HTTP.new("api.constantcontact.com", Net::HTTP.https_default_port())
  #http.use_ssl = true
  #uri = URI("https://api.constantcontact.com/v2/lists/#{cc_email_list}?api_key=#{cc_api_key}")

  http = Net::HTTP.new(cc_host, 443)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE # disable ssl certificate check
  #req = Net::HTTP::Get.new("https://#{cc_host}/v2/lists/#{cc_email_list}?api_key=#{cc_api_key}", initheader = {'Content-Type' =>'application/json', 'Authorization' => "Bearer #{cc_access_token}"})
  req = Net::HTTP::Get.new("https://#{cc_host}/v2/lists?api_key=#{cc_api_key}", initheader = {'Content-Type' =>'application/json', 'Authorization' => "Bearer #{cc_access_token}"})
  response = http.start {|http| http.request(req) }

  #return Response.new(response.code, response.message, response.body)
  #puts uri
#  req = Net::HTTP::Get.new(uri)
  #puts req
#  req['Authorization'] = "Bearer #{cc_access_token}"
  #puts req['Authorization']
  #http = Net::HTTP.new(uri.host, uri.port)
  #http.use_ssl = true

  #results = http.get(uri.request_uri)
  #response = http.request(Net::HTTP::Get.new("/v2/lists/#{cc_email_list}?api_key=#{cc_api_key}"))
  data = JSON.parse(response.body, :symbolize_names => true)
  if response.code != "200"
    puts "docker api error (status-code: #{response.code})\n#{response.body}"
  else
    constant_contact_lists = Array.new
    #puts data
    data.each do |repo|
      #puts repo[:contact_count]
      constant_contact_lists.push({
        label: repo[:name],
        value: repo[:contact_count]
        })
      end
      #puts constant_contact_lists
      if ordered
        constant_contact_lists = constant_contact_lists.sort_by { |obj| -obj[:value] }
      end

      send_event('constant_contact_lists', { items: constant_contact_lists.slice(0, max_length) })
      Keen.publish_batch(:constantcontact => constant_contact_lists.slice(0, max_length))
    end # if

  end # SCHEDULER
