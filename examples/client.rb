require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, :development)

class ClientExtension
  attr_reader :token

  def initialize(token)
    @token = token
  end

  def outgoing(message, callback)
     message['ext'] ||= {}
     message['ext']['writer_token'] = 'WRITER_TOKEN'

    callback.call(message)
  end
end

FayeExtension = ClientExtension.new('')

def publish(client, user_id, count)
  publication = client.publish("/users/#{user_id}", JSON.dump(data: count))
  publication.errback do |error|
    puts 'There was a problem: ' + error.message
    EM.stop
  end

  publication.callback do
    publish(client, user_id, count+1)
    EM.stop if count == 100
  end
end

def ask_presence(client)
  publication = client.publish("/presences", {})
  publication.errback do |error|
    puts 'There was a problem: ' + error.message
    EM.stop
  end

  publication.callback do |message|
    EM.stop
  end
end

EM.synchrony {
    client = Faye::Client.new('http://localhost:9292/colossus')
    client.add_extension(FayeExtension)
    publish(client, user_id = '*', count = 0)
}
