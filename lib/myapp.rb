require 'sinatra/base'
require 'sinatra/partial'
require 'base64'
require 'rubygems'
require 'json'
require 'byebug'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'net/https'
require 'uri'
require 'data_mapper'

env = ENV["RACK_ENV"] || "development"

DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://localhost/mbk_#{env}")
 
require './lib/user'
require './lib/transaction'

DataMapper.finalize
DataMapper.auto_upgrade!

class MBK < Sinatra::Base

set :views, File.join(File.dirname(__FILE__), '..', 'views')
set :public_folder, File.join(File.dirname(__FILE__), '..', 'public')
set :partial_template_engine, :erb

use Rack::Session::Cookie, :expire_after => 86400 # 1 day

APPLICATION_NAME = 'Monea BK'
PLUS_LOGIN_SCOPE = 'https://www.googleapis.com/auth/plus.login https://www.googleapis.com/auth/drive'

# Build the global client
$credentials = Google::APIClient::ClientSecrets.load
$authorization = Signet::OAuth2::Client.new(
    :authorization_uri => $credentials.authorization_uri,
    :token_credential_uri => $credentials.token_credential_uri,
    :client_id => $credentials.client_id,
    :client_secret => $credentials.client_secret,
    :redirect_uri => $credentials.redirect_uris.first,
    :scope => PLUS_LOGIN_SCOPE)
$client = Google::APIClient.new(application_name: APPLICATION_NAME)

get '/' do

  if !session[:token]
   
     if !session[:state]
      state = (0...13).map{('a'..'z').to_a[rand(26)]}.join
      session[:state] = state
      @state = session[:state]
      erb :homepage
     else
      @state = session[:state]
      erb :homepage
     end

   else
    erb :homepage2
  end

end

get '/test' do
  @transactions = User.get(session[:mbk_id]).transactions
  erb :test
end

# Connect the user with Google+ and store the credentials.
post '/connect' do

  if !session[:token]

    if session[:state] == params[:state]
      $authorization.code = request.body.read
      $authorization.fetch_access_token!
      $client.authorization = $authorization

      id_token = $client.authorization.id_token
      encoded_json_body = id_token.split('.')[1]
      
      encoded_json_body += (['='] * (encoded_json_body.length % 4)).join('')
      json_body = Base64.decode64(encoded_json_body)
      body = JSON.parse(json_body)

      gplus_id = body['sub']  
      monea_user = User.first_or_create(uid: gplus_id)
      mbk_id = monea_user.id

      # Serialize and store the token in the user's session.
      token_pair = TokenPair.new
      token_pair.update_token!($client.authorization)
      session[:token] = token_pair
      session[:mbk_id] = mbk_id
      session[:gplus_id] = gplus_id
    else
      halt 401, 'The client state does not match the server state.'
    end
    status 200
  else
    content_type :json
    'Current user is already connected.'.to_json
  end
end

# An Example API call, list the people the user shared with this app.
get '/people' do
  # Check for stored credentials in the current user's session.
  if !session[:token]
    halt 401, 'User not connected.'
  end
  # Authorize the client and construct a Google+ service.
  $client.authorization.update_token!(session[:token].to_hash)
  plus = $client.discovered_api('plus', 'v1')

  # Get the list of people as JSON and return it.
  response = $client.execute!(plus.people.list,
      :collection => 'visible',
      :userId => 'me').body
  content_type :json
  response
end

get '/sign_out' do
    session.delete(:token)
    redirect to('/')
end

# Disconnect the user by revoking the stored token and removing session objects.
post '/disconnect' do
  halt 401, 'No stored credentials' unless session[:token]

  # Use either the refresh or access token to revoke if present.
  token = session[:token].to_hash[:refresh_token]
  token = session[:token].to_hash[:access_token] unless token
  # You could reset the state at this point, but as-is it will still stay unique
  # to this user and we're avoiding resetting the client state.
  # session.delete(:state)
  session.delete(:token)

  # Send the revocation request and return the result.
  revokePath = 'https://accounts.google.com/o/oauth2/revoke?token=' + token
  uri = URI.parse(revokePath)
  request = Net::HTTP.new(uri.host, uri.port)
  request.use_ssl = true
  status request.get(uri.request_uri).code
end

# Serializes and deserializes the token.
class TokenPair

  @refresh_token
  @access_token
  @expires_in
  @issued_at

  def update_token!(object)
    @refresh_token = object.refresh_token
    @access_token = object.access_token
    @expires_in = object.expires_in
    @issued_at = object.issued_at
  end

  def to_hash
    return {
      :refresh_token => @refresh_token,
      :access_token => @access_token,
      :expires_in => @expires_in,
      :issued_at => Time.at(@issued_at)}
  end
end

# def current_user    
#     @current_user ||= User.get(session[:user_id]) if session[:user_id]
# end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
