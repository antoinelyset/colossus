class Colossus
  module Engine
    # The Memory Engine is a non-distributed engine.
    # Based on EventMachine in order to provide the ttl to
    # disconnect clients.
    class Memory
      include Observable

      attr_reader :client_sessions, :ttl, :mutex

      # @param [Integer/Float] ttl TTL in seconds
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
          if given_status == 'disconnected'
            client_sessions[user_id].delete(client_id)
          else
            client_sessions[user_id][client_id] = given_status
          end
        end

        if client_sessions[user_id].sessions.empty? ||
            client_sessions[user_id].status_changed?
          status = client_sessions[user_id].status
          delete(user_id) if status == 'disconnected'
          user_changed(user_id, status)
          return true
        end

        false
      end

      def get(user_id)
        if client_sessions.has_key?(user_id)
          { user_id => client_sessions[user_id].status }
        else
          { user_id => 'disconnected' }
        end
      end

      def get_multi(*user_ids)
        user_ids.inject({}) { |memo, user_id| memo.merge!(get(user_id)) }
      end

      def get_all
        statuses = {}
        client_sessions.each_pair do |user_id, session_store|
          statuses[user_id] = session_store.status
        end
        statuses
      end

      def delete(user_id)
        mutex.synchronize do
          client_sessions.delete(user_id)
        end
      end

      def reset!
        mutex.synchronize do
          @client_sessions = Hash.new do |hash, key|
            hash[key] = Colossus::Engine::Memory::ClientSessionStore.new
          end
        end
      end

      def new_periodic_ttl
        secs_ttl = Colossus.config.seconds_before_ttl_check
        @periodic_ttl = EM::Synchrony.add_periodic_timer(secs_ttl, &method(:gc_ttl))
      end

      def gc_ttl
        user_ids_to_delete = []

        client_sessions.each_pair do |user_id, session_store|
          sessions_dupped = session_store.sessions.dup

          session_store.sessions.each_pair do |session_id, session|
            if (session.last_seen + ttl) < Time.now
              sessions_dupped.delete(session_id)
            end
          end

          mutex.synchronize { session_store.sessions = sessions_dupped }

          if (session_store.last_seen + ttl) < Time.now
            user_ids_to_delete << user_id
          end
        end

        delete_expired_users(user_ids_to_delete)
      end

      def delete_expired_users(user_ids)
        user_ids.each do |user_id|
          delete(user_id)
          user_changed(user_id, 'disconnected')
        end
      end
    end
  end
end
