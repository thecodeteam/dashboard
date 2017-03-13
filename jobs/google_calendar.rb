require 'icalendar'

ical_url = 'https://calendar.google.com/calendar/ical/52rlkjj3h1lsfqmi5hr0475ceg%40group.calendar.google.com/private-a59d0bc7442a6bf35df6d8ea8a13ad03/basic.ics'
#ical_url = 'https://www.google.com/calendar/ical/52rlkjj3h1lsfqmi5hr0475ceg%40group.calendar.google.com/public/basic.ics'
uri = URI ical_url

SCHEDULER.every '1m', :first_in => 4 do |job|
#  result = Net::HTTP.get uri
  parsed_url = URI.parse(ical_url)
  puts parsed_url
  http = Net::HTTP.new(parsed_url.host, parsed_url.port)
  http.use_ssl = (parsed_url.scheme == "https")
  req = Net::HTTP::Get.new(parsed_url.request_uri)
  result = http.request(req).body
  calendars = Icalendar.parse(result)
  calendar = calendars.first

  events = calendar.events.map do |event|
    {
      start: event.dtstart,
      end: event.dtend,
      summary: event.summary
    }
  end.select { |event| event[:start] > DateTime.now }

  events = events.sort { |a, b| a[:start] <=> b[:start] }

  events = events[0..5]

  send_event('google_calendar', { events: events })
end
