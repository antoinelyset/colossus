class Colossus
  class SimpleWriterServer
    attr_reader :faye_extension

    def initialize(faye_extension)
      @faye_extension = faye_extension
    end

    def presence(writer_token, optional_user_ids = nil)
      raise 'Invalid token' unless valid?(writer_token)

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

    def faye_client
      faye_extension.faye.get_client
    end

    def colossus
      faye_extension.colossus
    end
  end
end
