class Colossus
  module Engine
    # Threadsage with ThreadSafe
    class MemoryThreadSafe
      include Observable

      attr_reader :client_sessions, :ttl

      # @param [Integer/Float] ttl TTL in seconds
      def initialize(ttl)
        @client_sessions = ThreadSafe::Cache.new do |hash, key|
          hash[key] = Colossus::Engine::MemoryThreadSafe::ClientSessionStore.new(ttl)
        end
        @ttl             = ttl
      end

      def user_changed(user_id, status)
        changed
        notify_observers(user_id, status)
      end

      def set(user_id, client_id, given_status)
        if given_status == DISCONNECTED
          client_sessions[user_id].delete(client_id)
        else
          client_sessions[user_id][client_id] = given_status
        end

        if client_sessions[user_id].sessions.empty? ||
            client_sessions[user_id].status_changed?
          status = client_sessions[user_id].status
          delete(user_id) if status == DISCONNECTED
          user_changed(user_id, status)
          return true
        end

        false
      end

      def get(user_id)
        if client_sessions.key?(user_id)
          { user_id => client_sessions[user_id].status }
        else
          { user_id => DISCONNECTED }
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
        client_sessions.delete(user_id)
      end

      def reset!
        client_sessions.clear
      end

      def new_periodic_ttl
        secs_ttl = Colossus.config.seconds_before_ttl_check
        @periodic_ttl = EM::Synchrony.add_periodic_timer(secs_ttl, &method(:gc_ttl))
      end

      def gc_ttl
        delete_expired_users
        client_sessions.each_pair do |user_id, session_store|
          session_store.delete_expired_sessions
        end
      end

      def delete_expired_users
        user_ids_to_delete = []
        client_sessions.each_pair do |user_id, session_store|
          user_ids_to_delete << user_id if (session_store.last_seen + ttl) < Time.now
        end

        user_ids_to_delete.each { |user_id| client_sessions.delete(user_id) }
      end
    end
  end
end
