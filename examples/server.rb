require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, :development)

RackFile = Rack::File.new('public')
RubyTemplate = Erubis::EscapedEruby.new(File.read(File.expand_path(File.join(File.dirname(__FILE__), './public/index.html.erb'))))

Colossus.configure do |conf|
  conf.writer_token = 'WRITER_TOKEN'
  conf.secret_key   = 'SECRET_KEY'
end

Faye::WebSocket.load_adapter('goliath')
App = Faye::RackAdapter.new(mount: '/colossus', timeout: 25)
ColossusFayeExtension = Colossus::Faye::Extension.new(App)

class UserChangedStatusObserver
  def update(user_id, status)
    puts "User #{user_id}, changed to #{status}"
  end
end

ColossusFayeExtension.colossus.add_observer(UserChangedStatusObserver.new)

class FayeExtensionTTLPlugin
  def initialize(address, port, config, status, logger); end

  def run
    ColossusFayeExtension.colossus.engine.new_periodic_ttl
  end
end

class GoliathServer < Goliath::API
  plugin FayeExtensionTTLPlugin

  def context
    user_id = Random.rand(1000).to_s
    user_token = ColossusFayeExtension.colossus.generate_user_token(user_id)
    { user_token: user_token, user_id: user_id }
  end

  def response(env)
    if env['PATH_INFO'] == "/colossus"
      App.call(env)
    elsif env['PATH_INFO'] == '/'
      [200, {}, RubyTemplate.evaluate(context)]
    else
      RackFile.call(env)
    end
  end
end
