class Colossus
  module Engine
    class Memory
      # Represents all the different sessions of a user. It can find
      #  the global status of the user given all the different status.
      class ClientSessionStore
        attr_reader :sessions, :last_status

        def initialize
          @sessions = Hash.new do |hash, key|
            hash[key] = Colossus::Engine::Memory::ClientSession.new
          end
          @last_status = 'disconnected'
        end

        def status
          sessions.values.reduce('disconnected') do |memo, session|
            case session.status
            when 'active'
              session.status
            when 'away'
              memo == 'active' ? memo : session.status
            else
              memo
            end
          end
        end

        def last_seen
          sessions.values.reduce(Time.new(0)) do |memo, session|
            session.last_seen > memo ? session.last_seen : memo
          end
        end

        def status_changed?
          last_status != status
        end

        def [](session_id)
          sessions[session_id]
        end

        def []=(session_id, session_status)
          @last_status = status
          sessions[session_id].status = session_status
        end

        def delete(session_id)
          sessions.delete(session_id)
        end
      end
    end
  end
end
