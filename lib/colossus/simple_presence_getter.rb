class Colossus
  class SimplePresenceGetter
    attr_reader :colossus

    def initialize(colossus)
      @colossus = colossus
    end

    def get_presences(writer_token, optional_user_ids = nil)
      raise 'Invalid token' unless valid?(writer_token)
      user_ids = Array(optional_user_ids) if optional_user_ids
      if user_ids && user_ids.is_a?(Array)
        Hash[user_ids.zip(colossus.get_multi(user_ids))]
      elsif user_ids == nil
        colossus.get_all
      else
        raise 'Invalid user_ids data'
      end
    end

    def valid?(writer_token)
      colossus.verifier.verify_writer_token(writer_token)
    end
  end
end
