class Colossus
  module Faye
    # Faye extension implementing all the presence, authorization,
    # authentification and push logic.
    class Extension
      attr_reader :colossus, :faye, :faye_client

      VALID_STATUSES = %w(disconnected away active).freeze

      def initialize(faye, colossus = Colossus.new)
        @colossus = colossus
        @faye     = faye
        faye.add_extension(self)
        @faye_client = faye.get_client
        colossus_faye_extension = Colossus::WriterClient::FayeExtension.
          new(colossus.verifier.writer_token)
        faye_client.add_extension(colossus_faye_extension)
      end

      def incoming(message, _request, callback)
        if !acceptable?(message)
          handle_invalid_token(message)
          message.delete('data')
          message.delete('ext')
        elsif message['ext']['user_token']
          handle_user_action(message)
          message.delete('data')
          message.delete('ext')
        elsif message['ext']['writer_token']
          handle_server_action(message)
          message.delete('ext')
        end

        callback.call(message)
      end

      def acceptable?(message)
        message['ext'] &&
          (message['ext']['user_token'] ||
           message['ext']['writer_token'])
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

      def handle_server_action(message)
        token = message['ext'] && message['ext']['writer_token']

        unless token && colossus.verifier.verify_writer_token(token)
          message['error'] = 'Invalid Token'
          message.delete('data')
          return message
        end

        if message['channel'].start_with?('/meta/')
          message.delete('data')
          message
        elsif message['channel'].start_with?('/presences/request/')
          handle_presence_request(message)
        elsif message['channel'].start_with?('/presences/response/')
          handle_presence_response(message)
        elsif message['channel'].start_with?('/users/')
          handle_publish(message)
        else
          message['error'] = 'Unknown Action'
          message.delete('data')
        end

        message
      end

      def handle_presence_request(message)
        user_ids    = message['data'] && message['data']['user_ids']
        presence_id = message['channel'].partition('/presences/request/').last

        if user_ids && user_ids.is_a?(Array)
          statuses = colossus.get_multi(user_ids)
          message['data'].delete('user_ids')
          faye_client.publish("/presences/response/#{presence_id}", { 'statuses' => Hash[user_ids.zip(statuses)] })
          message
        elsif user_ids == nil
          statuses = colossus.get_all
          faye_client.publish("/presences/response/#{presence_id}", { 'statuses' => statuses })
          message
        else
          message.delete('data')
          message['error'] = 'Invalid user_ids data'
          message
        end
      end

      def handle_presence_response(message)
        message
      end

      def handle_publish(message)
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
