# usage: curl -s http://api.stackoverflow.com/1.1/tags | gunzip | ruby add_ltsv_log_stackoverflow.rb
# note: works even with ruby 1.8.x
require 'SimpleJson_jp.rb' # downloaded from http://ruby-webapi.googlecode.com/svn/trunk/misc/SimpleJson/SimpleJson_jp.rb

src = ARGF.read
parser = JsonParser.new
json = parser.parse(src)

print Time.now.strftime("date:%Y-%m-%d\t")
json['tags'].each do |item|
  print item['name'] + ":" + item['count'].to_s + "\t"
end
print "\n"