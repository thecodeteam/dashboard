require 'dotenv'
Dotenv.load

require 'dashing'

configure do
  set :auth_token, ENV['DASHING_AUTH_TOKEN'] || SecureRandom.uuid
  set :default_dashboard, 'stats'
  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end
  get '/widgets/:id.json' do
  content_type :json
    response['Access-Control-Allow-Origin'] = '*'
    if data = settings.history[params[:id]]
      data.split[1]
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
