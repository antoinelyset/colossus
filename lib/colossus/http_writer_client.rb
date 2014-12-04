class Colossus
  class HTTPWriterClient
    attr_reader :url, :writer_token, :time_out

    def initialize(url,
                   writer_token = Colossus.config.writer_token,
                   time_out     = 2)
      @url          = url
      @writer_token = writer_token
      @time_out     = time_out
    end

    def presence(optional_user_ids = nil)
      user_ids = Array(optional_user_ids) if optional_user_ids
      connection.post('/presence_request') do |req|
        req.body = { user_ids: user_ids, writer_token: writer_token }
      end.body
    end

    def push(user_ids, message)
      user_ids = Array(user_ids)
      connection.post('/message') do |req|
        req.body = { user_ids: user_ids, message: message, writer_token: writer_token}
      end.body
    end

    private

    def connection
      Faraday.new(url, connection_options) do |conf|
        conf.request  :json
        conf.response :json
        conf.response :raise_error
        conf.adapter  Faraday.default_adapter
      end
    end

    def connection_options
      {request: {timeout: 2, open_timeout: 2}}
    end

    def base_url
      @base_url ||= URI.parse(url).tap{ |u| u.path=('/') }
    end
  end
end
