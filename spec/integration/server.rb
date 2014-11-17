Faye::WebSocket.load_adapter('goliath')
ColossusFayeExtension = Colossus::Faye::Extension.new
App                   = Faye::RackAdapter.new(extensions: [ColossusFayeExtension],
                                              mount:      '/colossus',
                                              timeout:    25)

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

  def response(env)
    App.call(env)
  end
end
