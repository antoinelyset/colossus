require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, :development)
Goliath.run_app_on_exit = false

client = Colossus::WriterClient.new('http://localhost:9292/colossus', 'WRITER_TOKEN')
statuses = client.get_presences
client.push_message(statuses.keys, 'HELLO SERVER FROM SIDE CLIENT')
