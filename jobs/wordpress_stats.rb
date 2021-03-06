#!/usr/bin/env ruby
require 'net/http'
require 'openssl'
require 'json'
require 'keen'

# Created by Jonas Rosland, https://github.com/jonasrosland, https://twitter.com/jonasrosland
# Template used from https://github.com/foobugs/foobugs-dashboard/blob/master/jobs/github_user_repos.rb

# This job tracks stats for your Wordpress blog
#
# This job should use the `Numbers` and `List` widgets
# One for the total of the blog and one for a list of the most popular posts

# Config
# ------
wp_host = ENV['WORDPRESS_HOST'] || 'public-api.wordpress.com'
wp_site = ENV['WORDPRESS_SITE'] || 'blog.codedellemc.com'

# The following line is only needed if you're deploying to Cloud Foundry
wp_bearer = JSON.parse(ENV['VCAP_SERVICES'], :symbolize_names => true)[:'user-provided'][0][:credentials][:wordpress_api]

# If you're deploying Dashing locally you can uncomment the following line
#wp_bearer = ENV['WORDPRESS_BEARER'] || 'YOUR_TOKEN_HERE'

# number of posts to display in the list
max_length = 13

# order the list by the numbers
ordered = true
wp_period = 'year'
number_of_periods = 5

SCHEDULER.every '60m', :first_in => 0 do |job|
  http = Net::HTTP.new(wp_host, 443)
  all = Net::HTTP::Get.new("https://#{wp_host}/rest/v1.1/sites/#{wp_site}/stats/summary?period=#{wp_period}&num=#{number_of_periods}&pretty=true", initheader = {'Content-Type' =>'application/json', 'Authorization' => "Bearer #{wp_bearer}"})
  posts = Net::HTTP::Get.new("https://#{wp_host}/rest/v1.1/sites/#{wp_site}/stats/top-posts?&period=#{wp_period}&max=#{max_length}&num=#{number_of_periods}&pretty=true", initheader = {'Content-Type' =>'application/json', 'Authorization' => "Bearer #{wp_bearer}"})
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE # disable ssl certificate check
  response_all = http.start {|http| http.request(all) }
  response_posts = http.start {|http| http.request(posts) }

  data_all = JSON.parse(response_all.body, :symbolize_names => true)
  data_posts = JSON.parse(response_posts.body, :symbolize_names => true)
  if response_all.code != "200"
    puts "wordpress api error (status-code: #{response_all.code})\n#{response_all.body}"
  else

    posts_stats = Array.new
    # Fix for Wordpress' crappy JSON formatting
    first_day_of_year = data_posts[:days].flatten.first

    data_posts[:days][first_day_of_year][:postviews].each do |post|
      unless post[:id] == 0 || post[:id] == 5857 || post[:id] == 5751 || post[:id] == 5745 || post[:type] != "post"
        posts_stats.push({
          label: post[:title],
          value: post[:views]
        })
      end
    end

    if ordered
      posts_stats = posts_stats.sort_by { |obj| -obj[:value] }
    end

    send_event('wordpress_total_views', { current: data_all[:views] })
    send_event('wordpress_posts_views', { items: posts_stats.slice(0, max_length) })
    Keen.publish_batch(:wordpress_posts_views => posts_stats.slice(0, max_length))
    Keen.publish(:wordpress_views, { :handle => 'emccode', :views => data_all[:views] })

  end # if

end # SCHEDULER
