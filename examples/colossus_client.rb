require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, :development)
Goliath.run_app_on_exit = false

SECRET_KEY = 'SECRET_KEY'
SHA1       = OpenSSL::Digest.new('sha1')
STATUSES = %w{ away active disconnected }

class ColossusRubyClient
  attr_reader :user_id, :user_token, :faye_client, :periodic_heartbeat

  def initialize(user_id = SecureRandom.uuid)
    @user_id     = user_id
    @user_token  = OpenSSL::HMAC.hexdigest(SHA1, SECRET_KEY, user_id)
    @faye_client = Faye::Client.new('http://localhost:4242/colossus')
    faye_client.add_extension(ClientExtension.new(user_token))
    @periodic_heartbeat = EM::Synchrony.add_periodic_timer(2, &method(:heartbeat))
    heartbeat
  end

  def heartbeat
    faye_client.publish("/users/#{user_id}", {status: STATUSES.sample})
  end
end

class ClientExtension
  attr_reader :token

  def initialize(token)
    @token = token
  end

  def outgoing(message, callback)
     message['ext'] ||= {}
     message['ext']['user_token'] = token

    callback.call(message)
  end
end

EM.synchrony do
  200.times do
    ColossusRubyClient.new
  end
end
