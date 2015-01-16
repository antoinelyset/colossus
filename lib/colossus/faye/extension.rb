class Colossus
  module Faye
    # Faye extension implementing all the presence, authorization,
    # authentification and push logic.
    class Extension
      attr_reader :faye, :colossus

      VALID_STATUSES = %w(disconnected away active).freeze

      def initialize(faye, colossus = Colossus.new)
        @faye     = faye
        @colossus = colossus
        faye.add_extension(self)
      end

      def incoming(message, callback)
        if !acceptable?(message)
          handle_invalid_token(message)
          message.delete('data')
          message.delete('ext')
        elsif message['ext']['user_token']
          handle_user_action(message)
          message.delete('data')
          message.delete('ext')
        elsif message['ext']['writer_token']
          message.delete('ext')
        end

        callback.call(message)
      end

      def acceptable?(message)
        message['ext'] &&
          (message['ext']['user_token'] || message['ext']['writer_token'])
      end

      def handle_user_action(message)
        if message['channel'] == '/meta/subscribe'
          handle_subscribe(message)
        elsif message['channel'].start_with?('/meta/')
          message
        elsif message['channel'].start_with?('/users/')
          handle_set_status(message)
        else
          message['error'] = 'Unknown Action'
        end

        message
      end

      def handle_invalid_token(message)
        message['error'] = 'Invalid Token'
        message
      end

      def handle_subscribe(message)
        token   = message['ext']['user_token']
        user_id = message['subscription'].partition('/users/').last

        if invalid_user_channel?(user_id)
          message['error'] = 'The only accepted channel_name is users/:user_id'
          return message
        end

        unless colossus.verifier.verify_token(token, user_id)
          message['error'] = 'Invalid Token'
        end

        message
      end

      def handle_set_status(message)
        token   = message['ext']['user_token']
        user_id = message['channel'].partition('/users/').last
        status  = message['data'] && message['data']['status']

        if invalid_user_channel?(user_id)
          message['error'] = 'The only accepted channel_name is users/:user_id'
          return message
        end

        unless status && VALID_STATUSES.include?(status)
          message['error'] = 'Invalid Status'
          return message
        end

        unless colossus.verifier.verify_token(token, user_id)
          message['error'] = 'Invalid Token'
          return message
        end

        colossus.set(user_id, message['clientId'], status)

        message
      end

      def invalid_user_channel?(user_id)
        user_id.empty? || user_id.include?('*') || user_id.include?('/')
      end
    end
  end
end
