class Colossus
  module Engine
    # The Redis Engine is a distributed engine.
    # Colossus server is now stateless.
    class Redis
      include Observable

      def initialize(ttl)
      end
    end
  end
end
