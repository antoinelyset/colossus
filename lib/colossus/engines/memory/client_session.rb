class Colossus
  module Engine
    class Memory
      # Represent the status and the information of a given user.
      class ClientSession
        attr_reader :status, :last_seen

        def initialize
          @status = DISCONNECTED
          @last_seen = Time.now
        end

        def status=(given_status)
          @last_seen = Time.now
          @status    = given_status
        end
      end
    end
  end
end
