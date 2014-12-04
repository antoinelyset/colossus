class Colossus
  class SimpleWriterServer
    attr_reader :faye_extension, :faye_client, :faye_client_extension

    def initialize(faye_extension)
      @faye_extension        = faye_extension
      @faye_client           = faye_extension.faye.get_client
      @faye_client_extension = FayeClientExtension.new
      @faye_client.add_extension(faye_client_extension)
    end

    def presence(writer_token, optional_user_ids = nil)
      raise 'Invalid token' unless valid?(writer_token)
      faye_client_extension.writer_token = writer_token

      case optional_user_ids
      when Array
        colossus.get_multi(*optional_user_ids)
      when String
        colossus.get(optional_user_ids)
      when NilClass
        colossus.get_all
      else
        raise 'Invalid user_ids data'
      end
    end

    def push(writer_token, user_ids, message)
      raise 'Invalid token' unless valid?(writer_token)
      faye_client_extension.writer_token = writer_token

      case user_ids
      when Array
        user_ids.each do |user_id|
          faye_client.publish("/users/#{user_id}", message)
        end
      when String
        faye_client.publish("/users/#{user_ids}", message)
      else
        raise 'Invalid user_ids data'
      end
    end

    def valid?(writer_token)
      colossus.verifier.verify_writer_token(writer_token)
    end

    def colossus
      faye_extension.colossus
    end

    class FayeClientExtension
      attr_accessor :writer_token

      def initialize(writer_token = nil)
        @writer_token = writer_token
      end

      def incoming(message, callback)
        callback.call(message)
      end

      def outgoing(message, callback)
        message['ext'] ||= {}
        message['ext']['writer_token'] = writer_token
        puts message

        callback.call(message)
      end
    end
  end
end
