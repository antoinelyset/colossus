require 'faye'
require 'json'
require 'openssl'
require 'faraday'
require 'faraday_middleware'
require 'observer'
require 'em-synchrony'
require 'securerandom'

require 'colossus/configuration'
require 'colossus/verifier'
require 'colossus/http_writer_client'
require 'colossus/simple_writer_server'

require 'colossus/engines/memory/memory'
require 'colossus/engines/memory/client_session'
require 'colossus/engines/memory/client_session_store'

require 'colossus/faye/extension'

# Top Level Class.
# The public API of the Gem.
class Colossus
  include Observable

  attr_reader :engine, :verifier

  # Initialize Colossus
  #
  # @param ttl [Integer] the seconds before a user without emitting heartbeat
  #   is considered disconnected
  #
  # @param engine [Engine] the engine which implements the needed methods
  #   to work with Colossus
  #
  # @return [Colossus]
  def initialize(ttl          = Colossus.config.ttl,
                 engine       = Colossus.config.engine,
                 secret       = Colossus.config.secret_key,
                 writer_token = Colossus.config.writer_token)
    @engine = engine.new(ttl.to_i)
    @engine.add_observer(self)
    @verifier = Colossus::Verifier.new(secret, writer_token)
  end

  # Set the status of a user on a specificed client. A client could be
  # a Websocket session (if the user has 2 tabs opened) or anything else.
  #
  # @param user_id [#to_s] The unique identifier of a user
  # @param client_id [#to_s] The unique identifier of a client
  # @param status [#to_s] The status of a the user, it can be active,
  #   away or disconnected.
  #
  # @return [Boolean] Return true if the status has changed if not false.
  def set(user_id, client_id, status)
    engine.set(user_id.to_s, client_id.to_s, status.to_s)
  end

  # Get the status of a specified user, it analyzes the status
  #   of all the sessions.
  #   It returns :
  #
  #   - active if one or more clients are active.
  #   - away if one or more clients are away.
  #   - disconnected.
  #
  # @param user_id [#to_s] The unique identifier of a user
  #
  # @return Hash{String => String} User_id key, status value
  def get(user_id)
    engine.get(user_id.to_s)
  end

  # @param user_ids [Array<#to_s>] An array of user ids
  # (see #get)
  def get_multi(*user_ids)
    engine.get_multi(*user_ids.map(&:to_s))
  end

  # (see #get)
  def get_all
    engine.get_all
  end

  # Reset all the data (useful for specs)
  def reset!
    engine.reset!
  end

  # Generate a token for the given user_id
  def generate_user_token(user_id)
    verifier.generate_user_token(user_id)
  end

  # Method used when the engine notify a change
  #
  # @!visibility private
  def update(user_id, status)
    changed
    notify_observers(user_id, status)
  end
end
