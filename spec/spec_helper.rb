require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, :test)
require_relative './support/goliath.rb'

Colossus.configure do |conf|
  conf.verifier_secret = 'please'
end

class SpecObserver
  attr_reader :spec
  def initialize(&spec)
    @spec = spec
  end
  def update(given_user_id, given_status)
    spec.call(given_user_id, given_status)
  end
end

class ClientExtension
  attr_reader :token
  def initialize(token)
    @token = token
  end
  def outgoing(message, callback)
    message['ext'] ||= {}
    message['ext']['user_push_token'] = token

    callback.call(message)
  end
end

Faye::WebSocket.load_adapter('goliath')
ColossusFayeExtension = Colossus::Faye::Extension.new
App = Faye::RackAdapter.new(extensions: [ColossusFayeExtension],
                            mount:      '/colossus',
                            timeout:    25)

class FayeExtensionTTLPlugin
  def initialize(address, port, config, status, logger); end

  def run
    ColossusFayeExtension.colossus.engine.new_periodic_ttl
  end
end

class GoliathServer < Goliath::API
  plugin FayeExtensionTTLPlugin

  def response(env)
    App.call(env)
  end
end
