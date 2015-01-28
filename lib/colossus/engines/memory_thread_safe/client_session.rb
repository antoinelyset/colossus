class Colossus
  module Engine
    class MemoryThreadSafe
      # Represent the status and the information of a given user.
      class ClientSession
        attr_reader :status, :last_seen

        def initialize
          @data             = ThreadSafe::Cache.new
          @data[:status]    = DISCONNECTED
          @data[:last_seen] = Time.now
        end

        def status
          @data[:status]
        end

        def status=(given_status)
          @data[:last_seen] = Time.now
          @data[:status]    = given_status
        end

        def last_seen
          @data[:last_seen]
        end
      end
    end
  end
end

