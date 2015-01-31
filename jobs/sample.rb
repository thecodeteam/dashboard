current_valuation = 0
current_karma = 0
current_email = 0


SCHEDULER.every '2s' do
  last_valuation = current_valuation
  last_karma     = current_karma
  #last_email     = current_email
  current_valuation = rand(100)
  current_karma     = rand(200000)
  #current_email     = last_email+rand(10)

  send_event('valuation', { current: current_valuation, last: last_valuation })
  send_event('karma', { current: current_karma, last: last_karma })
  #send_event('email_subscribers', { current: current_email, last: last_email })
  send_event('synergy',   { value: rand(100) })
end
