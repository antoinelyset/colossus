class Colossus
  class WriterClient
    attr_reader :url, :writer_token, :time_out

    def initialize(url,
                   writer_token = Colossus.config.writer_token,
                   time_out = 2)
      @url          = url
      @writer_token = writer_token
      @time_out     = time_out
    end

    def get_presences(optional_user_ids = nil)
      user_ids = Array(optional_user_ids) if optional_user_ids
      unique_token = generate_unique_token
      EM.synchrony do
        EM::Synchrony.add_timer(time_out) { raise 'Presence request timed out' }
        EM::Synchrony.sync(faye_client.subscribe("/presences/response/#{unique_token}") { |message| return message['statuses'] })
        EM::Synchrony.sync(faye_client.publish("/presences/request/#{unique_token}", user_ids))
      end
    end

    def get_presences_by_http(optional_user_ids = nil)
      user_ids = Array(optional_user_ids) if optional_user_ids
      # Custom Content-Type to indicate to the server
      # this is a simple http request
      conn = Faraday.new(url, headers: {'Content-Type' => 'application/vnd.http.json'}) do |conf|
        conf.adapter  Faraday.default_adapter
        conf.response :raise_error
      end

      body = conn.post do |req|
        req.body = JSON.dump({ user_ids: user_ids, writer_token: writer_token})
      end.body

      response = JSON.parse(body)
      response['statuses']
    end

    def push_message(user_ids, message)
      user_ids = Array(user_ids)
      EM.synchrony do
        EM::Synchrony.add_timer(time_out) { raise 'Push message timed out' }
        user_ids.each do |user_id|
          EM::Synchrony.sync(faye_client.publish("/users/#{user_id}", message))
        end
        EM.stop
      end
    end

    private

    def faye_client
      faye_client = ::Faye::Client.new(url)
      faye_client.add_extension(FayeExtension.new(writer_token))
      faye_client
    end

    def generate_unique_token
      SecureRandom.hex(8)
    end

    class FayeExtension
      attr_reader :token

      def initialize(token)
        @token = token
      end

      def incoming(message, callback)
        callback.call(message)
      end

      def outgoing(message, callback)
        message['ext'] ||= {}
        message['ext']['writer_token'] = token

        callback.call(message)
      end
    end
  end
end
