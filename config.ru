require 'dotenv'
Dotenv.load

require 'dashing'

configure do
  set :auth_token, 'Horrible_AUTH_t0ken_S3crets_HER3'

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
