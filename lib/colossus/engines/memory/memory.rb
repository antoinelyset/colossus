class Colossus
  module Engine
    # The Memory Engine is a non-distributed engine.
    # Based on EventMachine in order to provide the ttl to
    # disconnect clients.
    class Memory
      include Observable

      attr_reader :client_sessions, :ttl, :mutex

      def initialize(ttl)
        @client_sessions = Hash.new do |hash, key|
          hash[key] = Colossus::Engine::Memory::ClientSessionStore.new
        end
        @ttl       = ttl
        @mutex     = Mutex.new
      end

      def user_changed(user_id, status)
        changed
        notify_observers(user_id, status)
      end

      def set(user_id, client_id, given_status)
        mutex.synchronize do
          client_sessions[user_id][client_id] = given_status
        end

        if client_sessions[user_id].status_changed?
          given_status = client_sessions[user_id].status
          delete(user_id) if given_status == 'disconnected'
          user_changed(user_id, given_status)
          return true
        end
        false
      end

      def get(user_id)
        client_sessions[user_id]
      end

      def get_multi(*user_ids)
        user_ids.map { |user_id| get(user_id) }
      end

      def delete(user_id)
        mutex.synchronize do
          client_sessions.delete(user_id)
        end
      end

      def new_periodic_ttl
        secs_ttl = Colossus.config.seconds_before_ttl_check
        @periodic_ttl = EventMachine::PeriodicTimer.new(secs_ttl) do
          client_sessions.each_pair do |user_id, sessions|
            if (sessions.last_seen + ttl) < Time.now
              delete(user_id)
              user_changed(user_id, 'disconnected')
            end
          end
        end
      end
    end
  end
end
